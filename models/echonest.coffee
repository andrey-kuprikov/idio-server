config = require './../config'
invoke = require 'invoke'
request = require 'request'
_ = require 'underscore'
querystring = require 'querystring'


# обработчик данных
dataHandler =
	processTrack: (tr) ->
		track = {}
		track.source = 'echonest'
		track.artistName = tr.artist_name
		track.trackName = tr.title
		track.albumName = null
		track.durationSec = null
		track

	processTracks: (tracks) ->
		return [] if not _.isArray tracks
		_.map tracks, dataHandler.processTrack


echonest =
	url: 'http://developer.echonest.com/api/v4/'

	request: (url, params, options, cb) ->

		params.api_key = config.echonest.api_key
		params.format = 'json'

		options = _.defaults options || {},
			method: 'GET'
			#json: true
			timeout: config.echonest.timeout

		if (options.method == 'GET')
			url = url + '?' + querystring.stringify(params)
		else
			options.form = params
			options.headers = {'content-type' : 'application/x-www-form-urlencoded'}

		console.log url
		console.log options
		request echonest.url + url, options, (err, r, body) ->
		#request 'http://127.0.0.1:8888/hello/', options, (err, r, body) ->
			console.log 'echonest reponse:' + body
			statusCode = r && r.statusCode || 500

			if !err and statusCode == 200
				data = JSON.parse(body) ||  {}
				console.log 'data:' + data
				console.log 'data.response:' + data.response
				cb null, data.response || {}
			else
				cb err || body.response || body, 500


exports.request =
	createPlaylist:	(user, callback) ->
		inv = invoke (d, cb) ->
			echonest.request 'catalog/list', {}, { method: 'GET' }, cb
		inv.then (d, cb) ->
			console.log d
			for c in d.catalogs
				if c.name == user.login + '.common'
					echonest.request 'catalog/delete', { id: c.id }, { method: 'POST' }, cb
					return
			cb null, null
		inv.rescue (err) ->
			callback err, 500
		inv.end null, (d, cb) ->
			echonest.request 'catalog/create', { name: user.login + '.common', type: 'song' }, { method: 'POST' }, callback

	#update playlist items
	updatePlaylist:	(user, data, callback) ->
		echonest.request 'catalog/update', { id: user.playlistId , data: JSON.stringify(data) }, { method: 'POST' }, callback

	#get playlist data
	getPlaylist: (playlistId, callback) ->
		echonest.request 'catalog/profile', { id: playlistId }, { method: 'GET' }, callback		
