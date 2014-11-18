randomBytes = require('crypto').randomBytes
mongoose    = require('mongoose')
Q           = require('q')

schema = new mongoose.Schema
  email:
    required: true
    type: String
    trim: true
  name:
    required: true
    type: String
    trim: true
  files:
    type: [String]
    default: []
  token:
    required: true
    type: String

schema.pre 'validate', true, (next, done) ->
  next()

  Q.nfapply(randomBytes, [32]).then (buffer) =>
    @token = buffer.toString('hex')
    done()

module.exports = mongoose.model('Client', schema)