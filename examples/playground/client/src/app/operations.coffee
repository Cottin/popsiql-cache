

module.exports = (C) ->
	Workout:
		toggle: ({me: {userId}}) -> (activity, date) ->
			existing =  C Workout: _ {date, userId}
			if existing
				if existing.activity == activity
					C.remove Workout: _ {id: existing.id}
				else C.update Workout: _ {id: existing.id, activity}
			else
				C.create Workout: _ {userId, date, activity, isLate: false}

		toggle: ({me: {userId}}) -> (activity, date) ->
			existing =  C Workout: _ {date, userId}
			C TOGGLE: Workout: _ {id: existing.id, date, activity, userId, isLate}
