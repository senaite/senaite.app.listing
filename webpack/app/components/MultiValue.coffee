import React from "react"


class MultiValue extends React.Component

  ###*
   * MultiValue Field for the Listing Table
   *
   * A multi value field is identified by the column type "multivalue" in the
   * listing view, e.g.  `self.columns = {"Result": {"type": "multivalue"}, ... }`
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
   * Event handler when the value changed of the field
   * @param event {object} ReactJS event object
  ###
  on_change: (event) ->
    el = event.currentTarget
    # Get the parent list wrapper
    ul = el.parentNode.parentNode
    # Extract all input elements that store values
    inputs = ul.querySelectorAll("input")
    # Extract the UID attribute
    uid = el.getAttribute("uid")
    # Extract the column_key attribute
    name = el.getAttribute("column_key") or el.name
    # The value to store is a list of values
    values = (input.value.trim() for input in inputs)
    # Filter out empty values
    values = values.filter (value) -> value isnt ""

    # store the new value
    @setState
      value: values

    console.debug "MultiValue::on_change:name=#{name} value=#{values}"

    # Call the *update* field handler
    if @props.update_editable_field
      @props.update_editable_field uid, name, values, @props.item

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

  ###
   * Inputs list builder. Generates a list with as many inputs as values set
  ###
  build_inputs: ->
    # Convert the result to an array
    values = @to_array @state.value

    # filter out empties
    values = values.filter (value) -> value isnt ""

    # Add an empty value at the end
    values.push("")

    # Build the elements
    inputs = []
    for value in values
      console.log "MultiValue::build_elements:value='#{value}'"
      inputs.push(
        <li>
          <input type="text"
                 size={@props.size or 5}
                 value={value}
                 uid={@props.uid}
                 name={@props.name}
                 onChange={@props.onChange or @on_change}
                 column_key={@props.column_key}
                 className={@props.className}
                 {...@props.attrs} />
        </li>
      )

    return inputs

  render: ->
    <div className="multivalue">
      {@props.before and <span className="before_field" dangerouslySetInnerHTML={{__html: @props.before}}></span>}
      <ul className="list-unstyled" tabIndex={@props.tabIndex}>
        {@build_inputs()}
      </ul>
      {@props.after and <span className="after_field" dangerouslySetInnerHTML={{__html: @props.after}}></span>}
    </div>


export default MultiValue
