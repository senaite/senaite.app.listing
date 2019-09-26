import React from "react"


class TableColumnConfig extends React.Component

  constructor: (props) ->
    super(props)
    @on_drag_start = @on_drag_start.bind @
    @on_drag_end = @on_drag_end.bind @
    @on_drag_over = @on_drag_over.bind @
    @on_column_toggle_click = @on_column_toggle_click.bind @
    @on_column_toggle_changed = @on_column_toggle_changed.bind @

    @state =
      columns: @get_ordered_column_keys()

  on_drag_start: (event) ->
    @dragged_item = event.currentTarget
    event.dataTransfer.effectAllowed = "move";
    event.dataTransfer.setData("text/html", @dragged_item)
    event.dataTransfer.setDragImage(@dragged_item, 50, 0)

  on_drag_over: (event) ->
    li = event.currentTarget
    return unless li isnt @dragged_item

    column1 = @dragged_item.getAttribute "column"
    column2 = li.getAttribute "column"

    columns = @state.columns
    # index of the second column
    index = columns.indexOf column2
    # filter out the currently dragged item
    columns = columns.filter (column) => column isnt column1
    # add the dragged column after the dragged over column
    columns.splice index, 0, column1
    @setState
      columns: columns

  on_drag_end: (event) ->
    @dragged_item = null
    @props.set_column_order @state.columns

  on_column_toggle_click: (event) ->
    return if event.target.type is "checkbox"
    event.preventDefault()
    el = event.currentTarget
    column = el.getAttribute "column"
    @props.on_column_toggle column

  on_column_toggle_changed: (event) ->
    el = event.currentTarget
    column = el.getAttribute "column"
    @props.on_column_toggle column

  is_visible: (key) ->
    return key in @props.table_columns

  get_ordered_column_keys: ->
    if @props.ordered_columns.length > 0
      return @props.ordered_columns
    return Object.keys @props.columns

  build_column_toggles: ->
    columns = []
    for key in @state.columns
      column = @props.columns[key]
      checked = @is_visible key
      columns.push(
        <li
          key={key}
          column={key}
          style={{padding: "0 5px 5px 0"}}
          className="column"
          onDragOver={@on_drag_over}>
          <div
            column={key}
            className="draggable-column"
            onDragStart={@on_drag_start}
            onDragEnd={@on_drag_end}
            draggable={true}>
            <button
              column={key}
              onClick={@on_column_toggle_click}
              className="btn btn-default btn-xs">
              <input
                type="checkbox"
                column={key}
                onChange={@on_column_toggle_changed}
                checked={checked}/>
              &nbsp;<span className="glyphicon glyphicon-menu-hamburger"></span>
              &nbsp;<span>{column.title or key}</span>
            </button>
          </div>
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

export default TableColumnConfig
