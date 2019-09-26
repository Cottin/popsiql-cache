{groupBy, indexBy, map, prop} = R = require 'ramda' # auto_require: ramda
{fchange, $, $$} = RE = require 'ramda-extras' # auto_require: ramda-extras
[ːemail, ːid, ːavatar, ːname] = ['email', 'id', 'avatar', 'name'] #auto_sugar

immer = require 'immer'

{df} = require '../lib/utils'


# state = {person: {name: 'Elin'}}
# changes = []
# producerOLD = undef (draft) ->
# 	draft.person.age = 32
# producer = undef (draft) ->
# 	changeM {person: {age: 32}}, draft
# nextState = immer.produce state, producer, (patches) -> changes.push ...patches
# console.log 11111111111
# console.dir changes



module.exports =
	# meʹ: ({me, url: {group}}) ->
	# 	User1: _ {firebaseId, ːid, ːname, ːavatar, ːemail},
	# 		memberships: _ {},
	# 			group: _ {ːname},
	# 				members: _ {},
	# 					user: _ {ːavatar}

	group2_debug: ({now, group, url: {groupId}}) ->
		numWorkoutsMap = $ group.numWorkouts, indexBy prop('userId')
		workoutsMap = $ group.workouts, groupBy prop('userId')

		fchange group,
			numWorkouts: undefined
			members: map (m) ->
				tot = numWorkoutsMap[m.userId].count
				weeks = df.diff now, m.joined, 'week'
				avg = (tot / weeks).toFixed 1
				workouts = workoutsMap[m.userId]
				return {...m, avg, tot, workouts}

				





		
