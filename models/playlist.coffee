exports.initialize = (mongoose) ->
	structure =
		_id: String
		userId: String
		tracks: Array
	schema = new mongoose.Schema structure
	mongoose.model 'track', schema

exports.listen = (id, tracks) ->
	console.log('function playlist.listen is not defined')