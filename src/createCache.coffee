{contains, dissoc, equals, has, isEmpty, isNil, keys, match, merge, mergeDeepLeft, omit, props, type} = R = require 'ramda' #auto_require: ramda
{change, func, fmapO, customError} = RE = require 'ramda-extras' #auto_require: ramda-extras
[] = [] #auto_sugar
qq = (f) -> console.log match(/return (.*);/, f.toString())[1], f()
qqq = (f) -> console.log match(/return (.*);/, f.toString())[1], JSON.stringify(f(), null, 2)
_ = (...xs) -> xs

debounce = require 'lodash.debounce'
popsiql = require 'popsiql'

# Responsible for:
# - storing normalized data in memory
# - keeping track of statuses for normalized data and queries
#
# Responsible via dependencies for:
#
# NOT responsible for:
# - normalizing
# - executing queries or denormalizing


module.exports = func
	model: Object # popsiql model
	initialState: Object # initial state of cache i.e. normalized data
	debounceTime〳: Number # ms to "buffer" up changes before publishing
	maxWait〳: Number # ms to maximum keep "buffering" before forcing a flush
	successStay〳: Number # ms to keep object in success state
	remoteRead: (remoteQuery) -> # run remoteQuery at server & return Promise with normalized result
	remoteWrite: (delta) -> # run delta at server & return Promise with new id-mappings (if any)
	commitHook〳: (status, msg) -> # commitHook that gets called with commit status changes
	debug〳: Boolean # flag to get debug messages in console
	report: () -> # report callback for logging 
,	
(config) ->
	return new Cache config


customError = (name) ->
	class CustomError extends Error
		constructor: (msg) ->
			super msg
			@name = name
			Error.captureStackTrace this, CustomError

CE = customError 'cacheError'



resultToId = (localResult) -> JSON.stringify localResult

class Cache
	constructor: (config) ->
		defaultConfig =
			debounceTime: 10
			maxWait: 250
			debug: false
			successStay: 1000
		@config = mergeDeepLeft config, defaultConfig

		@state = config.initialState || {}
		@memo = {}
		@subs = {}
		@editSubs = {}
		@totalChanges = {}
		@rollbackState = null
		@commitStatus = null # w, s, f
		@stateHook = null
		@remoteReads = {} # flags for what read-queries have already been executed
		@newId = -1 # negative ids for new objects
		@changeCount = 0

		@changes = {}
		@undos = []
		@commitMsg = null

		@_flush = debounce @__flush, @config.debounceTime,
			leading: false # don't publish directly, let changes "buffer up"
			trailing: true # then when they're all buffered, publish everything at once
			maxWait: @config.maxWait # if too many changes, don't let them buffer in all eternity
			# Want to be sure your changes has been committed? Just sleep maxWait ms.


	sub: (query, subType, cb, key, initialRes = null) ->
		if isNil query then throw new CE 'cannot sub to nil query'
		else if ! contains subType, ['local', 'full', 'edit'] then throw new CE "invalid subType #{subType}"
		else if isNil(key) || type(key) != 'String' then throw new CE 'key is missing or not a string'
		fatQuery = popsiql.query.expandQuery @config.model, query
		lastRes = if initialRes then resultToId initialRes else null
		sub = {query, subType, fatQuery, cb, key, lastRes}

		@subs[key] = sub

		if subType == 'edit' then @editSubs[key] = sub

		# local0 = performance.now()
		# @_runLocal(sub).then ([localRes, localResNorm]) ->
		# 	# console.log "CACHE #{popsiql.utils.queryToString(query).substr(0,80)} == #{performance.now() - local0} ms"
		# 	# console.log localRes
		# 	cb localRes # initial call
		# 	sub.lastRes = resultToId localRes

		if subType == 'full' && @_shouldRunRemote query
			@config.remoteRead(query).then (normRes) =>
				@_recordRemoteRead query
				@_change normRes

		return () =>
			delete @subs[key]
			if subType == 'edit' then delete @editSubs[key]

	queryLocal: (query, subType) ->
		memoKey = @_memoKey {query, subType}
		# Commenting out memo since we don't have a good way to invalidate it! Doesn't work then!
		# if @memo[memoKey] then return @memo[memoKey]

		fatQuery = popsiql.query.expandQuery @config.model, query
		[res, resNorm] = @_runLocal {fatQuery, query, subType}, true
		@memo[memoKey] = [res, resNorm]
		return [res, resNorm]

	update: (delta) ->
		# TODO

	edit: (delta) ->
		undo = {}
		statePlusChanges = change @changes, @state
		newStateNeverUsed = change.meta delta, statePlusChanges, undo, @changes
		@undos.push undo
		@stateHook? @state, @changes
		@_editFlush()

	undo: () ->
		@undos = []
		@changes = {}
		@stateHook? @state, @changes
		@_editFlush()

	reset: () ->
		@state = @config.initialState || {}
		@memo = {}
		@remoteReads = {}

		for key, sub of @subs
			{subType, query} = sub
			if subType == 'full' && @_shouldRunRemote query
				@config.remoteRead(query).then (normRes) =>
					@_recordRemoteRead query
					@_change normRes

		@_flush()

	commit: (msg, remoteCall = null) ->
		if @commitStatus == 'w' then return false
		_delta = @changes

		# _ can be used as client side meta data
		delta = {}
		for entity, entityDelta of _delta
			delta[entity] = {}
			for id, itemDelta of entityDelta
				delta[entity][id] = if itemDelta == undefined then undefined else omit ['_'], itemDelta

		@config.report {ts: performance.now(), name: 'commit', delta}
		@commitMsg = msg
		@rollbackState = @state
		@_setCommitStatus 'w'
		@_change delta
		@_changeObjectStatus 'w', delta
		try
			if remoteCall then serverDelta = await remoteCall()
			else serverDelta = await @config.remoteWrite delta

			# Allow for id changes from server for temp objects
			serverDelta2 = {}
			for entity, data of serverDelta
				serverDelta2[entity] = {}
				for id, props of data
					if id < 0 && has('id', props) && id != props.id
						existingData = @state[entity]?[id] || {}
						serverDelta2[entity][props.id] = merge existingData, props
						serverDelta2[entity][id] = undefined

						# update delta used for objectStatus
						delta[entity][props.id] = {dummy: 1}
						delete delta[entity][id]
					else
						serverDelta2[entity][id] = props

			@_change serverDelta2
			@_changeObjectStatus 's', delta
			@_changeObjectStatus undefined, delta, @config.successStay
			@_setCommitStatus 's'
			@changes = {}
			@stateHook? @state, @changes
			@undos = []
			return serverDelta2
		catch err
			console.error err
			@_setState @rollbackState
			@_changeObjectStatus 'f', delta
			@_changeObjectStatus undefined, delta, 3000
			@_setCommitStatus 'f'
			# todo: re-apply server pushed since commit
		finally
			@commitMsg = null

		# return true

	getNewId: -> return @newId--

	_shouldRunRemote: (query) -> ! @remoteReads[JSON.stringify query]
	_recordRemoteRead: (query) -> @remoteReads[JSON.stringify query] = true


	_change: (delta) ->
		undo = {}	
		newState = change.meta delta, @state, undo, @totalChanges
		@state = newState
		@stateHook? @state, @changes
		@_flush()
		@changeCount = @changeCount + 1

	_setState: (newState) ->
		@state = newState
		@stateHook? @state, @changes
		@_flush()

	_memoKey: ({query, subType}) ->
		return JSON.stringify(query) + if subType == 'edit' then 'edit' else ''

	_editFlush: ->
		for key, sub of @editSubs
			[res, resNorm] = @_runLocal sub, true
			@memo[@_memoKey(sub)] = [res, resNorm]
			resId = resultToId res
			if resId != sub.lastRes
				sub.cb res
				sub.lastRes = resId

	__flush: ->
		ts = performance.now()
		@config.report {ts, name: 'flush-start', totalChanges: @totalChanges, changeCount: @changeCount}
		@changeCount = 0
		affectedSubs = []
		for key, sub of @subs
			t0 = performance.now()
			[res, resNorm] = await @_runLocal sub
			@memo[@_memoKey(sub)] = [res, resNorm]
			resId = resultToId res
			if resId != sub.lastRes
				sub.cb res, t0
				sub.lastRes = resId
				affectedSubs.push sub.key

		@totalChanges = {}

		@config.report {ts: performance.now(), name: 'flush-end', affectedSubs,
		time: {tot: performance.now() - ts}}


	_changeObjectStatus: (status, delta, delay = 0) ->
		fn = =>
			statusDelta = toStatusDelta2 status, delta, @state
			if !isEmpty(statusDelta) then @_change statusDelta

		if delay then setTimeout fn, delay
		else fn()

	_setCommitStatus: (s) ->
		@commitStatus = s
		@config.commitHook? @commitStatus, @commitMsg

	_runLocal: ({fatQuery, query, subType}, sync = false) ->
		stateToUse = if subType != 'edit' then @state else change @changes, @state
		popsiqlRamda = popsiql.ramda @config.model, stateToUse
		ramdaRead = (fatQuery) =>
			popsiqlRamda.read fatQuery, (entity, id, o) =>
				if @state[entity]?[id]?._ then merge o, {_: @state[entity][id]._}
				else o
				
		if sync then return popsiql.query.runFatQuerySync @config.model, ramdaRead, fatQuery, query
		else return popsiql.query.runFatQuery @config.model, ramdaRead, fatQuery, query


extractStatusDelta = (delta) ->
	fmapO delta, (items, entity) ->
		fmapO items, (entityDelta, id) -> {}

toStatusDelta2 = (status, delta, currentState) ->
	statusDelta = {}
	for entity, items of delta
		for id, ___ of items
			if !currentState[entity][id] then continue # if object removed, 
			statusDelta[entity] ?= {}
			if status == undefined
				if equals currentState[entity][id].keys, ['_'] then statusDelta[entity][id] = undefined
				else statusDelta[entity][id] = {'_': undefined}
			else statusDelta[entity][id] = {_: status}
	return statusDelta


# {Person: {1: {name: 'Sara'}, 2: {...}}} -> {Person: {1: {_: 'w'}, 2: {_: 'w'}}
toStatusDelta = (status, delta) ->
	fmapO delta, (items, entity) ->
		fmapO items, (entityDelta, id) ->
			(currentData) ->
				if status == undefined
					if equals ['_'], keys currentData then undefined
					else dissoc '_', currentData
				else merge currentData, {_: status}




