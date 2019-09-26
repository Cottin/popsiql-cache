{__, match, test, type} = require 'ramda' #auto_require: ramda
{$} = require 'ramda-extras' #auto_require: ramda-extras

colors = require './colors'

warn = (msg) ->
	console.warn msg
	return {}

unit = (x, base = 0) ->
	if type(x) == 'Number'
		return (x + base) / 10 + 'rem'
	else if ! isNaN(x) # we allow numbers as strings to eg. '2' so we can be a bit lazy in parsing
		x_ = parseFloat(x)
		return (x_ + base) / 10 + 'rem'
	else
		RE = /^(\d+)\+(\d)(vh|vw)?$/
		if test RE, x
			[_, num_, extra, vhvw] = match RE, x
			num = parseInt(num_) + base
			return "calc(#{num/10}rem + #{extra * 5 / 10}#{vhvw || 'vw'})"
		else
			return x

f = (x) ->
	ret = {}
	if type(x) != 'String' then return warn "font expected type string, given: #{x}"
	
	RE = ///^
	([a-z_]) # family
	([\d]{1,2}(?:\+\d)?|_) # size
	((?:[a-z]{2,3})(?:-\d)?|__)? # color
	(\d|_)? # weight
	(\d|_)? # shadow
	$///

	if ! test RE, x then return warn "Invalid string given for font: #{x}"
	[_, family, size, clr, weight, shadow] = match RE, x

	switch family
		when 'a' then ret.fontFamily = "Arial"
		when 'c' then ret.fontFamily = "Courier"
		when '_' then # no-op
		else return warn "invalid family '#{family}' for t: #{x}"

	if size != '_' then ret.fontSize = unit size, 0

	if clr && clr != '__' then ret.color = colors(clr)

	switch weight
		when '_' then # noop
		when undefined then # noop
		else ret.fontWeight = parseInt(weight) * 100

	switch shadow
		when '1' then ret.textShadow = '1px 1px 1px rgba(90,90,90,0.50)'
		when '2' then ret.textShadow = '1px 2px 0px #893D00'
		when '3' then ret.textShadow = '1px 2px 0px #000000'
		when undefined then # no-op
		when '_' then # noop
		else return warn "invalid text shadow '#{shadow}' for t: #{x}"

	return ret

bord = (x) -> border '', x
borb = (x) -> border '-bottom', x
bort = (x) -> border '-top', x
borl = (x) -> border '-left', x
borr = (x) -> border '-right', x


border = (side, x) ->
	RE = new RegExp("^(#{colors.REstr})(_(\\d))?$")
	if ! test RE, x then return warn "Invalid string given for border: #{x}"
	[_, clr, __, size] = match RE, x

	"border#{side}": "#{unit(size || 1)} solid #{colors(clr)}"

place = (clr) ->
	color = colors(clr)

	#https://css-tricks.com/almanac/selectors/p/placeholder/
	'::-webkit-input-placeholder': {color} # Chrome/Opera/Safari
	'::-moz-placeholder': {color} # Firefox 19+
	':-ms-input-placeholder': {color} # IE 10+
	':-moz-placeholder': {color} # Firefox 18-

fs = (x) ->
	if x == 'i' then fontStyle: 'italic'
	else warn "invalid font style '#{x}'"

ls = (x) -> letterSpacing: unit x

bg = (x) ->
	switch x

		# dev
		when 'lime' then backgroundColor: 'lime'
		when 'white' then backgroundColor: 'white'
		when 'teal' then backgroundColor: 'teal'
		when 'pink' then backgroundColor: 'pink'
		when 'red' then backgroundColor: 'red'
		when 'green' then backgroundColor: 'green'
		when 'blue' then backgroundColor: 'blue'
		when 'yellow' then backgroundColor: 'yellow'
		when 'lightblue' then backgroundColor: 'lightblue'
		when undefined then {}
		else 
			backgroundColor: colors x

op = (x) -> opacity: x

ol = (x) -> outline: x

_cur = (x) ->
	switch x
		when 'p' then cursor: 'pointer'
		else warn "invalid cur(sor) '#{x}'"

_tabs = -> {tabSize: 2}

_ani = ->
	'& div':
		animationDuration: '0.3s'
		animationName:
			'0%': { opacity: 0.4 },
			'100%': { opacity: 1 }



#auto_export: none__
module.exports = {warn, unit, f, bord, borb, bort, borl, borr, border, place, fs, ls, bg, op, ol, _cur, _tabs, _ani}