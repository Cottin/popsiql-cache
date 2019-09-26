{dissoc, equals, isNil, keys, match, merge, mergeDeepLeft, without} = R = require 'ramda' #auto_require: ramda
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
	remoteRead: (remoteQuery) -> # run remoteQuery at server & return Promise with normalized result
	remoteWrite: (delta) -> # run delta at server & return Promise with new id-mappings (if any)
	debug〳: Boolean # flag to get debug messages in console
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
		@config = mergeDeepLeft config, defaultConfig

		@state = config.initialState || {}
		@memo = {}
		@subs = []
		@totalChanges = {}
		@rollbackState = null
		@commitStatus = null # w, s, f
		@commitHook = null
		@stateHook = null
		@remoteReads = {} # flags for what read-queries have already been executed

		@_flush = debounce @__flush, @config.debounceTime,
			leading: false # don't publish directly, let changes "buffer up"
			trailing: true # then when they're all buffered, publish everything at once
			maxWait: @config.maxWait # if too many changes, don't let them buffer in all eternity
			# Want to be sure your changes has been committed? Just sleep maxWait ms.

	sub: (query, localOnly, cb, initialRes = null) ->
		if isNil query then throw new CE 'cannot sub to nil query'
		fatQuery = popsiql.query.expandQuery @config.model, query
		lastRes = if initialRes then resultToId initialRes else null
		sub = {query, fatQuery, cb, lastRes}

		@subs.push sub

		# local0 = performance.now()
		# @_runLocal(sub).then ([localRes, localResNorm]) ->
		# 	# console.log "CACHE #{popsiql.utils.queryToString(query).substr(0,80)} == #{performance.now() - local0} ms"
		# 	# console.log localRes
		# 	cb localRes # initial call
		# 	sub.lastRes = resultToId localRes

		if !localOnly && @_shouldRunRemote query
			@config.remoteRead(query).then (normRes) =>
				@_recordRemoteRead query
				@_change normRes

		return () => @subs = without [sub], @subs

	queryLocal: (query) ->
		squery = JSON.stringify(query)
		if @memo[squery] then return @memo[squery]

		fatQuery = popsiql.query.expandQuery @config.model, query
		[res] = @_runLocal {fatQuery, query}, true
		@memo[squery] = res
		return res

	commit: (delta) ->
		if @commitStatus == 'w' then return false
		@rollbackState = @state
		@_setCommitStatus 'w'
		@_change delta
		@_changeObjectStatus 'w', delta
		try
			serverDelta = await @config.remoteWrite delta
			@_change serverDelta
			@_changeObjectStatus 's', delta
			@_changeObjectStatus undefined, delta, 3000
			@_setCommitStatus 's'
		catch err
			console.error err
			@_setState @rollbackState
			@_changeObjectStatus 'f', delta
			@_changeObjectStatus undefined, delta, 3000
			@_setCommitStatus 'f'
			# todo: re-apply server pushed since commit

		return true

	_shouldRunRemote: (query) -> ! @remoteReads[JSON.stringify query]
	_recordRemoteRead: (query) -> @remoteReads[JSON.stringify query] = true


	_change: (delta) ->
		undo = {}	
		newState = change.meta delta, @state, undo, @totalChanges
		@state = newState
		@stateHook? @state
		@_flush()

	_setState: (newState) ->
		@state = newState
		@stateHook? @state
		@_flush()

	__flush: ->
		for sub in @subs
			[res] = await @_runLocal sub
			@memo[JSON.stringify(sub.query)] = res
			resId = resultToId res
			if resId != sub.lastRes
				sub.cb res
				sub.lastRes = resId

		@totalChanges = {}

	_changeObjectStatus: (status, delta, delay = 0) ->
		statusDelta = toStatusDelta status, delta
		if delay then setTimeout (=> @_change statusDelta), delay
		else @_change statusDelta

	_setCommitStatus: (s) ->
		@commitStatus = s
		@commitHook? @commitStatus

	_runLocal: ({fatQuery, query}, sync = false) ->
		popsiqlRamda = popsiql.ramda @config.model, @state
		ramdaRead = (fatQuery) =>
			popsiqlRamda.read fatQuery, (entity, id, o) =>
				if @state[entity]?[id]?._ then merge o, {_: @state[entity][id]._}
				else o
				
		if sync then return popsiql.query.runFatQuerySync @config.model, ramdaRead, fatQuery, query
		else return popsiql.query.runFatQuery @config.model, ramdaRead, fatQuery, query


extractStatusDelta = (delta) ->
	fmapO delta, (items, entity) ->
		fmapO items, (entityDelta, id) -> {}

# {Person: {1: {name: 'Sara'}, 2: {...}}} -> {Person: {1: {_: 'w'}, 2: {_: 'w'}}
toStatusDelta = (status, delta) ->
	fmapO delta, (items, entity) ->
		fmapO items, (entityDelta, id) ->
			(currentData) ->
				if status == undefined
					if equals ['_'], keys currentData then undefined
					else dissoc '_', currentData
				else merge currentData, {_: status}




