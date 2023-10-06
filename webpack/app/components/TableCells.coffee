import React from "react"
import Checkbox from "./Checkbox.coffee"
import TableCell from "./TableCell.coffee"
import TableTransposedCell from "./TableTransposedCell.coffee"


class TableCells extends React.Component

  constructor: (props) ->
    super(props)
    @on_remarks_expand_click = @on_remarks_expand_click.bind @

  on_remarks_expand_click: (event) ->
    event.preventDefault()
    el = event.currentTarget
    uid = el.getAttribute "uid"

    # notify parent event handler with the extracted uid
    if @props.on_remarks_expand_click
      @props.on_remarks_expand_click uid

  get_column: (column_key) ->
    return @props.columns[column_key]

  get_item: ->
    return @props.item

  get_uid: ->
    item = @get_item()
    return item.uid

  get_tab_index: (column_key, item) ->
    tabindex = item.tabindex or {column_key: "active"}
    tabindex = tabindex[column_key]
    return if tabindex == "disabled" then -1 else 0

  get_colspan: (column_key, item) ->
    colspan = item.colspan or {}
    return colspan[column_key]

  get_rowspan: (column_key, item) ->
    rowspan = item.rowspan or {}
    return rowspan[column_key]

  skip_cell_rendering: (column_key) ->
    item = @get_item()
    skip = item.skip or []
    return column_key in skip

  show_select: ->
    item = @get_item()
    if typeof item.show_select == "boolean"
      return item.show_select
    return @props.show_select_column

  is_transposed: (column_key) ->
    column = @get_column column_key
    return column.type == "transposed"

  get_transposed_items: () ->
    item = @get_item()
    transposed_keys = item.transposed_keys or []
    return transposed_keys.map (key) -> item[key]

  has_transposed_items: () ->
    return @get_transposed_items().length > 0

  is_loading: (uid) ->
    loading_uids = this.props.loading_uids or []
    return loading_uids.indexOf(uid) > -1

  get_errors_for: (uid) ->
    errors = this.props.errors or {}
    return errors[uid] or []

  ###*
   * Creates a checkbox for multiple uids
   * @returns SelectCell component
  ###
  create_multi_select_cell: (uids) ->
    value = uids.join(",")
    item = @get_item()
    level = item.node_level or 0
    cell = (
      <td key={value} className="level-#{level}">
        <Checkbox
          value={value}
          tabIndex="-1"
          onChange={@props.on_multi_select_checkbox_checked}/>
      </td>)
    return cell


  ###*
   * Creates a select cell
   *
   * @returns SelectCell component
  ###
  create_select_cell: () ->
    uid = @get_uid()
    checkbox_name = "#{@props.select_checkbox_name}:list"
    item = @get_item()
    remarks = @props.remarks  # True if this row follows a remarks row
    level = item.node_level or 0
    loading = @is_loading(uid)
    errors = @get_errors_for(uid)
    cell = (
      <td key={uid} className="level-#{level}">
        {!loading &&
          <Checkbox
            name={checkbox_name}
            value={uid}
            disabled={@props.disabled}
            checked={@props.selected}
            tabIndex="-1"
            onChange={@props.on_select_checkbox_checked}/>
          }

        {loading &&
        <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>}

        {errors.length > 0 &&
        <span className="text-warning fas fa-exclamation-triangle"
              title={errors.join("\n")}>
        </span>}

        {remarks &&
        <a uid={uid}
            href="#"
            className="remarks"
            onClick={@on_remarks_expand_click}>
          <span className="remarksicon fas fa-comment-alt"/>
        </a>}
      </td>)
    return cell

  ###*
   * Create an empty placeholder cell
  ###
  create_placeholder_cell: () ->
    cell = (<td className="placeholder"></td>)
    return cell

  ###*
   * Creates a regular table cell
   *
   * @param column_key {String} The key of the column definition
   * @param column_index {Integer} The current cell index
   * @returns TableCell component
  ###
  create_regular_cell: (column_key, column_index) ->
    item = @get_item()
    column = @get_column column_key
    colspan = @get_colspan column_key, item
    rowspan = @get_rowspan column_key, item
    tabindex = @get_tab_index column_key, item
    css = "contentcell #{column_key}"

    cell = (
      <TableCell
        {...@props}
        key={column_index}
        item={item}
        column_key={column_key}
        column_index={column_index}
        column={column}
        colspan={colspan}
        rowspan={rowspan}
        className={css}
        tabIndex={tabindex}
        />)
    return cell

  ###*
   * Creates a transposed cell
   *
   * Transposed cell items contain an object key "column_key", which points to
   * the transposed folderitem requested.
   *
   * E.g. a transposed worksheet would have the positions (1, 2, 3, ...) as
   * columns and the contained services of each position as rows.
   * {"column_key": "1", "1": {"Service": "Calcium", ...}}
   *
   * The column for "1" would then contain the type "transposed".
   *
   * @param column_key {String} The key of the column definition
   * @param column_index {Integer} The current cell index
   * @returns TableTransposedCell component
  ###
  create_transposed_cell: (column_key, column_index) ->
    item = @get_item()
    column = @get_column column_key
    colspan = @get_colspan column_key, item
    rowspan = @get_rowspan column_key, item
    tabindex = @get_tab_index column_key, item
    css = "contentcell #{column_key}"

    cell = (
      <TableTransposedCell
        {...@props}
        key={column_index}
        item={item}
        column_key={column_key}
        column_index={column_index}
        column={column}
        colspan={colspan}
        rowspan={rowspan}
        on_remarks_expand_click={@on_remarks_expand_click}
        className={css}
        tabIndex={tabindex}
        />)
    return cell


  ###*
   * Creates a Drag&Drop handler cell
   *
  ###
  create_dnd_cell: () ->
    item = @get_item()
    uid = @get_uid()
    level = item.node_level or 0
    cell = (
      <td ref={@props.dragref} key="dnd" className="level-#{level} dnd">
        <i className="fas fa-sort"></i>
      </td>
    )
    return cell


  build_cells: ->
    cells = []

    # insert select column
    if @show_select() and not @has_transposed_items()
      cells.push @create_select_cell()
    else if @show_select() and @has_transposed_items()
      items = @get_transposed_items()
      uids = items.map (item) -> item.uid
      cells.push @create_multi_select_cell uids

    if @props.allow_row_reorder
      cells.push @create_dnd_cell()

    # insert visible columns in the right order
    for column_key, column_index in @props.visible_columns

      # Skip single cell rendering to support rowspans
      if @skip_cell_rendering column_key
        continue

      if @is_transposed column_key
        # Transposed Cell
        cells.push @create_transposed_cell column_key, column_index
      else
        # Regular Cell
        cells.push @create_regular_cell column_key, column_index

    return cells

  render: ->
    return @build_cells()


export default TableCells
