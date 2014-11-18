router = require('express').Router()
Busboy = require('busboy')
mkdirp = require('mkdirp')
fse    = require('fs-extra')
fs     = require('fs')
Q      = require('q')

validator = require('../validators').client
Client    = require('../models/client')
mailer    = require('../mailer')
utils     = require('../utils')

uploadPath = (process.env.CLOUD_DIR || './public/uploads/clients/photos')

module.exports = (app) ->
  app.use '/clients', router

router
  .get '/', (req, res, next) ->

    Client.find().exec()
      .then (clients) ->
        res.send(clients)
      .then null, next

  .post '/', validator, (req, res, next) ->

    Client.create(req.body)
      .then (newClient) ->
        res.send(newClient)
      .then null, next

  .get '/:id', (req, res, err) ->

    Client.findById(req.params.id).exec()
      .then (client) ->
        if !client then utils.notFound(res)
        else if req.query.token != client.token then utils.unauthorized(res)
        else res.send(client)
      .then null, utils.mongooseError(res, next)


  .delete '/:id', (req, res, next) ->

    Client.findById(req.params.id).exec()
      .then (client) ->
        return utils.notFound(res)     if !client
        return utils.unauthorized(res) if client.token != req.query.token

        Client.findByIdAndRemove(req.params.id).exec()
          .then (removedClient) ->
            return utils.notFound(res) if !removedClient
            clientFolderPath = "#{uploadPath}/#{removedClient.id}"
            fse.remove clientFolderPath, (err) ->
              if err then next(err)
              else res.send(removedClient)

          .then null, utils.mongooseError(res, next)
      .then null, next

  .put '/:id/photos', (req, res, next) ->

    clientId = req.params.id

    Client.findById(clientId).exec()
      .then (client) ->
        return utils.notFound(res)     if !client
        return utils.unauthorized(res) if client.token != req.query.token

        busboy = new Busboy(headers: req.headers)
        folderPath = "#{uploadPath}/#{clientId}"

        busboy.on 'file', (fieldName, file, fileName, encoding, mimeType) ->

          Q.nfapply(mkdirp, [folderPath])
            .then (__) ->
              filePath = "#{folderPath}/#{fileName}"
              writeStream = fs.createWriteStream(filePath)
              file.pipe(writeStream)
            .then null, next

          file.on 'end', ->

            client.update($addToSet: {files: fileName}).exec().then null, next

        busboy.on 'finish', ->
          Client.findById(clientId).exec()
            .then (newClient) ->
              res.send(newClient)

              mailOptions =
                from: 'Photo App <noreply@photo-app.com>'
                to: 'ahimta@gmail.com'
                subject: 'Your profile was created successfully'
                text: 'https://pa.mod.bz/clients/'
                attachments: client.files.map (fileName, index) ->
                  {path: "#{folderPath}/#{fileName}"}

              mailer.send mailOptions, (err, info) ->
                if err then console.log(err)
                else console.log(info)
            .then null, next

        req.pipe(busboy)

      .then null, utils.mongooseError(res, next)