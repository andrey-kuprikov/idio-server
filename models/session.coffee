exports.initialize = (mongoose) ->
	structure =
		_id: String
		userId: String
	schema = new mongoose.Schema structure
	mongoose.model 'session', schema