import React from "react"


# Columns that are excluded from filtering by default
# These typically don't make sense for filtering even if they have an index
FILTER_EXCLUDED_COLUMNS = [
  "Progress"
  "progress"
  "getProgress"
  "Priority"
]


class TableHeaderCell extends React.Component
  ###
   * The table header cell component renders a single header cell
  ###

  constructor: (props) ->
    super(props)
    @on_filter_toggle = @on_filter_toggle.bind @

  on_filter_toggle: (event) ->
    ###
     * Event handler when the filter toggle button was clicked
    ###
    event.stopPropagation()
    if @props.on_filter_toggle
      @props.on_filter_toggle @props.column_key

  is_filterable: ->
    ###
     * Check if this column should show the filter button
     *
     * A column is filterable if:
     * - It has an index defined
     * - The `filter` attribute is not explicitly set to false
     * - The column key is not in the default exclusion list
    ###
    column = @props.columns?[@props.column_key] or {}
    column_key = @props.column_key

    # Check if filtering is explicitly disabled
    if column.filter is false
      return false

    # Check if column is in the default exclusion list
    # (can be overridden by setting filter: true explicitly)
    console.log "Checking filterability for column:", column_key, column
    if column_key in FILTER_EXCLUDED_COLUMNS and column.filter isnt true
      return false

    # Must have an index to be filterable
    if not column.index?
      return false

    return true

  render: ->
    # Check if column is filterable
    show_filter_button = @is_filterable()

    # Check if filter is active for this column
    is_filter_active = @props.column_key in (@props.active_column_filters or [])

    # Build filter button classes
    filter_btn_cls = ["btn", "btn-link", "btn-sm", "column-filter-toggle"]
    if is_filter_active
      filter_btn_cls.push "active"

    <th title={@props.alt}
        index={@props.index}
        sort_order={@props.sort_order}
        className={@props.className}
        onClick={@props.onClick}>
      <span>{@props.title}</span>
      {show_filter_button and
        <button
          type="button"
          className={filter_btn_cls.join " "}
          onClick={@on_filter_toggle}
          title={_t("Toggle column filter")}>
          <i className="fas fa-filter"></i>
        </button>
      }
    </th>


export default TableHeaderCell
