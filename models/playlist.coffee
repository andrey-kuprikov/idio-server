exports.initialize = (mongoose) ->
	trackStructure =
		artistName: String
		albumName: String
		trackName: String
		img: String
		duration: Number

	trackSchema = new mongoose.Schema trackStructure

	playlistStructure =
		echonestId: String
		createDate: {type: Date, default: Date.now}
		tracks: [trackSchema]
	playlistSchema = new mongoose.Schema playlistStructure

	playlistSchema.methods.listen =  (tracks, cb) ->
		console.log('function playlist.listen is not defined')
		cb null, null

	mongoose.model 'playlist', playlistSchema