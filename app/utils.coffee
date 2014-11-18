module.exports.mongooseError = (res, next) ->
  (err) ->
    if err.name == 'CastError' then module.exports.notFound(res)
    else next(err)

module.exports.unauthorized = (res) ->
  res.status(401).send(status: 401, message: 'Unauthorized')

module.exports.notFound = (res) ->
  res.status(404).send(status: 404, message: 'Not Found')