utils = require './../utils'
config = require './../config'
request = require 'request'
mongoose = require 'mongoose'
invoke = require 'invoke'

echonest = require './../models/echonest'
lastfm = require './../models/lastfm'

db = mongoose.createConnection(config.mongohost, config.mongodatabase)

exports.setup = (app, config) ->
	app.post '/hello/', mainController.hello
	app.get '/hello/', mainController.hello

	app.post '/users/', mainController.addUser
	app.get '/users/', mainController.getUser
	app.delete '/users/', mainController.delUser

	app.post '/playlists/listens/', mainController.addListens

	app.get '/playlists/', mainController.getUserPlaylist

	user = require './../models/user'
	user.initialize mongoose

	session = require './../models/session'
	session.initialize mongoose

converter = 
	lastfm2echonest: (input) ->
		output = []
		for item in input
			item = 
				item_id: utils.makeHash(item.songName, null, item.artistName),
				song_name: item.songName,
				artist_name: item.artistName,
				play_count: parseInt(item.count)
			output.push { item: item }
		return output

mainController =
	getRequestUser: (req, callback) ->
		sessionId = req.cookies.sessionId
		if !sessionId
			console.log 'authentication failed'
			callback 'authentication failed', 403
			return

		inv = invoke (d, cb) ->
			Session = db.model 'session'
			Session.findById sessionId, cb
		inv.rescue (err) ->
			console.log err
			callback err, null
		inv.end null, (d, cb) ->
			User = db.model 'user'
			user = User.findById d.userId, callback

	hello: (req, resp) ->
		console.log req.body

		resp.send 200

	addUser: (req, resp) ->
		userJson = req.body

		setListenedTracks = (user, cb) ->
			console.log 'ffg'
			lastfm.getTopTracks user.lastfm.login, (err, data) ->
				console.log data
				if err
					cb err, data
				else
					echonest.request.updatePlaylist user, converter.lastfm2echonest(data), cb
			#todo: facebook
			#tracks = _.union tracks, facebook.getTopTracks(user.facebook)


		inv = invoke (d, cb) ->
			if !userJson || !userJson.login || !userJson.passwordHash
				cb 'Missing required param', 400
				return
			User = db.model 'user'
			User.findOne {login: userJson.login}, (err, user) ->
				if err
					cb err, 500
				else if user
					cb 'user already exists', 409
				else
					cb null, user

		inv.then (d, cb) ->
			User = db.model 'user'
			user = new User(userJson)

			user.save (err) ->
				if (err)
					cb err, 500
				else
					cb null, user

		inv.then (user, cb) ->
			echonest.request.createPlaylist user, (err, data) ->
				if err
					cb err, 500
				else
					user.playlistId = data.id
					user.save()
					cb null, { user: user, echonest: data }

		inv.then (data, cb) ->
			setListenedTracks data.user, (err, d) ->
				cb null, data
			console.log 'fff2'

		inv.rescue (err) ->
			console.log err
			resp.send 500
			return

		inv.end null, (d, cb) ->
			console.log 'fff3'
			resp.set 'Location', '/users/?login=' + d.user.login + '&passwordHash=' + d.user.passwordHash
			resp.send 201
			console.log 'fff4'

	getUser: (req, resp) ->
		createSession = (user, cb) ->
			Session = db.model 'session'

			session = new Session {userId: user._id}
			session.save (err) ->
				if (err)
					cb err, null
					console.log 'error while creating new session'
					return
			
				data =
					user: user.toObject()
					sessionId: session._id
				console.log 'response:'
				console.log data
				cb null, data

		console.log 'get user'
		login = req.query.login
		passwordHash = req.query.passwordHash
		console.log login
		console.log passwordHash
		console.log req.query

		User = db.model('user')

		filter=
			login: login

		if passwordHash
			filter.passwordHash=passwordHash

		User.findOne filter, (err, user) ->
			if err
				console.log '500'
				resp.send 500
				return
			if !user
				console.log '404'
				resp.send 404
				return

			console.log '200 OK'
			if passwordHash
				createSession user, (err, data) ->
					if (err)
						resp.send 500
						return
					console.log 'Cookie: sessionId=' + data.sessionId
					resp.cookie 'sessionId', data.sessionId, { maxAge: 2000000000 }
					resp.send 200, data.user
			else
				resp.send 200, user

	delUser: (req, resp) ->
		login = req.query.login

		User = db.model('user')

		User.findOneAndRemove {login: login}, (err, user) ->
			if err
				resp.send 500
				return
			if !user
				resp.send(404)
				return
			resp.send(200)

	addListens: (req, resp) ->
		console.log 'method undefined'
		return
		tracks = req.body
		User = db.model 'user'
		console.log('get user method undeined')
		user = User.findOne()
		playlist.listen(user._id, tracks)

	getUserPlaylist: (req, resp) ->
		inv = invoke (d, cb) ->
			mainController.getRequestUser req, cb
		inv.then (d, cb) ->
			echonest.request.getPlaylist d.playlistId, cb
		inv.rescue (err) ->
			resp.send 500
		inv.end null, (d, cb) ->
			resp.send d