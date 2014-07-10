# do require('source-map-support').install

# Initialization and config
console.log 'Charging R20...'

express  = require 'express'
mongoose = require 'mongoose'
config   = require 'config-object'

app     = new express
config.load [
  '../defaults.cson'
  '../package.json'
  '../config.cson'
]

# Configure templates
require('teacup-view').load_components __dirname + '/templates/components'

# Load middleware
app.use require('body-parser').json()
app.use require './middleware/log-request'
express.response.serve = require './middleware/serve-response'

# Load routers
app.use '/', require './routers'

# Connect to data store
mongoose.connect Array(config.mongo.url).join ','

# Fire!
app.listen config.port
console.log "Boom! There is something going on at #{config.scheme}://#{config.host}:#{config.port}"