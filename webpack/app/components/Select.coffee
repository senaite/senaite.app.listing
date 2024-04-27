import React from "react"


class Select extends React.Component

  ###*
   * Select Field for the Listing Table
   *
   * A select field is identified by the column type "choices" in the listing
   * view, e.g.  `self.columns = {"Result": {"type": "choices"}, ... }`
   *
  ###
  constructor: (props) ->
    super(props)
    # remember the initial value
    @state =
      value: props.defaultValue or ""

    # bind event handler to the current context
    @on_blur = @on_blur.bind @
    @on_change = @on_change.bind @

  ###*
   * componentDidUpdate(prevProps, prevState, snapshot)
   * This is invoked immediately after updating occurs.
   * This method is not called for the initial render.
  ###
  componentDidUpdate: (prevProps) ->
    if @props.defaultValue isnt prevProps.defaultValue
      @setState value: @props.defaultValue

  ###*
   * Event handler when the mouse left the select field
   * @param event {object} ReactJS event object
  ###
  on_blur: (event) ->
    el = event.currentTarget
    # Extract the UID attribute
    uid = el.getAttribute("uid")
    # Extract the column_key attribute
    name = el.getAttribute("column_key") or el.name
    # Extract the value of the numeric field
    value = el.value
    @setState value: value

    console.debug "Select::on_blur: value=#{value}"

    # Call the *save* field handler with the UID, name, value
    if @props.save_editable_field
      @props.save_editable_field uid, name, value, @props.item

  ###*
   * Event handler when the value changed of the select field
   * @param event {object} ReactJS event object
  ###
  on_change: (event) ->
    el = event.currentTarget
    # Extract the UID attribute
    uid = el.getAttribute("uid")
    # Extract the column_key attribute
    name = el.getAttribute("column_key") or el.name
    # Extract the value of the numeric field
    value = el.value

    # Only propagate for new values
    if value == @state.value
      return

    console.debug "Select::on_change: value=#{value}"

    # store the new value
    @setState value: value

    # Call the *update* field handler
    if @props.update_editable_field
      @props.update_editable_field uid, name, value, @props.item

  ###*
   * Select options builder
   * @param options {array} list of option objects, e.g.:
   *                        {"ResultText": ..., "ResultValue": ...}
  ###
  build_options: ->
    options = []

    for option in @props.options
      value = option.ResultValue
      title = option.ResultText
      description = option.ResultDescription
      options.push(
        <option key={value}
                title={description}
                value={value}>
          {title}
        </option>)

    return options

  render: ->
    <span className={@props.field_css or "form-group"}>
      {@props.before and <span className={@props.before_css or "before_field"} dangerouslySetInnerHTML={{__html: @props.before}}></span>}
      <select key={@props.name}
              uid={@props.uid}
              name={@props.name}
              value={@state.value}
              column_key={@props.column_key}
              title={@props.help or @props.title}
              disabled={@props.disabled}
              onBlur={@props.onBlur or @on_blur}
              onChange={@props.onChange or @on_change}
              required={@props.required}
              className={@props.className}
              tabIndex={@props.tabIndex}
              {...@props.attrs}>
        {@build_options()}
      </select>
      {@props.after and <span className={@props.after_css or "after_field"} dangerouslySetInnerHTML={{__html: @props.after}}></span>}
    </span>


export default Select
