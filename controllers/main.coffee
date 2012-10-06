utils = require './../utils'
config = require './../config'
request = require 'request'
mongoose = require 'mongoose'
user = require './../models/user'

db = mongoose.createConnection(config.mongohost, config.mongodatabase)

exports.setup = (app, config) ->
	app.get '/hello/:name', mainController.hello

	app.post '/users/', mainController.addUser
	app.get '/users/:login', mainController.getUser
	app.delete '/users/:login', mainController.delUser

	user.initialize mongoose

mainController =
	hello: (req, resp) ->
		name = utils.getParam req.params.name

		data=
			name: name
			msg: 'hello ' + name

		resp.json data

	addUser: (req, resp) ->
		userJson = req.body

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