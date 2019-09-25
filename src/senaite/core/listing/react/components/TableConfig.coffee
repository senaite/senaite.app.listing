import React from "react"


class TableConfig extends React.Component

  constructor: (props) ->
    super(props)
    @on_column_visibility_click = @on_column_visibility_click.bind @
    @on_column_visibility_changed = @on_column_visibility_changed.bind @

  on_column_visibility_click: (event) ->
    ###
     * Event handler when a column checkbox was clicked
    ###
    event.preventDefault()
    column = event.currentTarget.name
    @props.on_column_visibility_changed column


  on_column_visibility_changed: (event) ->
    ###
     * Event handler when a column checkbox was clicked
    ###

    # get the column id
    column = event.currentTarget.name
    @props.on_column_visibility_changed column


  is_visible: (key) ->
    if key in @props.visible_columns
      return yes
    return no


  build_column_toggles: ->
    columns = []
    for key, column of @props.columns
      visible = @is_visible(key)
      columns.push(
        <li key={key} className="column-toggle">
          <button
            name={key}
            onClick={@on_column_visibility_click}
            className="btn btn-default btn-xs">
            <input
              type="checkbox"
              name={key}
              onChange={@on_column_visibility_changed}
              checked={visible}/> {column.title or key}
          </button>
        </li>
      )
    return columns


  render: ->
    <div id={@props.id} className={@props.className}>
      <div className="row">
        <div className="col-sm-12 text-left">
          <h5>{@props.title}</h5>
          <ul className="list-inline">
            {@build_column_toggles()}
          </ul>
        </div>
      </div>
    </div>

export default TableConfig
