import React from "react"


class ReadonlyField extends React.Component

  constructor: (props) ->
    super(props)

  is_boolean_field: ->
    if typeof(@props.value) == "boolean"
      return yes
    return no

  render: ->
    if @is_boolean_field()
      if @props.value
        return <span>{_t("Yes")}</span>
      else
        return <span>{_t("No")}</span>
    else
      return (
        <span className={@props.field_css or "form-group"}>
          {@props.before and <span className={@props.before_css or "before_field"} dangerouslySetInnerHTML={{__html: @props.before}}></span>}
          <span dangerouslySetInnerHTML={{__html: @props.formatted_value}} {...@props.attrs}></span>
          {@props.after and <span className={@props.after_css or "after_field"} dangerouslySetInnerHTML={{__html: @props.after}}></span>}
        </span>
      )


export default ReadonlyField
