View      = require "teacup-view"
moment    = require "moment"

layout    = require "../layouts/default"

module.exports = new View (data) ->

  data.subtitle = @cede => @translate "Legal questions matching your query"

  {
    query
    questions
    unpublished
    user
    csrf
  } = data

  layout data, =>
    @searchForm { query, action: '/search' }

    do @hr

    if questions.length then @div class: "row", =>
      for question in questions
        @div class: "col-sm-12", =>
          @div class: "panel panel-default search-result", =>
            @div class: "panel-body", =>
              @a
                href: "/questions/#{question._id}"
                class: "lead"
                => @markdown question.text

              if question.answers?.length
                @ul class: "list-inline small", =>
                  @strong => @translate "%d answers by:",
                    question.answers.length
                  for answer in question.answers
                    @li => @a href: "/questions/#{question._id}/##{answer._id}", answer.author?.name or @cede => @translate "unknown author"

              else @strong => @translate "No answers yet."

    else @div class: "alert alert-info", => @translate "No matching questions found."

    @div class: "well", =>
      @p "Would you like to share your story, so we can extract questions from it and try to provide answers?"

      if user?.can 'tell a story'
        @button
          class : 'btn btn-primary btn-lg'
          data  :
            toggle  : "modal"
            target  : "#story-new-dialog"
            shortcut: "n"
          =>
            @i class: "fa fa-fw fa-comment"
            @text "Share a story"

        @modal
          title : @cede => @translate "New story"
          id    : "story-new-dialog"
          =>
            @p => @translate "Please tell us your story."
            @storyForm
              method  : "POST"
              action  : "/stories/"
              text    : query.search
              csrf    : csrf
      else
        @button
          class : "btn btn-primary btn-lg browserid login"
          =>
            @i class: "fa fa-fw fa-check-circle"
            @text "Log in to share a story"
