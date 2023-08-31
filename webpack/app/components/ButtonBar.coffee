import React from "react"

import Button from "./Button.coffee"


class ButtonBar extends React.Component

  constructor: (props) ->
    super(props)

    # Bind eventhandlers to local context
    @on_ajax_save_button_click = @on_ajax_save_button_click.bind @
    @on_transition_button_click = @on_transition_button_click.bind @

    # default "confirm first" transitions
    @confirm_transitions = [
      "cancel"
      "deactivate"
      "invalidate"
      "reject"
      "remove"
      "retract"
      "unassign"
      "retest"
      "reinstate"
    ]

    @css_mapping =
      # default buttons
      "reassign": "btn-secondary"
      "duplicate": "btn-secondary"
      "close": "btn-secondary"
      # blue buttons
      "assign": "btn-secondary"
      "receive": "btn-primary"
      "open": "btn-primary"
      "verify": "btn-primary"
      "retest": "btn-primary"
      # green buttons
      "activate": "btn-success"
      "prepublish": "btn-success"
      "publish": "btn-success"
      "republish": "btn-success"
      "submit": "btn-success"
      # orange buttons
      "unassign": "btn-warning"
      # red buttons
      "cancel": "btn-danger"
      "deactivate": "btn-danger"
      "invalidate": "btn-danger"
      "reject": "btn-danger"
      "retract": "btn-danger"
      "remove": "btn-danger"

  componentDidUpdate: ->
    # N.B. This needs jQuery.js and bootstrap.js injected from the outer scope
    #      -> see webpack.config.js externals
    #
    # Not sure if hooking this event handler in `componentDidUpdate` always
    # intercepts correctly *before* the bound `onClick` event handler fires.
    #
    # http://bootstrap-confirmation.js.org/
    $("[data-toggle=confirmation]").confirmation
      rootSelector: "[data-toggle=confirmation]"
      btnOkLabel: _t("Yes")
      btnOkClass: "btn btn-outline-primary"
      btnOkIconClass: "fas fa-check-circle mr-1"
      btnCancelLabel: _t("No")
      btnCancelClass: "btn btn-outline-secondary"
      btnCancelIconClass: "fas fa-circle mr-1"
      container: "body"
      singleton: yes

  get_button_css: (id, transition={}) ->
    # calculate the button CSS
    cls = "btn btn-sm mr-1 mb-1"

    # append additional button styles
    additional_cls = @css_mapping[id]
    transition_cls = transition.css_class
    if additional_cls
      cls += " #{additional_cls}"
    else if transition_cls?
      cls += " #{transition_cls}"
    else
      cls += " btn-outline-secondary"

    return cls

  on_ajax_save_button_click: (event) ->
    # prevent form submit, because we want to handle that explicitly
    event.preventDefault()

    # call the parent event handler to save
    if @props.on_ajax_save_button_click
      @props.on_ajax_save_button_click()

  on_transition_button_click: (event) ->
    # prevent form submit, because we want to handle that explicitly
    event.preventDefault()

    # extract the action ID
    el = event.currentTarget

    # extract the transition action and the url of the button
    action = el.getAttribute "id"
    url = el.getAttribute "url"

    # call the parent event handler to perform the transition
    if @props.on_transition_button_click
      @props.on_transition_button_click action, url

  build_buttons: ->
    buttons = []

    # Add a clear button if the select column is rendered
    if @props.show_select_column
      if @props.transitions.length > 0
        buttons.push(
          <button
            key="clear"
            className="btn btn-outline-secondary btn-sm mb-1 mr-1"
            title={_t("Clear selection")}
            onClick={@on_transition_button_click}
            id="clear_selection">
            <i className="fas fa-circle-notch"></i>
          </button>
          )

    # Add an Ajax save button
    if @props.show_ajax_save
      buttons.push(
        <button
          key="ajax-save"
          className="btn btn-primary btn-sm mb-1 mr-1"
          onClick={@on_ajax_save_button_click}
          title={@props.ajax_save_button_title}
          id="ajax_save_selection">
          {@props.ajax_save_button_title} <i className="fas fa-save"></i>
        </button>
        )

    # build the transition buttons
    for transition in @props.transitions
      id = transition.id
      url = transition.url
      title = _t(transition.title)
      help = _t(transition.help)
      cls = @get_button_css(id, transition)
      btn_id = "#{id}_transition"

      # append custom css class
      if transition.css_class
        cls += " #{transition.css_class}"

      # each review_state item may also define a list of confirm transitions
      review_state_confirm_transitions = @props.review_state.confirm_transitions or []

      # Add bootstrap-confirmation data toggle
      # http://bootstrap-confirmation.js.org/#options
      attrs = transition.attrs or {}
      if id in @confirm_transitions or id in review_state_confirm_transitions
        attrs["data-toggle"] = "confirmation"
        attrs["data-title"] = "#{title}?"

        confirm_messages = @props.review_state.confirm_messages or {}
        confirm_message = _t(confirm_messages[id])
        if confirm_message
          attrs["data-content"] = "#{confirm_message}"

      buttons.push(
        <Button
          key={transition.id}
          id={btn_id}
          title={title}
          help={help}
          url={url}
          className={cls}
          badge={@props.selected_uids.length}
          onClick={@on_transition_button_click}
          disabled={@props.lock_buttons}
          attrs={attrs}/>
      )

    return buttons

  render: ->
    if @props.selected_uids.length == 0
      return null

    <div className="#{@props.className}">
      {@build_buttons()}
    </div>


export default ButtonBar
