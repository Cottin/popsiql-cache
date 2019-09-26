{} = R = require 'ramda' # auto_require: ramda
{$, $$} = RE = require 'ramda-extras' # auto_require: ramda-extras
[ːjoined, ːuserId, ːcolor, ːname, ːend, ːemail, ːid, ːdate, ːactivity, ːavatar, ːstart, ːgoal, ːisLate] = ['joined', 'userId', 'color', 'name', 'end', 'email', 'id', 'date', 'activity', 'avatar', 'start', 'goal', 'isLate'] #auto_sugar

_ = (...xs) -> xs



module.exports =
	me: ({auth: {firebaseId}}) ->
		User1: _ {firebaseId, ːid, ːname, ːavatar, ːemail},
			memberships: _ {},
				group: _ {ːname},
					members: _ {},
						user: _ {ːavatar}

	group: ({url: {groupId}}) ->
		Group1: _ {id: groupId, ːstart, ːend},
			members: _ {ːgoal, ːcolor, ːjoined}, 
				user: _ {ːavatar}

			workouts: _ {ːdate, ːactivity, ːisLate, ːuserId}
			numWorkouts: {}




