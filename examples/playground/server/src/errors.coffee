
customServerError = (name, staticMsg) ->
	# serverError set to true => an application specific error as opposed to normal
	# javascript errors such as ReferenseError, TypeError etc.
	class ServerError extends Error
		constructor: (msg) ->
			if staticMsg then super staticMsg else super msg
			@serverError = true
			@name = name
			Error.captureStackTrace this, ServerError

# Something in user input is not valid
ValidationError = customServerError 'ValidationError'

# Something is incorrect with input data or stored data or similar but this is different from
# a ValidationError in that it shouldn't occur with correct application usage. Ie. if this is seen
# there is a chance it occured due to some bug or incorrect usage of api by developer.
IncorrectError = customServerError 'IncorrectError'

# User not logged in
NoAuthError = customServerError 'NoAuthError', 'Du är inte inloggad'

# User not permitted to do something
PermissionError = customServerError 'PermissionError'

# DB-related error
DBError = customServerError 'DBError'


#auto_export: none_
module.exports = {customServerError, ValidationError, IncorrectError, NoAuthError, PermissionError, DBError}