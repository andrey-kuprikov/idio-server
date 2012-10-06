exports.initialize = (mongoose) ->
	structure =
		login: String
		name: String
	schema = new mongoose.Schema structure
	mongoose.model 'user', schema