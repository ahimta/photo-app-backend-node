_ = require('lodash')

baseSerializer = (mongoRecord) ->
  object = if mongoRecord.toObject then mongoRecord.toObject() else mongoRecord
  serialzedRecord    = _.omit(_.clone(object), '_id', '__v')
  serialzedRecord.id = mongoRecord._id.toString() if mongoRecord._id
  serialzedRecord

clientSerializer = (client) ->
  _.omit(_.clone(client), 'token')

module.exports =
  client: _.compose(clientSerializer, baseSerializer)