import React from "react"


class Button extends React.Component
  ###
   * The button component renders a single button
  ###

  render: ->
    ###
     * Render the Button component
    ###
    <button id={@props.id}
            title={@props.help or @props.title}
            name={@props.name}
            url={@props.url}
            onClick={@props.onClick}
            className={@props.className}
            disabled={@props.disabled}
            {...@props.attrs}>
      <span dangerouslySetInnerHTML={{__html: @props.title}}></span>
      {@props.badge and
        <span className="badge badge-light"
              style={{marginLeft: "0.25em"}}>
          {@props.badge}
        </span>
      }
    </button>


export default Button
