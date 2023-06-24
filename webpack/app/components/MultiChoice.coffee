import React from "react"


class MultiChoice extends React.Component

  ###*
   * Multi-Choice Field for the Listing Table
   *
   * A multi select field is identified by the column type "multichoice" in the listing
   * view, e.g.  `self.columns = {"Result": {"type": "multichoice"}, ... }`
   *
  ###
  constructor: (props) ->
    super(props)

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
    # Prepare a list of UIDs
    value = (input.value for input in checked)

    console.debug "MultiChoice::on_change: value=#{value}"

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
      selected = option.selected or no
      options.push(
        <li key={value}>
          <input type="checkbox"
                 defaultChecked={selected}
                 uid={@props.uid}
                 name={@props.name}
                 value={value}
                 onChange={@props.onChange or @on_change}
                 column_key={@props.column_key}
                 title={@props.help or @props.title}
                 tabIndex={@props.tabIndex}
                 {...@props.attrs}/> {title}
        </li>)

    return options

  render: ->
    <div className={@props.field_css or "multichoice"}>
      {@props.before and <span className={@props.before_css or "before_field"} dangerouslySetInnerHTML={{__html: @props.before}}></span>}
      <ul className="list-unstyled">
        {@build_options()}
      </ul>
      {@props.after and <span className={@props.after_css or "after_field"} dangerouslySetInnerHTML={{__html: @props.after}}></span>}
    </div>


export default MultiChoice
