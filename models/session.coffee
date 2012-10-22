exports.initialize = (mongoose) ->
	structure =
		sessionId: String
		userId: String
	schema = new mongoose.Schema structure
	mongoose.model 'session', schema