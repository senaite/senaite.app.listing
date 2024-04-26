import React from "react"


class TextField extends React.Component

  ###*
   * Text Field for the Listing Table
   *
   * A text field is identified by the column type "text" in the listing
   * view, e.g.  `self.columns = {"Result": {"type": "text"}, ... }`
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
   * componentDidUpdate(prevProps, prevState, snapshot)
   * This is invoked immediately after updating occurs.
   * This method is not called for the initial render.
  ###
  componentDidUpdate: (prevProps) ->
    if @props.defaultValue != prevProps.defaultValue
      @setState value: @props.defaultValue

  ###*
   * Event handler when the value changed of the text field
   * @param event {object} ReactJS event object
  ###
  on_change: (event) ->
    el = event.currentTarget
    # Extract the UID attribute
    uid = el.getAttribute("uid")
    # Extract the column_key attribute
    name = el.getAttribute("column_key") or el.name
    # Extract the value of the text field
    value = el.value

    # store the new value
    @setState
      value: value

    console.debug "StringField::on_change: value=#{value}"

    # Call the *update* field handler
    if @props.update_editable_field
      @props.update_editable_field uid, name, value, @props.item

  render: ->
    <span className={@props.field_css or "form-group"}>
      {@props.before and <span className={@props.before_css or "before_field"} dangerouslySetInnerHTML={{__html: @props.before}}></span>}
      <textarea
             rows={@props.rows or 3}
             cols={@props.size or 20}
             uid={@props.uid}
             name={@props.name}
             value={@state.value}
             column_key={@props.column_key}
             title={@props.help or @props.title}
             disabled={@props.disabled}
             required={@props.required}
             className={@props.className}
             placeholder={@props.placeholder}
             onChange={@props.onChange or @on_change}
             tabIndex={@props.tabIndex}
             {...@props.attrs}/>
      {@props.after and <span className={@props.after_css or "after_field"} dangerouslySetInnerHTML={{__html: @props.after}}></span>}
    </span>


export default TextField
