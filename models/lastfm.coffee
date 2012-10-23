config = require './../config'
request = require 'request'
_ = require 'underscore'

#http://ws.audioscrobbler.com/2.0/?method=user.getTopTracks&api_key=ba5259fc36b7d1b4fc2ec96215115089&format=json&user=andreykuprikov&period=12month

getMethodUrl = (method, params) ->
	return 'http://ws.audioscrobbler.com/2.0/?method=' + method + '&api_key=' + config.lastfmKey + '&format=json'

exports.getTopTracks = (login, callback) ->
	url = getMethodUrl('user.getTopTracks')
	url = url + '&user=' + login + '&period=12month&limit=5'
	console.log 'ggg'
	request.get url, (err, response, body) ->
		console.log 'ggg1'
		if (err || response.statusCode != 200)
			callback err, null
		data = JSON.parse(body)
		console.log 'ggg2'
		result = _.map data.toptracks.track, (track) ->
			res = 
				songName: track.name
				artistName: track.artist.name
				count: track.playcount
		console.log 'ggg3'
		callback null, result
