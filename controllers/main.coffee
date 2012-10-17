utils = require './../utils'
config = require './../config'
request = require 'request'
mongoose = require 'mongoose'

user = require './../models/user'
session = require './../models/session'

lastfm = require './../models/lastfm'
playlist = require './../models/playlist'

db = mongoose.createConnection(config.mongohost, config.mongodatabase)

exports.setup = (app, config) ->
	app.get '/hello/:name', mainController.hello

	app.post '/users/', mainController.addUser
	app.get '/users/:login', mainController.getUser
	app.delete '/users/:login', mainController.delUser

	app.post '/session/', mainController.postSession

	app.post '/playlists/listens/', mainController.addListens

	user.initialize mongoose
	session.initialize mongoose

mainController =
	hello: (req, resp) ->
		name = utils.getParam req.params.name

		data=
			name: name
			msg: 'hello ' + name

		resp.json data

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
			user.save()

			setListenedTracks(user)

			resp.set('Location', '/users/' + user.login);
			resp.send(201)

	getUser: (req, resp) ->
		login = utils.getParam req.params.login

		User = db.model('user')

		User.findOne {login: login}, (err, user) ->
			if err
				resp.send 500
				return
			if !user
				resp.send(404)
				return
			resp.send(200, user.toObject())

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

	postSession: (req, resp) ->
		login = req.body.login
		password = req.body.password
		console.log login
		console.log password

		User = db.model 'user'
		Session = db.model 'session'

		User.findOne {login: login, password: password}, (err, user) ->
			if err
				resp.send 500, err
				return
			if !user
				resp.send(404)
				return

			session = new Session {userId: user._id}
			session.save()
			resp.send(200, session.toObject())
