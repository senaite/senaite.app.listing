import React from "react"


class MultiSelect extends React.Component

  ###*
   * MultiSelect Field for the Listing Table
   *
   * A multi select field is identified by the column type "multiselect" in the listing
   * view, e.g.  `self.columns = {"Result": {"type": "multiselect"}, ... }`
   *
  ###
  constructor: (props) ->
    super(props)

    # remember the initial value
    @state =
      value: props.defaultValue

    # bind event handler to the current context
    @on_change = @on_change.bind @

  ###*
   * Event handler when the value changed of the select field
   * @param event {object} ReactJS event object
  ###
  on_change: (event) ->
    el = event.currentTarget
    # Get the parent list wrapper
    ul = el.parentNode.parentNode
    # Extract all selected items
    checked = ul.querySelectorAll("select")
    # Extract the UID attribute
    uid = el.getAttribute("uid")
    # Extract the column_key attribute
    name = el.getAttribute("column_key") or el.name
    # Prepare a list of UIDs
    value = (input.value for input in checked)

    # store the new value
    @setState
      value: value

    console.debug "MultiSelect::on_change: name=#{name} value=#{value}"

    # Call the *update* field handler
    if @props.update_editable_field
      @props.update_editable_field uid, name, value, @props.item

  ###*
   * Select options builder
   * @param selected_value the option to be selected
   * @param options {array} list of option objects, e.g.:
   *                        {"ResultText": ..., "ResultValue": ...}
  ###
  build_options: ->
    options = []

    # Possible options of the selection list
    props_options = @props.options or []

    # Add an empty option to be displayed by default, but only when no empty
    # option does not exist yet
    empties = props_options.filter (option) -> option.ResultValue ==  ""
    if empties.length == 0
      props_options.push(
        {
          ResultValue: ""
          ResultText: ""
        }
      )

    # Sort the options alphabetically
    sorted_options = props_options.sort (a, b) ->
      text_a = a.ResultText
      text_b = b.ResultText
      if text_a > text_b then return 1
      if text_a < text_b then return -1
      return 0

    # Add the options to the selection list
    for option in sorted_options
      value = option.ResultValue
      title = option.ResultText
      options.push(
        <option value={value}>{title}</option>
      )

    return options

  ###
   * Converts the value to an array
  ###
  to_array: (value) ->
    if not value
      return []
    if Array.isArray(value)
      return value
    value = "#{value}"
    value = value.split("u'").join("'")
    value = value.split("'").join("")
    return JSON.parse value

  ###
   * Selectors list builder. Generates a list with as many select elements as
   * values passed-in. Each selector contains all the options for selection,
   * with the option that matches with the value selected
   * @param values {array} list of selected ResultValues
   * @param options {array} list of option objects, e.g.:
   *                        {"ResultText": ..., "ResultValue": ...}
  ###
  build_selectors: ->
    # Convert the result to an array
    values = @to_array @state.value

    # Bail out empties
    values = values.filter (value) -> value isnt ""

    # Add an empty selector at the end
    values.push("")

    # Build the selectors
    selectors = []
    for selected_value in values
      console.log "MultiSelect::build_selectors:value='#{selected_value}'"
      selectors.push(
        <li key={selected_value}>
          <select value={selected_value}
                  uid={@props.uid}
                  name={@props.name}
                  onChange={@props.onChange or @on_change}
                  onBlur={@props.onBlur or @on_blur}
                  column_key={@props.column_key}
                  className={@props.className}
                  {...@props.attrs}>
            {@build_options()}
          </select>
        </li>
      )

    return selectors

  render: ->
    <div className="multiselect">
      {@props.before and <span className="before_field" dangerouslySetInnerHTML={{__html: @props.before}}></span>}
      <ul className="list-unstyled" tabIndex={@props.tabIndex}>
        {@build_selectors()}
      </ul>
      {@props.after and <span className="after_field" dangerouslySetInnerHTML={{__html: @props.after}}></span>}
    </div>


export default MultiSelect
