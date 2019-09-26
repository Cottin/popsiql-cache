{} = R = require 'ramda' # auto_require: ramda
{} = RE = require 'ramda-extras' # auto_require: ramda-extras
[] = [] #auto_sugar

_ = (...xs) -> xs



module.exports =
	url: {} # set continuesly by router
	auth: {firebaseId: 'abc2'} # set by firebase. undefined = now yet gotten, null = not logged in, object = logged in
	now: 1504659869000 # Date.now() # don't use Date.now() in code, use this data point instead

	colors: [1, 2, 3, 4, 5, 6, 7, 8, 9]
	activities: [
		# FITNESS
		{id: 1, name: 'Löpning'}
		{id: 2, name: 'Gym'}
		{id: 3, name: 'Cykling'}
		{id: 4, name: 'Gång'}
		{id: 5, name: 'Gruppträning'}
		{id: 6, name: 'Simmning'}
		{id: 7, name: 'Dans'}

		# BOLLSPORTER
		{id: 8, name: 'Basket'}
		{id: 9, name: 'Bandy'}
		{id: 10, name: 'Volleyboll'}
		{id: 11, name: 'Fotboll'}

		# RACKETSPORTER
		{id: 12, name: 'Tennis'}
		{id: 13, name: 'Badminton'}
		{id: 14, name: 'Pingis'}
		{id: 15, name: 'Squash'}

		# VINTERSPORTER
		# {id: 16, name: 'Skidor'}
		# {id: 17, name: 'Längd'}
		# {id: 18, name: 'Snowboard'}
		# {id: 19, name: 'Hockey'}
		# {id: 20, name: 'Skridskor'}

		# # OUTDOORS
		# {id: 21, name: 'Klättring'}
		# {id: 22, name: 'Vandring'}

		# # ÖVRIGT
		# {id: 23, name: 'Yoga'}
		# {id: 24, name: 'Kampsport'}
		# # {id: 25, name: 'Tinder'}
		# {id: 26, name: 'Golf'}
		# {id: 27, name: 'Ridning'}
		# {id: 28, name: 'Friidrott'}

		# # VATTENSPORTER
		# {id: 29, name: 'Vindsurfing'}
		# {id: 30, name: 'Segling'}
		# {id: 31, name: 'Paddling'}
		# {id: 32, name: 'Kite'}
	]
