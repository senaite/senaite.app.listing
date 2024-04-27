import React from "react"


class MultiChoice extends React.Component

  ###*
   * Multi-Choice Field for the Listing Table
   *
   * A multi choice field is identified by the column type "multichoice" in the
   * listing view, e.g.  `self.columns = {"Result": {"type": "multichoice"}, ... }`
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
    # Extract all checked items
    checked = ul.querySelectorAll("input[type='checkbox']:checked")
    # Extract the UID attribute
    uid = el.getAttribute("uid")
    # Extract the column_key attribute
    name = el.getAttribute("column_key") or el.name
    # Store the new values
    value = (input.value for input in checked)
    @setState
      value: value

    console.debug "MultiChoice::on_change: value=#{value}"

    # Call the *update* field handler
    if @props.update_editable_field
      @props.update_editable_field uid, name, value, @props.item

  ###
   * Converts the value to an array
  ###
  to_array: (value) ->
    if not value
      return []
    if Array.isArray(value)
      return value
    parsed = JSON.parse value
    if not Array.isArray(parsed)
      # This might happen when a default value is set, e.g. 0
      return [parsed]
    return parsed


  ###*
   * Checkboxes list builder. Generates a list of checkboxes made of the
   * options passed-in. The values are the ids of the options to be selected
   * @param values {array} list of selected ResultValues
   * @param options {array} list of option objects, e.g.:
   *                        {"ResultText": ..., "ResultValue": ..., "ResultDescription": ...}
  ###
  build_checkboxes: ->
    checkboxes = []

    # Convert the result to an array
    values = @to_array @state.value

    # filter out empties
    values = values.filter (value) -> value isnt ""

    # ensure safe comparison (strings)
    values = values.map (value) -> value.toString()

    for option in @props.options
      value = option.ResultValue
      title = option.ResultText
      description = option.ResultDescription
      selected = value.toString() in values
      checkboxes.push(
        <li key={value}>
          <input type="checkbox"
                 defaultChecked={selected}
                 uid={@props.uid}
                 name={@props.name}
                 value={value}
                 onChange={@props.onChange or @on_change}
                 column_key={@props.column_key}
                 title={description or @props.help or @props.title}
                 tabIndex={@props.tabIndex}
                 {...@props.attrs}/> {title}
        </li>)

    return checkboxes

  render: ->
    <div className={@props.field_css or "multichoice"}>
      {@props.before and <span className={@props.before_css or "before_field"} dangerouslySetInnerHTML={{__html: @props.before}}></span>}
      <ul className="list-unstyled">
        {@build_checkboxes()}
      </ul>
      {@props.after and <span className={@props.after_css or "after_field"} dangerouslySetInnerHTML={{__html: @props.after}}></span>}
    </div>


export default MultiChoice
