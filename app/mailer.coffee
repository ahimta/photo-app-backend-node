smtpTransport = require('nodemailer-smtp-transport')
nodemailer    = require('nodemailer')

smtpTransporter = smtpTransport
  host: 'smtp.mandrillapp.com'
  port: '587'
  auth:
    user: 'ahimta@gmail.com'
    pass: 'Nr2ygL5cxO-6BqF1r9q_pw'

transporter = nodemailer.createTransport(smtpTransporter)

module.exports.send = (options, callback) ->
  transporter.sendMail(options, callback)
