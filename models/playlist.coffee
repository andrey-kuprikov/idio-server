exports.initialize = (mongoose) ->
	trackStructure =
		artistName: String
		albumName: String
		trackName: String
		img: String
		duration: Number

	trackSchema = new mongoose.Schema trackStructure

	playlistStructure =
		createDate: {type: Date, default: Date.now}
		tracks: [trackSchema]
	playlistSchema = new mongoose.Schema playlistStructure
	
	mongoose.model 'track', playlistSchema

exports.listen = (id, tracks) ->
	console.log('function playlist.listen is not defined')