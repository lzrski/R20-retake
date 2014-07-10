express = require 'express'

router = new express.Router

Story  = require "../models/Story"

# List's of stories operations
router.route '/'
  .get (req, res) ->
    Story.find (error, stories) ->
      if error then res.emit error
      res.serve stories
  .post (req, res) ->
    res.serve 'A new story'

# Single story's operations
router.route '/:story_id'
  .get (req, res) ->
    res.serve 'A single story'
  .put (req, res) ->
    res.serve 'Store a new draft for a story'
  .delete (req, res) ->
    res.serve 'Remove a story, but leave jou rnal'

# Questions' operations
router.route '/:story_id/questions'
  .get (req, res) ->
    res.serve 'A list of questions related to story'
  .post (req, res) ->
    res.serve 'Create a story-question link'

router.route '/:story_id/questions/:question_id'
  .delete (req, res) ->
    res.serve 'Remove a story-question link'

# Journal operations
router.route '/:story_id/apply'
  .post (req, res) ->
    res.serve 'Apply a draft or another a journal operation'

router.route '/:story_id/journal'
  .get (req, res) ->
    res.serve 'Get a list of journal entries for this story'

router.route '/:story_id/journal/:entry_id'
  .get (req, res) ->
    res.serve 'Single journal entry. Can be a draft with apply form.'

module.exports = router
