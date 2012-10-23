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
	createPlaylist:		(user, callback) ->
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


	getSimilarTracks:	(artist, title, limit, callback) ->
		if !title
			echonest.request 'playlist/basic?' + echonest.setParams({ artist:artist, type:'artist-radio', results:limit }), null, (err, data) ->
				data = dataHandler.processTracks data.songs || []
				callback err, data

		else
			inv = invoke (d, cb) ->
				echonest.request 'song/search?' + echonest.setParams({ results:1, artist:artist, title:title }), null, cb

			inv.then (d, cb) ->
				if !d.songs or !d.songs.length
					callback 'Track not found'
					return

				p = { type:'song-radio', results:limit }
				if d.songs[0].id
					p.song_id = d.songs[0].id
				else if d.songs[0].tracks?[0].id
					p.track_id = d.songs[0].tracks?[0].id

				echonest.request 'playlist/basic?' + echonest.setParams(p), null, cb

			inv.rescue (err) -> callback err, 500
			inv.end null, (data, cb) ->
				data = dataHandler.processTracks data.songs || []
				callback null, data
