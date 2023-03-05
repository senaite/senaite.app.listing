import React from "react"


class DateTime extends React.Component

  ###*
   * DateTime field for the Listing Table
   *
   * A datetime field is identified by the column type "datetime" in the listing
   * view, e.g.  `self.columns = {"Result": {"type": "datetime"}, ... }`
   *
  ###
  constructor: (props) ->
    super(props)

    # remember the initial value
    @state =
      value: props.defaultValue
      date_value: ""
      time_value: ""

    if props.defaultValue
      parts = props.defaultValue.split(" ")
      @state["date_value"] = if parts.length > 0 then parts[0] else ""
      @state["time_value"] = if parts.length > 1 then parts[1] else ""

    @dt_date = React.createRef()
    @dt_time = React.createRef()
    @dt_hidden = React.createRef()

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
   * Event handler when the value changed of the datetime field
   * @param event {object} ReactJS event object
  ###
  on_change: (event) ->

    # extract the current date and time values
    dt_date = @dt_date.current.value
    dt_time = @dt_time.current.value

    # ensure both components are set
    if dt_date and not dt_time
      dt_time = "00:00"

    # set the concatenated date and time to the hidden field
    if dt_date and dt_time
      value = "#{dt_date} #{dt_time}"
    else
      value = ""

    this.setState
      value: value
      date_value: dt_date
      time_value: dt_time

    # extract the field values from the hidden field
    el = @dt_hidden.current
    # Extract the UID attribute
    uid = el.getAttribute("uid")
    # Extract the column_key attribute
    name = el.getAttribute("column_key") or el.name
    # Extract the value of the datetime field
    value = el.value

    console.debug "DateTime::on_change: value=#{value}"

    # Call the *update* field handler
    if @props.update_editable_field
      @props.update_editable_field uid, name, value, @props.item

  render: ->
    <span className="form-group">
      {@props.before and <span className="before_field" dangerouslySetInnerHTML={{__html: @props.before}}></span>}
      <div className="input-group flex-nowrap d-inline-flex w-auto datetimewidget">
        <input type="date"
               ref={@dt_date}
               name="#{@props.name}-date"
               title={@props.help or @props.title}
               className={@props.className}
               disabled={@props.disabled}
               required={@props.required}
               onChange={@props.onChange or @on_change}
               tabIndex={@props.tabIndex}
               value={@state.date_value}
               min={@props.min_date}
               max={@props.max_date}
               {...@props.attrs}/>
        <input type="time"
               ref={@dt_time}
               name="#{@props.name}-time"
               className={@props.className}
               title={@props.title}
               disabled={@props.disabled}
               required={@props.required}
               onChange={@props.onChange or @on_change}
               tabIndex={@props.tabIndex}
               value={@state.time_value}
               min={@props.min_time}
               max={@props.max_time}
               {...@props.attrs}/>
      </div>
      <input
        type="hidden"
        ref={@dt_hidden}
        uid={@props.uid}
        name={@props.name}
        column_key={@props.column_key}
        value={@state.value} />

      {@props.after and <span className="after_field" dangerouslySetInnerHTML={{__html: @props.after}}></span>}
    </span>


export default DateTime
