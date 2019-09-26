React = require 'react'
fela = require 'fela'
prefixer = require('fela-plugin-prefixer').default
fallbackValue = require('fela-plugin-fallback-value').default
shortstyle = require 'shortstyle'
{omit, props, type} = require 'ramda' #auto_require: ramda
{fchange} = require 'ramda-extras' #auto_require: ramda-extras

styleMaps = require './styleMaps'
felaRenderer = require './felaRenderer'

# attrMaps = {}
# attrMaps.is = (x) -> {id: x} # hack to be able to use is as a label

parseShortstyle = shortstyle omit(['unit'], styleMaps), styleMaps.unit

createElementFela = ->
	[a0] = arguments

	if 'Object' == type a0
		comp = 'div'
		props = a0
		children = Array.prototype.splice.call(arguments, 1)
	else
		comp = a0 # either a string or a component, eg. 'span' or Icon
		props = arguments[1]
		children = Array.prototype.splice.call(arguments, 2)

	felaStyle = parseShortstyle props.s
	felaClassName = felaRenderer.renderRule (-> felaStyle), {}
	props_ = fchange props,
		s: undefined
		className: (c) -> if c then c + ' ' + felaClassName else felaClassName
		is: undefined # hack to be able to use is as a label
		id: (id) -> id || props['is'] || undefined

	# console.log 1, comp, props_, children

	return React.createElement comp, props_, children...

module.exports = createElementFela


	# [comp, props, children] = Shortstyle.createElementHelper(felaRenderer)(arguments...)
	# React.createElement comp, props, children...

	# createElementHelper = (felaRenderer) ->
	# 	if !felaRenderer then throw new Error 'Missing felaRenderer'
	# 	return () ->
	# 		[a0] = arguments

	# 		if type(a0) == 'Object'
	# 			comp = 'div'
	# 			props = a0
	# 			children = Array.prototype.splice.call(arguments, 1)
	# 		else
	# 			comp = a0 # either a string or a component, eg. 'span' or Icon
	# 			props = arguments[1]
	# 			children = Array.prototype.splice.call(arguments, 2)

	# 		if !props.s then return [comp, props, children]

	# 		felaStyle = parse props.s
	# 		qqq 1, felaStyle
	# 		felaClassName = felaRenderer.renderRule (-> felaStyle), {}
	# 		props_ = fchange props,
	# 			s: undefined
	# 			className: (c) -> if c then c + ' ' + felaClassName else felaClassName

	# 		return [comp, props_, children]

	# return {parse, createElementHelper}
