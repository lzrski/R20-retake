# Index (/) route
express  = require 'express'

router = new express.Router

# List's of stories operations
router.route '/'
  .get (req, res) ->
    res.template = require '../templates/index'
    res.serve message: 'Hello there!'

# Load subrutes
router.use "/#{route}", require "./#{route}" for route in [
  'authenticate'
  'participants'
  'stories'
  'questions'
  # TODO:
  # 'answers'
]

module.exports = router
