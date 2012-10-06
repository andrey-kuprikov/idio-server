
express = require 'express'
config = require './config'
fs = require 'fs'

serving = true

exports.initialize = (switchSockets) ->

	app = express()

	# конфиги
	app.configure ->
		app.use express.bodyParser()
		app.use express.cookieParser()
		app.use express.methodOverride()

	logFile = fs.createWriteStream './logs/access.log', {flags: 'a'}
	app.use express.logger { stream: logFile }

	app.configure 'development', ->
		app.use express.errorHandler { dumpExceptions: true, showStack: true }

	app.configure 'production', ->
		app.use express.errorHandler()

	app.get '/*', checkServingController

	serving = true
	app.on 'close', -> serving = false

	checkServingController = (req, resp, next) ->
		if !serving
			resp.writeHead 200, { 'connection': 'close' }
			resp.end()
		else
			next()


	[
		'main'
	].map (controllerName) ->
		controller = require './controllers/' + controllerName
		controller.setup app, config

	app

