fela = require 'fela'
prefixer = require('fela-plugin-prefixer').default
fallbackValue = require('fela-plugin-fallback-value').default
embedded = require('fela-plugin-embedded').default

felaRenderer = fela.createRenderer {plugins: [prefixer(), fallbackValue(), embedded()]}

felaRenderer.renderStatic """
html, body {
  display: flex;
  flex-grow: 1;
  margin: 0;
  padding: 0;
  font-family: 'Open Sans', sans-serif;
}

html {
  font-size: calc(9px + 0.3vw);
  background-color: #F1F1F1;
  color: rgba(0, 0, 0, 0.7);
}

@media screen and (max-width: 320px) {
  html {
    font-size: 10px;
  }
}

@media screen and (min-width: 1000px) {
  html {
    font-size: 12px;
  }
}

* {
  box-sizing: border-box;
}

#root {
  display: flex;
  flex-grow: 1;
}


/* RESETS */
a {
  text-decoration: none;
}

input {
  background: none;
  border: none;
  outline: none;
}


"""

module.exports = felaRenderer
