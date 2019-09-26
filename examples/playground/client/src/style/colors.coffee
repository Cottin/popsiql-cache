{join, match, test} = require 'ramda' #auto_require: ramda
{fmapO} = require 'ramda-extras' #auto_require: ramda-extras
[] = [] #auto_sugar

_ = (...xs) -> xs

warn = (msg) ->
	console.warn msg
	return 'fuchsia'

RE = ///^
([a-z]{2,3}) # color
(-(\d))? # opacity
$///

# https://stackoverflow.com/questions/17242144/javascript-convert-hsb-hsv-color-to-rgb-accurately
hsvToRgb = (h, s, v) ->
	r = g = b = i = f = p = q = t = undefined
	i = Math.floor(h * 6)
	f = h * 6 - i
	p = v * (1 - s)
	q = v * (1 - (f * s))
	t = v * (1 - ((1 - f) * s))
	switch i % 6
		when 0 then _ r = v, g = t, b = p
		when 1 then _ r = q, g = v, b = p
		when 2 then _ r = p, g = v, b = t
		when 3 then _ r = p, g = q, b = v
		when 4 then _ r = t, g = p, b = v
		when 5 then _ r = v, g = p, b = q
	return [Math.round(r * 255), Math.round(g * 255), Math.round(b * 255)]

baseColors =

	wh: _ 0, 0, 100
	bk: _ 0, 0, 0
	bu: _ 212, 67, 89
	re: _ 360, 58, 95



baseColorsRgb = fmapO baseColors, ([h, s, b]) -> join ', ', hsvToRgb h/360, s/100, b/100

colors = (clr) ->
	if ! test RE, clr then return warn "Invalid color: #{clr}"
	[_, base, ___, _opacity] = match RE, clr

	if ! baseColorsRgb[base] then return warn "Color base does not exist: #{base}"

	opacity = if _opacity then parseInt(_opacity) / 10 else 1.0

	return "rgba(#{baseColorsRgb[base]}, #{opacity})"

colors.RE = RE
colors.REstr = "(?:[a-z]{2,3})(?:-\\d)?"

module.exports = colors

