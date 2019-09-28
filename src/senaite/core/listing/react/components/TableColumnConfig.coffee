import React from "react"


class TableColumnConfig extends React.Component

  constructor: (props) ->
    super(props)

    @on_drag_start = @on_drag_start.bind @
    @on_drag_end = @on_drag_end.bind @
    @on_drag_over = @on_drag_over.bind @
    @on_column_toggle_click = @on_column_toggle_click.bind @
    @on_reset_click = @on_reset_click.bind @

    @state =
      columns_order: @props.columns_order

  ###*
   * componentDidUpdate(prevProps, prevState, snapshot)
   *
   * This is invoked immediately after updating occurs.
   * This method is not called for the initial render.
  ###
  componentDidUpdate: (prevProps, prevState, snapshot) ->
    # update the column order from the listing
    if @props.columns_order != prevProps.columns_order
        @setState {columns_order: @props.columns_order}

  on_reset_click: (event) ->
    event.preventDefault()
    # call the parent event handler
    if @props.on_column_toggle_click
      @props.on_column_toggle_click "reset"

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

    columns_order = @state.columns_order
    # index of the second column
    index = columns_order.indexOf column2
    # filter out the currently dragged item
    columns_order = columns_order.filter (column) -> column isnt column1
    # add the dragged column after the dragged over column
    columns_order.splice index, 0, column1
    # set the new columns order to the local state
    @setState {columns_order: columns_order}

  on_drag_end: (event) ->
    @dragged_item = null
    # call the event handler of the controller to change the column order
    if @props.on_columns_order_change
      @props.on_columns_order_change @state.columns_order

  on_column_toggle_click: (event) ->
    return if event.target.type is "checkbox"
    event.preventDefault()
    el = event.currentTarget
    column = el.getAttribute "column"
    # call the event handler of the controller to toggle the column
    if @props.on_column_toggle_click
      @props.on_column_toggle_click column

  is_column_visible: (column) ->
    return column.toggle isnt off

  build_column_toggles: ->
    columns = []
    for key in @state.columns_order
      column = @props.columns[key]
      visible = @is_column_visible column
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
              {visible and <span className="glyphicon glyphicon-check"></span>}
              {not visible and <span className="glyphicon glyphicon-unchecked"></span>}
              &nbsp;<span dangerouslySetInnerHTML={{__html: column.title or key}}></span>
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

            <li
              key="reset"
              style={{padding: "0 5px 5px 0"}}>
              <button onClick={@on_reset_click} className="btn btn-warning btn-xs">
                {_("Reset Columns")}
              </button>
            </li>
          </ul>
        </div>
      </div>
    </div>

export default TableColumnConfig
