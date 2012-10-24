exports.initialize = (mongoose) ->
	structure =
		login: String
		passwordHash: String
		email: String
		name: String
		createDate: {type: Date, default: Date.now}
		#we user forward linking because user model should know about all user playlists
		playlistIds: [mongoose.Schema.Types.ObjectId]
		lastfm:
			login: String
	schema = new mongoose.Schema structure
	mongoose.model 'user', schema