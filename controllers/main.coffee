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
	app.delete '/users/:login', mainController.delUser

	app.post '/playlists/listens/', mainController.addListens

	user = require './../models/user'
	user.initialize mongoose

	session = require './../models/session'
	session.initialize mongoose

	playlist = require './../models/playlist'
	playlist.initialize mongoose

mainController =
	hello: (req, resp) ->
		console.log req.body

		resp.send 200

	addUser: (req, resp) ->
		userJson = req.body

		setListenedTracks = (user, playlist, cb) ->
			console.log 'ffg'
			lastfm.getTopTracks user.lastfm.login, (err, data) ->
				console.log data
				if err
					cb err, data
				else
					playlist.listen data, cb
			#todo: facebook
			#tracks = _.union tracks, facebook.getTopTracks(user.facebook)


		inv = invoke (d, cb) ->
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
					cb null, { user: user, echonest: data }

		inv.then (data, cb) ->
			console.log 'fff'
			Playlist = db.model 'playlist'
			playlist = new Playlist { echonestId: data.echonest.id }
			playlist.save (err) ->
				if (err)
					cb err, 500
					return
				data.user.playlistIds.push playlist._id
				data.user.save (err) ->
					if (err)
						cb err, 500
						return
					cb null, { user: data.user, playlist: playlist }
					console.log 'fff1'

		inv.then (data, cb) ->
			setListenedTracks data.user, data.playlist, (err, d) ->
				cb null, data
			console.log 'fff2'

		inv.rescue (err) ->
			console.log err
			resp.send 500
			return

		inv.end null, (d, cb) ->
			console.log 'fff3'
			resp.set 'Location', '/users/' + d.user.login
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
			
				user = user.toObject()
				user.sessionId = session._id
				console.log 'response:'
				console.log user
				cb null, user

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
			filter.password=passwordHash

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
					resp.send 200, data
			else
				resp.send 200, user

	delUser: (req, resp) ->
		login = utils.getParam req.params.login

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
		tracks = req.body
		User = db.model 'user'
		console.log('get user method undeined')
		user = User.findOne()
		playlist.listen(user._id, tracks)
