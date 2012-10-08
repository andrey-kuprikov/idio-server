exports.initialize = (mongoose) ->
	structure =
		id: String
		login: String
		password: String
		email: String
		name: String
		session: String
		lastfm:
			login: String
	schema = new mongoose.Schema structure
	mongoose.model 'user', schema