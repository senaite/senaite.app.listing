import React from "react"
import TableRow from "./TableRow"


class TableCategoryRow extends React.Component

  constructor: (props) ->
    super(props)
    # Bind event handler to local context
    @on_category_click = @on_category_click.bind @
    @on_category_select = @on_category_select.bind @

  on_category_click: (event) ->
    console.debug "TableCategoryRow::on_category_click: #{@props.category}"
    # notify parent event handler with the extracted values
    if @props.on_category_click
      @props.on_category_click event

  on_category_select: (event) ->
    category = @props.category
    console.debug "TableCategoryRow::on_category_select: #{@props.category}"
    # notify parent event handler with the extracted values
    if @props.on_category_select
      @props.on_category_select event

  build_category: ->
    cells = []

    category = @props.category
    show_select_column = @props.show_select_column
    expanded = @props.expanded
    selected = @props.selected
    colspan = @props.columns_count

    if expanded
      cls = "expanded"
      icon_cls = "fas fa-caret-square-down"
    else
      cls = "collapsed"
      icon_cls = "fas fa-caret-square-up"

    if show_select_column
      colspan -= 1
      cells.push(
        <td key="select">
          <span category={category}
                onClick={@on_category_select}>
            {selected and <i className="fas fa-check-circle"></i>}
            {not selected and <i className="fas fa-dot-circle"></i>}
          </span>
        </td>
      )

    cells.push(
      <td key="toggle"
          category={category}
          className={cls}
          onClick={@on_category_click}
          colSpan={colspan}>
        <i className={icon_cls}></i> <span>{category}</span>
      </td>
    )

    return cells

  render: ->
    <tr category={@props.category}
        className={@props.className}>
      {@build_category()}
    </tr>


export default TableCategoryRow
