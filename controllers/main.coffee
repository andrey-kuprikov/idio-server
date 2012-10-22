utils = require './../utils'
config = require './../config'
request = require 'request'
mongoose = require 'mongoose'
invoke = require 'invoke'

user = require './../models/user'
session = require './../models/session'
echonest = require './../models/echonest'

lastfm = require './../models/lastfm'
playlist = require './../models/playlist'

db = mongoose.createConnection(config.mongohost, config.mongodatabase)

exports.setup = (app, config) ->
	app.post '/hello/', mainController.hello
	app.get '/hello/', mainController.hello

	app.post '/users/', mainController.addUser
	app.get '/users/', mainController.getUser
	app.delete '/users/:login', mainController.delUser

	app.post '/playlists/listens/', mainController.addListens

	user.initialize mongoose
	session.initialize mongoose

mainController =
	hello: (req, resp) ->
		console.log req.body

		resp.send 200

	addUser: (req, resp) ->
		userJson = req.body

		setListenedTracks = (user) ->
			lastfm.getTopTracks user.lastfm.login, (tracks) ->
				console.log(tracks)
				playlist.listen(user._id, tracks)
			#todo: facebook
			#tracks = _.union tracks, facebook.getTopTracks(user.facebook)

		User = db.model 'user'
		User.findOne {login: userJson.login}, (err, user) ->
			if err
				resp.send 500
				return
			if user
				resp.send 409
				return
			user = new User(userJson)
			user.save (err) ->
				if (err)
					console.log 'error while saving user to db'
					resp.send 500
					return

				inv = invoke (d, cb) ->
					echonest.request.createPlaylist user, cb

				inv.then (d, cb) ->
					Playlist = db.model 'playlist'
					playlist = new Playlist()
					playlist.save()
					user.playlistIds.push playlist._id
				inv.then (d, cb) ->
					setListenedTracks user, cb

				inv.rescue (err) ->
					console.log err
					resp.send 500
					return

				inv.end null, (d, cb) ->
					resp.set 'Location', '/users/' + user.login
					resp.send 201

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

		if (passwordHash)
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
			createSession user, (err, data) ->
				if (err)
					resp.send 500
					return
				resp.send 200, data

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
