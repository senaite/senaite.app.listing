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
    @on_sort_asc = @on_sort_asc.bind @
    @on_sort_desc = @on_sort_desc.bind @

  on_filter_toggle: (event) ->
    ###
     * Event handler when the filter toggle button was clicked
    ###
    event.stopPropagation()
    if @props.on_filter_toggle
      @props.on_filter_toggle @props.column_key

  on_sort_asc: (event) ->
    ###
     * Sort this column ascending (direct, no toggle)
    ###
    event.stopPropagation()
    event.preventDefault()
    if @props.on_sort_click and @props.index
      @props.on_sort_click @props.index, "ascending"

  on_sort_desc: (event) ->
    ###
     * Sort this column descending (direct, no toggle)
    ###
    event.stopPropagation()
    event.preventDefault()
    if @props.on_sort_click and @props.index
      @props.on_sort_click @props.index, "descending"

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

    # Editor cell open for this column
    is_editor_open = @props.column_key in (@props.active_column_filters or [])
    # The column carries a current filter value (set manually or via a
    # saved preset); highlight the funnel so the user sees which
    # columns are filtered even when the editor cell is closed
    column_filters = @props.column_filters or {}
    has_filter_value = !!column_filters[@props.column_key]
    is_filter_active = is_editor_open or has_filter_value

    # Build filter button classes
    filter_btn_cls = ["btn", "btn-link", "btn-sm", "column-filter-toggle"]
    if is_filter_active
      filter_btn_cls.push "active"

    # Sort state for this column
    sortable = @props.className and "sortable" in @props.className.split(" ")
    is_sort_column = sortable and (@props.index is @props.sort_on)
    asc_active = is_sort_column and @props.sort_order is "ascending"
    desc_active = is_sort_column and @props.sort_order is "descending"

    asc_cls = ["column-sort-arrow", "column-sort-asc"]
    if asc_active
      asc_cls.push "active"
    desc_cls = ["column-sort-arrow", "column-sort-desc"]
    if desc_active
      desc_cls.push "active"

    <th title={@props.alt}
        index={@props.index}
        sort_order={@props.sort_order}
        className={@props.className}
        onClick={@props.onClick}>
      <div className="column-header-inner">
        <span className="column-title" title={@props.title}>
          {@props.title}
        </span>
        {(sortable or show_filter_button) and
          <span className="column-header-controls">
            {sortable and
              <span className="column-sort-arrows">
                <button
                  type="button"
                  className={asc_cls.join " "}
                  onClick={@on_sort_asc}
                  title={_t("Sort ascending")}
                  aria-label={_t("Sort ascending")}>
                  <i className="fas fa-chevron-up"></i>
                </button>
                <button
                  type="button"
                  className={desc_cls.join " "}
                  onClick={@on_sort_desc}
                  title={_t("Sort descending")}
                  aria-label={_t("Sort descending")}>
                  <i className="fas fa-chevron-down"></i>
                </button>
              </span>
            }
            {show_filter_button and
              <button
                type="button"
                className={filter_btn_cls.join " "}
                onClick={@on_filter_toggle}
                title={_t("Toggle column filter")}>
                <i className="fas fa-filter"></i>
              </button>
            }
          </span>
        }
      </div>
    </th>


export default TableHeaderCell
