import reactHotLoader from 'react-hot-loader'
import React from 'react'
import { render } from 'react-dom'
import Main from './ui/Main'

const root = document.createElement('div')
root.id = 'root'
document.body.appendChild(root)

render(<Main />, root)
