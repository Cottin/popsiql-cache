{hot} = require 'react-hot-loader'
React = require 'react'
{RendererProvider} = require 'react-fela'

felaRenderer = require '../style/felaRenderer'

Body = require './Body'


Main = ->
	React.createElement RendererProvider, {renderer: felaRenderer},
		React.createElement Body

module.exports = hot(module)(Main)
