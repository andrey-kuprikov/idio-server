crypto = require 'crypto'

# для обрезки пробелов в начале и конце сторки
if typeof String.prototype.trim == "undefined"
	String.prototype.trim = () -> #String(this)
		String(this).replace /^ +| +$/g, ''

exports.md5 = (data) ->
	return crypto.createHash(data)

exports.makeHash = (trackName, albumName, artistName) ->
	result = ''
	if trackName
		result = 'track'+artistName.toLowerCase()+trackName.toLowerCase()
	else if albumName
		result = 'album'+artistName.toLowerCase()+albumName.toLowerCase()
	else
		result = 'artist'+artistName.toLowerCase()
	return result


exports.getParam = (param) ->
	try
		param = decodeURIComponent param
	catch e
		# для отлова ошибки (вывести ссылку): URIError: URI malformed.
		# Пример: decodeURIComponent("localhost?q=%")
		process.stderr.write e.message + '. Param: ' + param

	if param.indexOf(' ') is -1

		param = param.replace /\+/g, ' '
		param = param.replace(/%2f/g, '/');

	param


exports.setParam = (param) ->
	return '' if !param
	param = param.replace /\//g, '%2f'

	if not param.match(/(\+)|(')|(")/)
		param = param.replace /\s/g, '+'
	else
		param = encodeURIComponent param
	param


exports.cacheImageUrl = (url, source) ->
	return null if !url
	arr = url.split '/'
	arr[2] = source + '.i.tracksflow.com'

	url = arr.join '/'
	url

exports.splitParams = (str) ->
	[artist, album] = str.split '_'
	[(exports.getParam artist), exports.getParam album]

exports.getCookies = (req) ->
	cookies = {}
	if !req.headers.cookie
		return cookies

	for c in request.headers.cookie.split(';')
    	parts = c.split '='
    	cookies[ parts[ 0 ].trim() ] = ( parts[ 1 ] || '' ).trim()
    return cookies