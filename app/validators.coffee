form  = require('express-form').configure(dataSources: ['body'], flashErrors: false)
field = form.field

baseValidator = (req, res, next) ->
  if req.form.isValid then next()
  else res.status(400).send(req.form.getErrors())

module.exports.client = [

  form(
    field('email').required().notEmpty().isEmail(),
    field('name').required().notEmpty()
  ),
  baseValidator
]