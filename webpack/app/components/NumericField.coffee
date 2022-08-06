import React from "react"


class NumericField extends React.Component

  ###*
   * Numeric Field for the Listing Table
   *
   * A numeric field is identified by the column type "numeric" in the listing
   * view, e.g.  `self.columns = {"Result": {"type": "numeric"}, ... }`
   *
  ###
  constructor: (props) ->
    super(props)

    # remember the initial value
    @state =
      value: props.defaultValue
      size: @get_field_size_for(props.defaultValue)

    # bind event handler to the current context
    @on_blur = @on_blur.bind @
    @on_change = @on_change.bind @

  ###*
   * componentDidUpdate(prevProps, prevState, snapshot)
   * This is invoked immediately after updating occurs.
   * This method is not called for the initial render.
  ###
  componentDidUpdate: (prevProps) ->
    if @props.defaultValue != prevProps.defaultValue
      @setState value: @props.defaultValue

  ###*
   * Event handler when the mouse left the numeric field
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
    # Remove any trailing dots
    value = value.replace(/\.*$/, "")
    # Validate if the entered value can be converted to a Number
    if not @validate(value)
      value = ""
    # Set the sanitized value back to the field
    el.value = value
    # store the sanitized value in the state
    @setState
      value: value
      size: @get_field_size_for(value)
    console.debug "NumericField::on_blur: value=#{value}"

    # Call the *save* field handler with the UID, name, value
    if @props.save_editable_field
      @props.save_editable_field uid, name, value, @props.item

  ###*
   * Event handler when the value changed of the numeric field
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
    # Convert the value to float
    value = @to_float value
    # Set the float value back to the field
    el.value = value
    # store the new value
    @setState
      value: value
      size: @get_field_size_for(value)

    console.debug "NumericField::on_change: value=#{value}"

    # Call the *update* field handler
    if @props.update_editable_field
      @props.update_editable_field uid, name, value, @props.item

  ###*
   * Float converter
   * @param value {string} a numeric string value
  ###
  to_float: (value) ->
    # Valid -.5; -0.5; -0.555; .5; 0.5; 0.555
    #       -,5; -0,5; -0,555; ,5; 0,5; 0,555
    # Non Valid: -.5.5; 0,5,5; ...;
    #
    # New in version 2.3: Allow exponential notation, e.g. 1e-5 for 0.00005 or 1e5 for 10000
    value = value.replace /(^[-,<,>]?)(\d*)([e][-,\+]?\d*|[\.,\,]?\d*)(.*)/, "$1$2$3"
    value = value.replace(",", ".")
    return value

  ###*
   * Calculate the field size for the given value to make all digits visble
   * @param value {string} a numeric string value
  ###
  get_field_size_for: (value) ->
    length = value.toString().length
    if length < @props.size
      return @props.size
    return length


  ###*
   * Checks if the entered value is valid
   * @param value {string} the value
  ###
  validate: (value) ->
    # strip off detection limits
    number = value.replace /(^[<,>]?)(.*)/, "$2"
    return not Number.isNaN(Number(number))


  render: ->
    <span className="form-group">
      {@props.before and <span className="before_field" dangerouslySetInnerHTML={{__html: @props.before}}></span>}
      <input type="text"
             size={@state.size}
             uid={@props.uid}
             name={@props.name}
             value={@state.value}
             column_key={@props.column_key}
             title={@props.help or @props.title}
             disabled={@props.disabled}
             required={@props.required}
             className={@props.className}
             placeholder={@props.placeholder}
             onBlur={@props.onBlur or @on_blur}
             onChange={@props.onChange or @on_change}
             tabIndex={@props.tabIndex}
             {...@props.attrs}/>
      {@props.after and <span className="after_field" dangerouslySetInnerHTML={{__html: @props.after}}></span>}
    </span>


export default NumericField
