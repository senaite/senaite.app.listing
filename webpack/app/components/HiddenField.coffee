import React from "react"


class HiddenField extends React.Component

  ###*
   * Hidden Field for the Listing Table
   *
   * Render this field to ensure the value is sent to the server on form submission
   *
  ###
  constructor: (props) ->
    super(props)

  render: ->
    <span className={@props.field_css or "form-group"}>
      {@props.before and <span className={@props.before_css or "before_field"} dangerouslySetInnerHTML={{__html: @props.before}}></span>}
      <input type="hidden"
            uid={@props.uid}
            name={@props.name}
            value={@props.value}
            column_key={@props.column_key}
            className={@props.className}
            {...@props.attrs}/>
      {@props.after and <span className={@props.after_css or "after_field"} dangerouslySetInnerHTML={{__html: @props.after}}></span>}
    </span>


export default HiddenField
