config = require './../config'
invoke = require 'invoke'
request = require 'request'
_ = require 'underscore'
querystring = require 'querystring'

dataHandler =
	processTrack: (tr) ->
		track = {}
		track.source = 'vk'
		track.artist_name = tr.artist
		track.song_name = tr.title
		track.foreign_id = tr.aid
		track.url = tr.url
		return track

	processTracks: (tracks) ->
		return [] if not _.isArray tracks
		_.map tracks, dataHandler.processTrack

vk =
	url: 'https://api.vk.com/method/'

	request: (method, params, options, cb) ->

		params.access_token = config.vk.access_token
		params.format = 'json'

		options = _.defaults options || {},
			method: 'GET'
			#json: true
			timeout: config.vk.timeout

		if (options.method == 'GET')
			url = vk.url + method + '?' + querystring.stringify(params)
		else
			options.form = params
			options.headers = {'content-type' : 'application/x-www-form-urlencoded'}

		console.log url
		console.log options
		request url, options, (err, r, body) ->
			console.log 'vk reponse:' + body
			statusCode = r && r.statusCode || 500

			if !err and statusCode == 200
				data = JSON.parse(body) ||  {}
				console.log 'data:' + data
				console.log 'data.response:' + data.response
				cb null, data.response || {}
			else
				cb err || data.response || body, 500


exports.request =
	getTrackUrl:	(query, callback) ->
		vk.request 'audio.search', {q: query, sort: 2, count: 1}, { method: 'GET' }, (err, data) ->
			if err
				callback err, data
			else
				console.log data
				if (data && data[0] > 0)
					track = dataHandler.processTrack data[1]
					callback null, track
				else
					callback 404, null