exports.initialize = (mongoose) ->
	structure =
		login: String
	schema = new mongoose.Schema structure
	mongoose.model 'session', schema