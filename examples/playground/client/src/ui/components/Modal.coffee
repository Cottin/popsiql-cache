{filter, props} = R = require 'ramda' #auto_require: ramda
{} = RE = require 'ramda-extras' #auto_require: ramda-extras
[] = [] #auto_sugar

React = require 'react'
ReactDOM = require 'react-dom'

{_} = require '../../setup'


# stolen from https://reactjs.org/docs/portals.html
modalRoot = document.getElementById 'modal-root'

class ModalBase extends React.Component
	constructor: (props) ->
		super(props)
		@el = document.createElement 'div'

	componentDidMount: ->
		# The portal element is inserted in the DOM tree after
		# the Modal's children are mounted, meaning that children
		# will be mounted on a detached DOM node. If a child
		# component requires to be attached to the DOM tree
		# immediately when mounted, for example to measure a
		# DOM node, or uses 'autoFocus' in a descendant, add
		# state to Modal and only render the children when Modal
		# is inserted in the DOM tree.
		modalRoot.appendChild @el
		document.getElementById('root').style.filter = "url('#blurFilter')"


	componentWillUnmount: ->
		modalRoot.removeChild @el

	render: ->
		ReactDOM.createPortal @props.children, @el

Modal = (props) ->
	_ ModalBase, {},
		_ {s: 'posf w100% h100% p0_20 z10 xrcc bgbk-6', onClick: -> props.onClickOutside?()},
			_ {s: 'mt-40vh', onClick: (e) ->
					props.onClickInside?()
					e.stopPropagation()},
				props.children

		_ 'svg', {height: 0, width: 0},
			_ 'filter', {id: "blurFilter"},
				_ 'feGaussianBlur', {stdDeviation: 5}

module.exports = {Modal}

