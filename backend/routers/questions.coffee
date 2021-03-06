express = require 'express'
router  = new express.Router
_       = require "lodash"
Error2  = require "error2"
async   = require "async"

approve = require "../middleware/approve-request"

Question    = require "../models/Question"
Participant = require "../models/Participant"
Answer      = require "../models/Answer"

# List of questions operations
router.route '/'

  .get (req, res) ->
    res.template = require '../templates/questions/list'

    # TODO: Enable when elasticsearch works again
    # if req.query.search
    #   return Question.search req.query.search, (error, result) ->
    #     if error then return req.next error
    #     res.serve questions: result.map (hit) -> hit.document


    { tags } = req.query
    query = if tags then {tags: $all: tags} else { }

    async.parallel
      questions   : (done) ->
        async.waterfall [
          (done) ->
            Question
              .find query
              .sort _id: -1
              .exec done
          (questions, done) ->
            async.each questions,
              (question, done) ->
                question.findAnswers (error, answers) ->
                  if error then return done error
                  question.answers = answers
                  do done
              -> done null, questions
        ], done
      unpublished : (done) -> Question.findUnpublished done

      (error, data) ->
        if error then return req.next error
        res.serve data

  .post approve('suggest a new question'), (req, res) ->
    { text, tags } = req.body
    if typeof tags is 'string' then tags = tags.split ','
    question = new Question { text, tags }
    question.saveDraft author: req.user.id, (error, draft)->
      if error then return req.next error
      res.redirect "/questions/#{question.id}/journal/#{draft.id}"

router.param 'id', (req, res, done, id) ->
  if not /^[0-9a-fA-F]{24}$/.test id then return done new Error2
    code: 422
    name: 'Unprocessable Entity'
    message: "#{id} is not a valid question identifier. Check your url."

  # TODO: consider async.parallel - this is just slighly better then pyramid of doom!
  async.waterfall [
    (done) -> Question.findByIdOrCreate id, done

    (question, done) -> question.findEntries action: 'draft', (error, journal) ->
      done error, question, journal

    (question, journal, done) ->
      if question.isNew and not journal.length then return done new Error2
        code   : 404
        name   : "Question not found"
        message: "There is no question at this address."

      Participant.populate journal,
        path: 'meta.author'
        (error, journal) ->
          done error, question, journal

    (question, journal, done) ->
      question.findStories (error, stories) ->
        done error, question, journal, stories

    (question, journal, stories, done) ->
      question.findAnswers (error, answers) ->
        done error, question, journal, stories, answers

    (question, journal, stories, answers, done) ->
      Answer.findUnpublished
        'data.question': question._id
        'data.author'  : req.user?._id
        (error, user_drafted) ->
          done error, question, journal, stories, answers, user_drafted[0]

  ], (error, question, journal, stories, answers, user_drafted) ->

      if error then return done error
      _.extend req, {
        question
        journal
        stories
        answers
        user_drafted
      }

      done null

router.param 'entry_id', (req, res, done, id) ->
  req.entry = _.find req.journal, (entry) -> entry.id is id
  if not req.entry then return done new Error2
    code   : 404
    name   : "Not Found"
    message: "Journal entry not found."
  do done

# Single question's operations
router.route '/:id'
  .get (req, res) ->
    res.template = require "../templates/questions/single"
    res.serve _.pick req, [
      'question'
      'journal'
      'stories'
      'answers'
      'unpublished'
      'user_drafted'
    ]
  .post approve('suggest a new question'), (req, res) -> # TODO: put?
    data = _.pick req.body, [
      'text'
      'tags'
    ]
    { question } = req
    question.set data
    question.saveDraft author: req.user.id, (error, draft) ->
      if error then return req.next error
      res.redirect "/questions/#{question.id}/journal/#{draft.id}"

  .delete approve('publish a question'), (req, res) ->
    req.question.removeDocument author: req.user.id, (error, entry) ->
      res.redirect 'back'

# Questions' operations
router.route '/:id/stories'
  .get (req, res) ->
    res.serve 'A list of stories related to question'

router.use '/:id/answers', require './answers'

# Journal operations
# TODO: own router?

router.route '/:id/journal'
  .get (req, res) ->
    res.serve 'Get a list of journal entries for this question'

router.route '/:id/journal/:entry_id'
  .get (req, res) ->
    res.template = require "../templates/questions/single"
    data = _.pick req, [
      'question'
      'journal'
      'entry'
    ]
    res.serve data

router.route '/:id/journal/:entry_id/apply'
  .post approve('publish a question'), (req, res) ->
    req.entry.apply author: req.user.id, (error, question) ->
      if error then return req.next error
      res.redirect "/questions/#{question.id}"

module.exports = router
