import React from "react"


class FractionField extends React.Component

  ###*
   * Fraction Field for the Listing Table
   *
   * A numeric field is identified by the column type "fraction" in the listing
   * view, e.g.  `self.columns = {"Result": {"type": "fraction"}, ... }`
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
   * Event handler when the mouse left the fraction field
   * @param event {object} ReactJS event object
  ###
  on_blur: (event) ->
    el = event.currentTarget
    # Extract the UID attribute
    uid = el.getAttribute("uid")
    # Extract the column_key attribute
    name = el.getAttribute("column_key") or el.name
    # Extract the value of the fraction field
    value = el.value
    # Remove trailing dots and/or fraction chars
    value = value.replace /[\.,\/]*$/, ""
    # Validate if the entered value is a fraction
    if not @validate(value)
      value = ""
    # Set the sanitized value back to the field
    el.value = value
    # store the sanitized value in the state
    @setState
      value: value
      size: @get_field_size_for(value)
    console.debug "FractionField::on_blur: value=#{value}"

    # Call the *save* field handler with the UID, name, value
    if @props.save_editable_field
      @props.save_editable_field uid, name, value, @props.item

  ###*
   * Event handler when the value changed of the fraction field
   * @param event {object} ReactJS event object
  ###
  on_change: (event) ->
    el = event.currentTarget
    # Extract the UID attribute
    uid = el.getAttribute("uid")
    # Extract the column_key attribute
    name = el.getAttribute("column_key") or el.name
    # Extract the value of the fraction field
    value = el.value
    # Remove trailing detection limits, dots and/or fraction chars. Validator
    # may fail otherwise because the user is still typing
    fraction = value.replace /[<,>,=,\.,\/]*$/, ""
    # Validate if the entered value is a fraction
    console.debug "FractionField::on_change: value=#{value} fraction=#{fraction}"
    if fraction and not @validate(fraction)
      value = value.replace fraction, ""
    # Set the sanitized value back to the field
    el.value = value
    # store the new value
    @setState
      value: value
      size: @get_field_size_for(value)
    console.debug "FractionField::on_change: value=#{value}"

    # Call the *update* field handler
    if @props.update_editable_field
      @props.update_editable_field uid, name, value, @props.item

  ###*
   * Calculate the field size for the given value to make all digits visible
   * @param value {string} a fraction string value
  ###
  get_field_size_for: (value) ->
    length = value.toString().length
    if length < @props.size
      return @props.size
    return length

  ###*
   * Checks if the entered value is a valid fraction
   * @param value {string} the value
  ###
  validate: (value) ->
    # remove leading detection limits
    value = value.replace /^([<,>,<,=]*)(.*)$/, "$2"
    # remove trailing dots and/or fraction chars
    number = value.replace /[\.,\/]*$/, ""
    if not number
      return false

    # split fraction into numerator and denominator
    numbers = number.split("/")
    if numbers.length != 2
      return not Number.isNaN(Number(number))

    # ensure the numerator is a number and different from 0
    numerator = Number(numbers[0])
    if Number.isNaN(numerator) or numerator == 0
      return false

    # ensure the denominator is a number and different from 0
    denominator = Number(numbers[1])
    if Number.isNaN(denominator) or denominator == 0
      return false

    return true

  render: ->
    <span className={@props.field_css or "form-group"}>
      {@props.before and <span className={@props.before_css or "before_field"} dangerouslySetInnerHTML={{__html: @props.before}}></span>}
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
      {@props.after and <span className={@props.after_css or "after_field"} dangerouslySetInnerHTML={{__html: @props.after}}></span>}
    </span>


export default FractionField
