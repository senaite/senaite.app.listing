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
    @state = @get_state_from_props(props)

    # bind event handler to the current context
    @on_blur = @on_blur.bind @
    @on_change = @on_change.bind @
    @on_other_change = @on_other_change.bind @
    @on_other_blur = @on_other_blur.bind @

  get_options: (props=@props) ->
    return props.options or []

  is_manual_entry_enabled: (value) ->
    return value is true

  is_other_option: (option={}) ->
    value = ("" + (option.ResultValue or "")).trim().toLowerCase()
    text = ("" + (option.ResultText or "")).trim().toLowerCase()
    return value is "other" or text is "other"

  is_manual_entry_value: (value, props=@props) ->
    options = @get_options(props)
    selected = "" + (value or "")
    for option in options
      opt_val = if option.ResultValue? then "" + option.ResultValue else ""
      manual = option.AllowManualEntry
      if opt_val == selected and (
        @is_manual_entry_enabled(manual) or @is_other_option(option)
      )
        return yes
    return no

  get_first_manual_entry_value: (props=@props) ->
    options = @get_options(props)
    for option in options
      manual = option.AllowManualEntry
      if @is_manual_entry_enabled(manual) or @is_other_option(option)
        return "" + (option.ResultValue or "")
    return ""

  is_predefined_value: (value, props=@props) ->
    options = @get_options(props)
    val = "" + (value or "")
    for option in options
      opt_val = if option.ResultValue? then "" + option.ResultValue else ""
      if opt_val == val
        return yes
    return no

  get_normalized_value: (state=@state) ->
    if @is_manual_entry_value(state.value)
      return state.other_value or ""
    return state.value

  get_state_from_props: (props=@props) ->
    value = props.defaultValue or ""

    if value and not @is_predefined_value(value, props)
      manual_value = @get_first_manual_entry_value(props)
      if manual_value
        return {
          value: manual_value
          other_value: value
        }

    return {
      value: value
      other_value: ""
    }

  ###*
   * componentDidUpdate(prevProps, prevState, snapshot)
   * This is invoked immediately after updating occurs.
   * This method is not called for the initial render.
  ###
  componentDidUpdate: (prevProps) ->
    if @props.defaultValue isnt prevProps.defaultValue
      @setState @get_state_from_props(@props)

  ###*
   * Event handler when the mouse left the select field
   * @param event {object} ReactJS event object
  ###
  on_blur: (event) ->
    el = event.currentTarget
    if @is_manual_entry_value(@state.value)
      return
    # Extract the UID attribute
    uid = el.getAttribute("uid")
    # Extract the column_key attribute
    name = el.getAttribute("column_key") or el.name
    # Extract the value of the numeric field
    value = @get_normalized_value()

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
    selected = el.value

    # Only propagate for new values
    if selected == @state.value
      return

    is_manual = @is_manual_entry_value(selected)
    other_value = if is_manual then @state.other_value else ""
    value = if is_manual then other_value else selected

    console.debug "Select::on_change: value=#{value}"

    @setState {
      value: selected
      other_value: other_value
    }

    if @props.update_editable_field
      @props.update_editable_field uid, name, value, @props.item

  on_other_change: (event) ->
    el = event.currentTarget
    uid = el.getAttribute("uid")
    name = el.getAttribute("column_key") or el.name
    value = el.value

    if value == @state.other_value
      return

    @setState other_value: value

    if @props.update_editable_field and @is_manual_entry_value(@state.value)
      @props.update_editable_field uid, name, value, @props.item

  on_other_blur: (event) ->
    el = event.currentTarget
    uid = el.getAttribute("uid")
    name = el.getAttribute("column_key") or el.name
    value = @state.other_value or ""

    console.debug "Select::on_other_blur: value=#{value}"

    if @props.save_editable_field and @is_manual_entry_value(@state.value)
      @props.save_editable_field uid, name, value, @props.item

  ###*
   * Select options builder
   * @param options {array} list of option objects, e.g.:
   *                        {"ResultText": ..., "ResultValue": ...}
  ###
  build_options: ->
    @props.options.map (option, index) =>
      value = option.ResultValue
      title = option.ResultText
      description = option.ResultDescription
      <option key={"#{@props.name}-#{value || index}"}
              title={description}
              value={value}>
        {title}
      </option>

  render: ->
    show_other = @is_manual_entry_value(@state.value)

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
      {show_other and
        <input type="text"
               uid={@props.uid}
               name={@props.name}
               value={@state.other_value}
               column_key={@props.column_key}
               disabled={@props.disabled}
               onBlur={@on_other_blur}
               onChange={@on_other_change}
               className={(@props.className or "form-control form-control-sm") + " mt-1 result-other-input"}
               tabIndex={@props.tabIndex}
               />
      }
      {@props.after and <span className={@props.after_css or "after_field"} dangerouslySetInnerHTML={{__html: @props.after}}></span>}
    </span>


export default Select
