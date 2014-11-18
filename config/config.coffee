path     = require 'path'
rootPath = path.normalize __dirname + '/..'
env      = process.env.NODE_ENV || 'development'

config =
  development:
    root: rootPath
    app:
      name: 'backend'
    port: 3000
    db: 'mongodb://localhost/backend-development'
    

  test:
    root: rootPath
    app:
      name: 'backend'
    port: 3001
    db: 'mongodb://localhost/backend-test'
    

  production:
    root: rootPath
    app:
      name: 'backend'
    port: 3000
    db: 'mongodb://localhost/backend-production'
    

module.exports = config[env]
