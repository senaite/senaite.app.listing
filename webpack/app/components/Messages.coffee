import React from "react"


class Messages extends React.Component

  constructor: (props) ->
    super(props)

    # Bind eventhandlers to local context
    @on_dismiss_message = @on_dismiss_message.bind @

  on_dismiss_message: (event) ->
    event.preventDefault()
    index = event.currentTarget.getAttribute "index"
    # call the parent event handler
    if @props.on_dismiss_message
      @props.on_dismiss_message parseInt(index)

  render_messages: ->
    messages = []
    me = this
    @props.messages.map (message, index) ->
      messages.push(
        <div key={index} className="alert alert-#{message.level or 'info'}">
          <button onClick={me.on_dismiss_message} index={index} type="button" className="close" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
          {message.title and <h4 className="alert-heading">{message.title}</h4>}
          {message.text and <div>{message.text}</div>}
          {message.traceback and <pre>{message.traceback}</pre>}
        </div>)
    return messages

  render: ->
    if not @props.messages
      return null
    <div id={@props.id} className={@props.className}>
      {@render_messages()}
    </div>

export default Messages
