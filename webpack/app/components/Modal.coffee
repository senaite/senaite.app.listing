import React from "react"

class Modal extends React.Component

  constructor: (props) ->
    super(props)

  render: ->
    <div id="#{@props.id}" className="#{@props.className}" tabindex="-1">
    </div>

export default Modal
