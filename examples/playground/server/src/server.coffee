{empty, isNil, keys, length, map, test, type} = R = require 'ramda' # auto_require: ramda
{fmapO, maxIn, $} = RE = require 'ramda-extras' # auto_require: ramda-extras
[ːramda] = ['ramda'] #auto_sugar

require('dotenv').config()

{join} = require 'ramda' #auto_requireːramda
{} = require 'ramda-extras' #auto_requireːramda-extras
express = require 'express'
bodyParser = require 'body-parser'
cors = require 'cors'
morgan = require 'morgan'


model = require './model'
data = require './seed'
popsiql = require '../../../../../popsiql/src/popsiql'
popRamda = popsiql.ramda(model, data)
log = require './log'

app = express()

app.use morgan('combined')
app.use bodyParser.urlencoded({ extended: true })
app.use bodyParser.json()

app.use cors()

toShortString = (x) ->
	if 'Array' == type x
		len = length x
		if len == 0 then return "[] (empty)"
		else if len == 1 then return "[ {} ] (1 item)"
		else if len == 2 then return "[ {}, {} ] (2 items)"
		else if len > 2 then return "[ {}, {}, ... ] (#{len} items)"
	else if 'Object' == type res
		return "{ id: #{res.id}, ... }"
	else
		return res


execQuery = (fatQuery) ->
	res = popRamda.read fatQuery
	# log toShortString res
	# log res # swich to this for more detailed debugging
	return res

execDelta = (delta) -> popRamda.write delta


app.post '/popsiql', (req, res) ->
	try 
		log '----------------------------------'

		if !req.body.DELTA # READ ###################################
			log popsiql.utils.queryToString req.body
			[result, normalized] = await popsiql.query.runQuery model, execQuery, req.body
			if req.query.normalize == 'true' then res.send normalized
			else res.send result

		else # WRITE ##############################
			log JSON.stringify req.body, null, 2
			# JSON dosn't support undefined so call server with null instead and switch back here
			fullDelta = fmapO req.body.DELTA, (items, entity) ->
				return fmapO items, (v, k) -> if isNil v then undefined else v

			exec = ({entity, id, delta}) ->
				if parseInt(id) < 0
					newId = 1 + $ data[entity], keys, map(parseInt), maxIn
					newObj = {...delta, id: newId}
					popRamda.write {[entity]: {[newId]: newObj}}
					return {[entity]: {[id]: undefined, [newId]: newObj}}
				else if isNil delta
					popRamda.write {[entity]: {[id]: undefined}}
					return {}
				else
					popRamda.write {[entity]: {[id]: {...delta}}}
					return {}

			serverDelta = await popsiql.query.runDelta {model, exec, delta: fullDelta}
			qq -> serverDelta
			test123 = JSON.stringify serverDelta, (k, v) -> if v == undefined then null else v
			qq -> test123
			res.send test123
			log serverDelta

	catch err
		console.error err
		res.status(500).send(err.message)


app.listen process.env.PORT, () ->
	console.log 'Listening on ' + process.env.PORT
