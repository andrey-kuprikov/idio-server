exports.initialize = (mongoose) ->
	structure =
		#we user backward linking because user model don't need to know about all opened sessions
		userId: String
		createDate: {type: Date, default: Date.now}
	schema = new mongoose.Schema structure
	mongoose.model 'session', schema