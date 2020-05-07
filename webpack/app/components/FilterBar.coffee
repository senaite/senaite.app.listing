import React from "react"
import Button from "./Button.coffee"


class FilterBar extends React.Component
  ###
   * The filter component provides workflow filter buttons
  ###

  constructor: (props) ->
    super(props)

    @on_filter_button_clicked = @on_filter_button_clicked.bind @

  on_filter_button_clicked: (event) ->
    ###
     * Event handler when a filter button was clicked
    ###

    # prevent form submission
    event.preventDefault()

    el = event.currentTarget
    id = el.id

    # call the parent event handler with the state id
    @props.on_filter_button_clicked id

  build_filter_buttons: ->
    ###
     * Build filter buttons from the listing `review_states` list
    ###
    buttons = []

    # the current active review state
    active_state = @props.review_state

    for key, value of @props.review_states

      # button CSS
      cls = "btn btn-outline-secondary btn-sm"

      if value.id == active_state
        cls += " active"

      buttons.push(
        <Button
          key={value.id}
          onClick={@on_filter_button_clicked}
          id={value.id}
          title={value.title}
          className={cls}/>
      )

    # omit filter buttons if there is only one
    if buttons.length == 1
      return []

    return buttons

  render: ->
    <div className={@props.className}>
      {@build_filter_buttons()}
    </div>


export default FilterBar
