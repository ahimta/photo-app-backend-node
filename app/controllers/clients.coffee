router = require('express').Router()
Busboy = require('busboy')
mkdirp = require('mkdirp')
fse    = require('fs-extra')
fs     = require('fs')
gm     = require('gm')
_      = require('lodash')
Q      = require('q')

serializer = require('../serializers').client
validator  = require('../validators').client
Client     = require('../models/client')
mailer     = require('../mailer')
utils      = require('../utils')

uploadsPath = (process.env.CLOUD_DIR || './public/uploads')
photosPath = (uploadsPath + '/clients/photos')

module.exports = (app) ->
  app.use '/api/v0/clients', router

router
  .get '/', (req, res, next) ->

    Client.find().exec()
      .then (clients) ->
        serializedClients = clients.map(serializer)
        res.send(serializedClients)
      .then null, next

  .post '/', validator, (req, res, next) ->

    Client.create(req.body)
      .then (newClient) ->
        serializedClient = _.merge(serializer(newClient), token: newClient.token)
        res.send(serializedClient)
      .then null, next

  .get '/:id', (req, res, err) ->

    Client.findById(req.params.id).exec()
      .then (client) ->
        if !client then utils.notFound(res)
        else if req.query.token != client.token then utils.unauthorized(res)
        else res.send(serializer(client))
      .then null, utils.mongooseError(res, next)


  .delete '/:id', (req, res, next) ->

    Client.findById(req.params.id).exec()
      .then (client) ->
        return utils.notFound(res)     if !client
        return utils.unauthorized(res) if client.token != req.query.token

        Client.findByIdAndRemove(req.params.id).exec()
          .then (removedClient) ->
            return utils.notFound(res) if !removedClient
            clientFolderPath = "#{photosPath}/#{removedClient.id}"
            fse.remove clientFolderPath, (err) ->
              if err then next(err)
              else res.send(serializer(removedClient))

          .then null, utils.mongooseError(res, next)
      .then null, next

  .get '/:id/photos/:fileName', (req, res, next) ->

    Client.findById(req.params.id).exec()
      .then (client) ->
        return utils.notFound(res) if ! client
        filePath = "#{photosPath}/#{client.id}/#{req.params.fileName}"
        res.download(filePath)
      .then null, utils.mongooseError(res, next)

  .put '/:id/photos', (req, res, next) ->

    clientId = req.params.id

    Client.findById(clientId).exec()
      .then (client) ->
        return utils.notFound(res)     if !client
        return utils.unauthorized(res) if client.token != req.query.token

        busboy = new Busboy
          headers: req.headers
          limits:
            fileSize: 5 * 1024 * 1024

        folderPath = "#{photosPath}/#{clientId}"

        busboy.on 'file', (fieldName, file, fileName, encoding, mimeType) ->

          Q.nfapply(mkdirp, [folderPath])
            .then (__) ->
              filePath    = "#{folderPath}/#{fileName}"
              writeStream = fs.createWriteStream(filePath)

              file.pipe(writeStream)
            .then null, next

          file.on 'end', ->

            client.update($addToSet: {files: fileName}).exec().then null, next

        busboy.on 'finish', ->
          Client.findById(clientId).exec()
            .then (newClient) ->
              res.send(serializer(newClient))

              mailOptions =
                from: 'Photo App <noreply@photo-app.com>'
                to: newClient.email
                subject: 'Your profile was created successfully'
                text: "
                    With name '#{newClient.name}' and email '#{newClient.email}'.
                    You can delete your profile in https://pa.mod.bz/#/clients?client_id=#{newClient.id}&token=#{newClient.token}
                    In addition you can see other users' profiles in https://pa.mod.bz/#/clients
                  "
                html: "
                    With name <b>#{newClient.name}</b> and email <b>#{newClient.email}</b>.
                    You can delete your profile <a href='https://pa.mod.bz/#/clients?client_id=#{newClient.id}&token=#{newClient.token}'>here</a>
                    In addition you can see other users' profiles <a href='https://pa.mod.bz/#/clients'>here</a>
                  "
                attachments: newClient.files.map (fileName, index) ->
                  {path: "#{folderPath}/#{fileName}"}

              mailer.send mailOptions, (err, info) ->
                if err then console.log(err)
                else console.log(info)
            .then null, next

        req.pipe(busboy)

      .then null, utils.mongooseError(res, next)