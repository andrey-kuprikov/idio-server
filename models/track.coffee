exports.initialize = (mongoose) ->
	structure =
		artistName: String
		albumName: String
		trackName: String
		img: String
		duration: Number
	schema = new mongoose.Schema structure
	mongoose.model 'track', schema