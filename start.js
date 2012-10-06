require('coffee-script');

var config = require('./config'),
	app = require('./init').initialize();

app.listen(config.server.workerPort);
console.log("Server listening on port %d in %s mode", config.server.workerPort, app.settings.env);