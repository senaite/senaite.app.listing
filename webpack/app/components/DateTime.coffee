import React from "react"


class DateTime extends React.Component

  ###*
   * Date/DateTime field for the Listing Table
   *
   * A date/datetime field is identified by the column type "date" or "datetime" in the listing
   * view, e.g.  `self.columns = {"Result": {"type": "datetime"}, ... }`
  ###
  constructor: (props) ->
    super(props)

    # remember the initial value
    @state =
      value: props.defaultValue
      date_value: ""
      time_value: ""

    value = props.defaultValue
    if value
      @state.value = @format_date_value(value)
      @state.date_value = @format_date(value)
      @state.time_value = @format_time(value)

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
      value = @props.defaultValue
      @setState
        value: @format_date_value(value)
        date_value: @format_date(value)
        time_value: @format_time(value)

  ###*
   * Format the date value
   *
   * @param d {string,object} date string or object
   * @returns {string} date or datetime
  ###
  format_date_value: (d) ->
      if @props.type == "date"
        return @format_date(d)
      return "#{@format_date(d)} #{@format_time(d)}"

  ###*
   * Format a date string/object to a date string with the format %Y-%m-%d
   *
   * @param d {string,object} date string or object
   * @returns {string} date in the format %Y-%m-%d
  ###
  format_date: (d) ->
      date = new Date(d)
      year = date.getFullYear()
      month = String(date.getMonth() + 1).padStart(2, "0")
      day = String(date.getDate()).padStart(2, "0")
      return "#{year}-#{month}-#{day}"

  ###*
   * Format a date string/object to a time string with the format %H:%M
   *
   * @param d {string,object} date string or object
   * @returns {string} time in the format %H-%M
  ###
  format_time: (d) ->
      date = new Date(d)
      hours = String(date.getHours()).padStart(2, "0")
      minutes = String(date.getMinutes()).padStart(2, "0")
      return "#{hours}:#{minutes}"

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

    console.debug "DateTime::on_change: value=#{value}"

    # Call the *update* field handler
    if @props.update_editable_field
      @props.update_editable_field uid, name, value, @props.item

  render: ->
    <span className={@props.field_css or "form-group"}>
      {@props.before and <span className={@props.before_css or "before_field"} dangerouslySetInnerHTML={{__html: @props.before}}></span>}
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
        {@props.type == "datetime" and
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
        }
      </div>
      <input
        type="hidden"
        ref={@dt_hidden}
        uid={@props.uid}
        name={@props.name}
        column_key={@props.column_key}
        value={@state.value} />
      {@props.after and <span className={@props.after_css or "after_field"} dangerouslySetInnerHTML={{__html: @props.after}}></span>}
    </span>


export default DateTime
