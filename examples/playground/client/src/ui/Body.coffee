{all, isNil, map, match, props, reverse, test, toPairs, type} = R = require 'ramda' #auto_require: ramda
{fmap, change, fmapO, $, sf2} = RE = require 'ramda-extras' #auto_require: ramda-extras
[ːname, ːtext, ːprice, ːdueDate, ːdate, ːamount, ːtype] = ['name', 'text', 'price', 'dueDate', 'date', 'amount', 'type'] #auto_sugar
qq = (f) -> console.log match(/return (.*);/, f.toString())[1], f()
qqq = (f) -> console.log match(/return (.*);/, f.toString())[1], JSON.stringify(f(), null, 2)

{useState, useEffect} = React = require 'react'
createCache = require 'popsiql-cache'
popsiql = require 'popsiql'


window.R = R
window.RE = RE

model = require '../app/model'
seed = require '../../../server/src/seed'

{Modal} = require './components/Modal'
PerfSpinner = require './components/PerfSpinner'

{_} = require '../setup'

code = """\
Company: _ {ːname},
	projects: _ { ːname}
"""

code2 = """
subs:
	me:
		query: ...
		norms: [
			{query: ...}
"""


defaultQuery =
	Company: _ {ːname},
		projects: _ { ːname},
			entries: _ {ːdate, ːamount, ːtext}


# class App
# 	constructor: ->
# 		@state = {}
# 		subs = []

# 	sub: (cb) -> @subs.push cb
# 	unsub: (cb) -> @subs = without [cb], @subs
# 	pub: (delta) ->
# 		@state = change delta, @state
# 		for sub in @subs
# 			sub? @state

serverData =
	Project:
		1: {id: 1, name: 'test'}

sleep = (ms) -> new Promise (res) -> setTimeout res, ms

globals = {throw: false}

cache = createCache
	model: model
	initialState: {}
	remoteRead: (remoteQuery) ->
		await sleep 3000
		return fetch CONFIG_API_URL,
			method: 'POST'
			headers: {'Content-Type': 'application/json'}
			body: JSON.stringify remoteQuery
		.then (res) -> res.json()
	remoteWrite: (delta) ->
		await sleep 3000
		if globals.throw then throw new Error 'Fake server error'
		return fetch CONFIG_API_URL,
			method: 'POST'
			headers: {'Content-Type': 'application/json'}
			# JSON does not support undefined -> switch to nulls
			body: JSON.stringify {DELTA: delta}, (k, v) -> if v == undefined then null else v
		.then (res) ->
			serverDelta = await res.json()
			fullDelta = fmapO serverDelta, (items, entity) ->
				return fmapO items, (v, k) -> if isNil v then undefined else v
			return fullDelta
	report: (o) -> # console.log o

window.cache = cache


useCache = () ->
	 # seems changes doesn't trigger change (because ref not value?), so count is workaround
	[count, setCount] = useState 0
	[state, setState] = useState cache.state
	[changes, setChanges] = useState cache.changes
	[commitStatus, setCommitStatus] = useState cache.commitStatus
	useEffect () ->
		cache.commitHook = (newCommitStatus) -> setCommitStatus newCommitStatus
		cache.stateHook = (currentState, currentChanges) ->
			setCount count + 1
			setState cache.state
			setChanges cache.changes

		return () ->
			cache.commitHook = null
			cache.stateHook = null

	return [state, changes, commitStatus, count]

useQuery = (query, key, subType = 'full') ->
	t0 = performance.now()
	[localRes] = cache.queryLocal query, subType # get initial data if there is any
	console.log "queryLocal #{ Math.round performance.now() - t0 } ms :", localRes
	[cacheCounter, setCacheCounter] = useState 0

	useEffect () ->
		cb = (res) -> setCacheCounter (count) -> count + 1
		return cache.sub query, subType, cb, key, localRes

	# https://github.com/facebook/react/issues/14476#issuecomment-471199055
	# Note: we know dataQueries are small shallow objects anyway so JSON.stringify
	# shouldn't put any significant burden. But test it some time to be sure :)
	, [JSON.stringify(query)]

	qq -> cacheCounter
	return localRes

# useQuery = (query, localOnly = false) ->
# 	[state, setState] = useState null

# 	console.log {query}
# 	useEffect () ->
# 		console.log 'useEffect'
# 		if localOnly then unsub = cache.subLocal query, (newState) -> setState newState
# 		else unsub = cache.sub query, (newState) -> setState newState

# 		return unsub

# 	# https://github.com/facebook/react/issues/14476#issuecomment-471199055
# 	# Note: we know dataQueries are small shallow objects anyway so JSON.stringify
# 	# shouldn't put any significant burden. But test it some time to be sure :)
# 	, [JSON.stringify(query)]

# 	return state

useDeepState = (initial) ->
	[state, setState] = useState initial

	setDeepState = (spec) ->
		setState (prevState) ->
			newState = change spec, prevState
			return newState

	return [state, setDeepState]


count = 1
Body = () ->
	[state, setState] = useDeepState
		subs: {}, query: null, delta: null, showQueries: false, showDeltas: false, throw: false, subType: 'full',
	{query, delta} = state

	_ {is: 'Body', s: 'xc__ xg1 p10_10 h100vh'},
		_ {s: 'xrb_ h100%'},
			_ Left, {}
			_ {s: 'xg1 w50%'},
				_ {s: 'bgwh-4 fa11bk-53 p8_10 mb5'}, 'APP STATE: '
				_ Code, {text: query && popsiql.utils.queryToString(query) || sf2(delta), s: 'h200 ovs'}
				_ {s: 'xrbc mt10'},
					_ {s: 'xrb_'},
						_ Link, {s: 'mr15', onClick: -> setState {showQueries: true}}, 'Queries'
						_ Link, {s_: 'mr15 f__re', onClick: -> setState {showDeltas: true}}, 'Deltas'
					_ {s: 'xrbc'},
						if query
							_ {s: 'bgbu p10 fa11wh5 _curp', onClick: ->
								subId = count++
								setState {subs: {[subId]: {query,  data: null, subType: state.subType}}}
								# qq -> state.localOnly
								# if state.localOnly
								# 	cache.subLocal query, (data) -> setState {subs: {[subId]: {data}}}
								# else
								# 	cache.sub query, (data) -> setState {subs: {[subId]: {data}}}
							}, 'SUBSCRIBE'
						if delta
							_ {s: 'xr__'},
								_ {s: 'p10 fa11bk-45 _curp', onClick: ->
									cache.undo()
								}, 'UNDO'
								_ {s: 'bgre p10 fa11wh5 _curp', onClick: ->
									cache.edit delta
								}, 'EDIT'
								_ {s: 'bgbu p10 fa11wh5 _curp', onClick: ->
									cache.commit()
								}, 'COMMIT'

				_ {s: 'xrbc mb20'},
					_ {s: 'xrb_'},
						_ {s: 'xr__'},
							_ {s: 'fa11bk-46 mr5'}, 'Throw:'
							_ 'input', {type: 'checkbox', checked: state.throw,
							onChange: (e) ->
								globals.throw = e.target.checked
								setState({throw: e.target.checked})}

							# _ {s: 'fa11bk-46 mr5'}, 'Local only:'
							# _ 'input', {type: 'checkbox', checked: state.localOnly,
							# onChange: (e) ->
							# 	setState({localOnly: e.target.checked})}

						_ {s: 'xr__'},
							_ {s: 'fa11bk-46 ml10 mr5'}, 'Type:'
							_ 'label', {s: 'xr__ mr10'},
								_ 'input', {type: 'radio', checked: state.subType == 'full', id: 'full',
								onChange: (e) -> setState({subType: 'full'})}
								_ {}, 'Full'
							_ 'label', {s: 'xr__ mr10'},
								_ 'input', {type: 'radio', checked: state.subType == 'local',
								onChange: (e) -> setState({subType: 'local'})}
								_ {}, 'Local'
							_ 'label', {s: 'xr__'},
								_ 'input', {type: 'radio', checked: state.subType == 'edit',
								onChange: (e) -> setState({subType: 'edit'})}
								_ {}, 'Edit'

				_ {s: '_ani'},
					$ state.subs, toPairs, reverse, map ([id, {query, subType, data}]) ->
						_ Sub, {key: id, query, subType, data, id,
						onDelete: -> setState {subs: {[id]: undefined}}}
					_ {s: 'posa top5 lef40% bgwh p10 bordbk_1'},
						React.createElement PerfSpinner, {}
			if state.showQueries
				_ Modal, {onClickOutside: -> setState {showQueries: false},
				onClickInside: -> setState {showQueries: false}},
					_ {s: 'bgwh p20'},
						fmap queries, ({name, query}) ->
							_ Link, {s_: 'p10_0', key: name, onClick: ->
								setState {query: null, delta: null}
								setState {query}
								}, name
			if state.showDeltas
				_ Modal, {onClickOutside: -> setState {showDeltas: false},
				onClickInside: -> setState {showDeltas: false}},
					_ {s: 'bgwh p20'},
						fmap deltas, ({name, delta}) ->
							_ Link, {s_: 'f__re p10_0', key: name, onClick: ->
								setState {delta: null, query: null}
								setState {delta}}, name

Left = ->
	[cacheState, cacheChanges, commitStatus, count] = useCache()
	_ {s: 'xg1 pr5 h100% w50% xc__'},
		_ {s: 'bgwh-4 fa11bk-53 p8_10 mb5'}, 'COMMIT STATUS: ' + friendlyCommitStatus commitStatus
		# _ TextArea, {value: sf2(data), s: 'h100%'}
		_ Code, {text: sf2(cacheChanges), s: 'xg1 mb5 xb1'}
		_ Code, {text: sf2(cacheState), s: 'xg1 xb5'}

TextArea = (props) ->
	_ 'textarea', {...props, s: 'bgwh bordwh p10 w100% fc10bk-8 _tabs'}, code

Sub = ({query, subType, data, id, onDelete}) ->
	data = useQuery query, id, subType
	console.log 'RENDER Sub: ', data
	_ {s: 'mb20 posr'},
		_ {s: 'posa top1 rig20 fa9bk-85'}, subType
		_ {s: 'posa top1 rig5 fa10re5'}, id
		_ {s: 'posa top10 rig5 fa10bu5 _curp', onClick: onDelete}, 'Delete'
		_ {s: 'bgwh-4 p10 fc10bk-8 whp'}, popsiql.utils.queryToString query
		_ {s: 'bgwh bordwh w100% fc10bk-8 whp p10 h350 ovs'}, sf2 data

SubTest = ({query, subType, id, onDelete}) ->
	[, setCount] = useState 0
	[localRes] = cache.queryLocal query # get initial data if there is any

	useEffect () ->
		cb = (res) ->
			console.log 'cb'
			setCount (count) ->
				console.log "setCount: #{count + 1}"
				count + 1

		return cache.sub query, subType, cb, localRes

	# https://github.com/facebook/react/issues/14476#issuecomment-471199055
	# Note: we know dataQueries are small shallow objects anyway so JSON.stringify
	# shouldn't put any significant burden. But test it some time to be sure :)
	, [JSON.stringify(query)]

	data = localRes

	console.log 'RENDER Sub: ', data
	_ {s: 'mb20 posr'},
		_ {s: 'posa top1 rig5 fa10re5'}, id
		_ {s: 'posa top10 rig5 fa10bu5 _curp', onClick: onDelete}, 'Delete'
		_ {s: 'bgwh-4 p10 fc10bk-8 whp'}, popsiql.utils.queryToString query
		_ {s: 'bgwh bordwh w100% fc10bk-8 whp p10 h350 ovs'}, sf2 data




Link = (props) ->
	_ {...props, s: 'fa11bu6 _curp ' + props.s_}

Code = (props) ->
	_ {...props, s: 'bgwh bordwh w100% fc10bk-8 whp p10'}, props.text


friendlyCommitStatus = (s) ->
	switch s
		when 'w' then 'Waiting...'
		when 'f' then 'Failed!'
		when 's' then 'Succeeded'
		else s

queries = [
	{name: 'all kidnaping', query:
		Company: _ {id: 2},
			projects: _ { ːname},
				entries: _ { ːamount, text: {like: 'kidnap'}}
	}
	{name: 'company names', query:
		Company: _ { ːname}
	}
	{name: 'entry.id = 1', query:
		WorkEntry1: _ {id: 1, ːdate, ːamount, ːtext}#,
			# project: _ {ːname},
			# 	company: _ {ːname}
	}
	{name: 'all projects', query:
		Project: _ {ːname, ːprice, ːtype, ːdueDate},
			entries: _ {ːamount, ːtext}
	}
	{name: 'projects 12 april -93', query:
		Project: _ {dueDate: '1993-04-12', ːname},
			entries: _ {ːamount, ːtext}
	}
]

deltas = [
	{name: '3 hour to entry 1', delta:
		WorkEntry: {1: {amount: 3}}
	}
	{name: '4 hour to entry 1', delta:
		WorkEntry: {1: {amount: 4}}
	}
	{name: 'change workentries', delta:
		WorkEntry:
			1: {amount: 3}
			2: undefined
			11: undefined
			'-1': {id: -1, amount: 1, text: 'calling kidnap off', projectId: 1}
	}
]

					



module.exports = Body
