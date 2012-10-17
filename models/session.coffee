exports.initialize = (mongoose) ->
	structure =
		userId: String
	schema = new mongoose.Schema structure
	mongoose.model 'session', schema