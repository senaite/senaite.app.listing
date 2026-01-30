import React from "react";
import SearchableSelect from "./SearchableSelect.js";


// Module-level cache for index values (persists across component instances)
// Structure: {form_id: {column_key: {values: [], index_type: ""}}}
const INDEX_VALUES_CACHE = {};


class ColumnFilterRow extends React.Component {
  /**
   * The column filter row component renders a row of filter inputs
   * below the header row for per-column filtering.
   *
   * Supports different input types based on index type:
   * - BooleanIndex: Yes/No select
   * - DateIndex: Date picker
   * - FieldIndex/KeywordIndex: Searchable select with filtering
   * - Others: Text input
   */

  constructor(props) {
    super(props);
    this.state = {
      // Loading state for index values
      loading_values: {}
    };

    this.on_filter_change = this.on_filter_change.bind(this);
    this.on_select_change = this.on_select_change.bind(this);
    this.on_searchable_select_change = this.on_searchable_select_change.bind(this);
    this.on_searchable_select_submit = this.on_searchable_select_submit.bind(this);
    this.on_date_change = this.on_date_change.bind(this);
    this.on_keydown = this.on_keydown.bind(this);
    this.on_clear = this.on_clear.bind(this);
    this.on_focus = this.on_focus.bind(this);
  }

  componentDidMount() {
    /**
     * Fetch index values for active filters on mount
     */
    this.fetch_active_filter_values();
  }

  componentDidUpdate(prevProps) {
    /**
     * Fetch index values when new filters are activated
     */
    const prev_filters = prevProps.active_column_filters || [];
    const curr_filters = this.props.active_column_filters || [];

    // Check if new filters were added
    const new_filters = curr_filters.filter((f) => !prev_filters.includes(f));
    if (new_filters.length > 0) {
      this.fetch_active_filter_values();
    }
  }

  get_cache_key() {
    /**
     * Get the cache key for this listing
     */
    return this.props.form_id || "default";
  }

  get_cached_values(column_key) {
    /**
     * Get cached index values for a column
     */
    const cache_key = this.get_cache_key();
    if (INDEX_VALUES_CACHE[cache_key] &&
        INDEX_VALUES_CACHE[cache_key][column_key]) {
      return INDEX_VALUES_CACHE[cache_key][column_key];
    }
    return null;
  }

  set_cached_values(column_key, data) {
    /**
     * Set cached index values for a column
     */
    const cache_key = this.get_cache_key();
    if (!INDEX_VALUES_CACHE[cache_key]) {
      INDEX_VALUES_CACHE[cache_key] = {};
    }
    INDEX_VALUES_CACHE[cache_key][column_key] = data;
  }

  fetch_active_filter_values() {
    /**
     * Fetch index values for all active column filters
     */
    const active_filters = this.props.active_column_filters || [];
    for (const key of active_filters) {
      const column = this.props.columns?.[key];
      const index_type = column?.index_type;
      // Only fetch for index types that can have selectable values
      if (["FieldIndex", "KeywordIndex"].includes(index_type)) {
        this.fetch_index_values(key);
      }
    }
  }

  on_filter_change(event) {
    /**
     * Event handler when a text filter input value changes
     */
    const column_key = event.target.dataset.columnKey;
    const value = event.target.value;
    if (this.props.on_column_filter_change) {
      this.props.on_column_filter_change(column_key, value);
    }
  }

  on_select_change(event) {
    /**
     * Event handler when a select filter value changes
     * Immediately submits the filter
     */
    const column_key = event.target.dataset.columnKey;
    const value = event.target.value;
    if (this.props.on_column_filter_change) {
      this.props.on_column_filter_change(column_key, value);
    }
    // Auto-submit on select change
    if (this.props.on_column_filter_submit) {
      setTimeout(() => {
        this.props.on_column_filter_submit();
      }, 0);
    }
  }

  on_searchable_select_change(column_key, value) {
    /**
     * Event handler when searchable select value changes
     */
    if (this.props.on_column_filter_change) {
      this.props.on_column_filter_change(column_key, value);
    }
  }

  on_searchable_select_submit() {
    /**
     * Event handler when searchable select submits (Enter or option select)
     */
    if (this.props.on_column_filter_submit) {
      setTimeout(() => {
        this.props.on_column_filter_submit();
      }, 0);
    }
  }

  on_date_change(event) {
    /**
     * Event handler when a date filter value changes
     * Immediately submits the filter
     */
    const column_key = event.target.dataset.columnKey;
    const value = event.target.value;
    if (this.props.on_column_filter_change) {
      this.props.on_column_filter_change(column_key, value);
    }
    // Auto-submit on date change
    if (this.props.on_column_filter_submit) {
      setTimeout(() => {
        this.props.on_column_filter_submit();
      }, 0);
    }
  }

  on_keydown(event) {
    /**
     * Event handler for keydown in filter input
     * Submit filter on Enter key
     */
    if (event.key === "Enter") {
      if (this.props.on_column_filter_submit) {
        this.props.on_column_filter_submit();
      }
    }
  }

  on_clear(event) {
    /**
     * Event handler to clear a column filter
     */
    event.preventDefault();
    const column_key = event.currentTarget.dataset.columnKey;
    if (this.props.on_column_filter_change) {
      this.props.on_column_filter_change(column_key, "");
    }
    // Auto-submit on clear
    if (this.props.on_column_filter_submit) {
      setTimeout(() => {
        this.props.on_column_filter_submit();
      }, 0);
    }
  }

  on_focus(event) {
    /**
     * Event handler when input receives focus
     * Fetches index values if not cached
     */
    const column_key = event.target.dataset.columnKey;
    this.fetch_index_values(column_key);
  }

  fetch_index_values(column_key) {
    /**
     * Fetch unique values for the given column's index
     */
    // Skip if already cached
    const cached = this.get_cached_values(column_key);
    if (cached) {
      // Force re-render to pick up cached values
      this.forceUpdate();
      return;
    }

    // Skip if already loading
    if (this.state.loading_values[column_key]) {
      return;
    }

    // Mark as loading
    const loading = Object.assign({}, this.state.loading_values);
    loading[column_key] = true;
    this.setState({ loading_values: loading });

    // Fetch from API
    if (this.props.api?.fetch_index_values) {
      this.props.api.fetch_index_values({ column_key: column_key })
        .then((data) => {
          // Cache the values at module level
          this.set_cached_values(
            column_key,
            data || { values: [], index_type: null }
          );
          // Update loading state
          const loading = Object.assign({}, this.state.loading_values);
          loading[column_key] = false;
          this.setState({ loading_values: loading });
        })
        .catch((error) => {
          console.error(`Failed to fetch index values for ${column_key}:`, error);
          // Cache empty result to prevent repeated failed requests
          this.set_cached_values(column_key, { values: [], index_type: null });
          const loading = Object.assign({}, this.state.loading_values);
          loading[column_key] = false;
          this.setState({ loading_values: loading });
        });
    }
  }

  render_boolean_filter(key, filter_value) {
    /**
     * Render a Yes/No select for boolean filters
     */
    let btn_cls = "btn btn-outline-secondary";
    if (!filter_value) {
      btn_cls += " invisible";
    }

    return (
      <td className="column-filter-cell" key={`filter_${key}`}>
        <div className="input-group input-group-sm">
          <select
            className="form-control form-control-sm"
            data-column-key={key}
            value={filter_value}
            onChange={this.on_select_change}
          >
            <option value="">{_t("-- Select --")}</option>
            <option value="true">{_t("Yes")}</option>
            <option value="false">{_t("No")}</option>
          </select>
          <div className="input-group-append">
            <button
              type="button"
              className={btn_cls}
              data-column-key={key}
              onClick={this.on_clear}
              title={_t("Clear filter")}
            >
              <i className="fas fa-times"></i>
            </button>
          </div>
        </div>
      </td>
    );
  }

  render_date_filter(key, filter_value) {
    /**
     * Render a date picker for date filters
     */
    let btn_cls = "btn btn-outline-secondary";
    if (!filter_value) {
      btn_cls += " invisible";
    }

    return (
      <td className="column-filter-cell" key={`filter_${key}`}>
        <div className="input-group input-group-sm">
          <input
            type="date"
            className="form-control form-control-sm"
            data-column-key={key}
            value={filter_value}
            onChange={this.on_date_change}
          />
          <div className="input-group-append">
            <button
              type="button"
              className={btn_cls}
              data-column-key={key}
              onClick={this.on_clear}
              title={_t("Clear filter")}
            >
              <i className="fas fa-times"></i>
            </button>
          </div>
        </div>
      </td>
    );
  }

  render_searchable_select_filter(key, filter_value, values) {
    /**
     * Render a searchable select for filters with many values
     */
    const is_loading = this.state.loading_values[key];
    let btn_cls = "btn btn-outline-secondary";
    if (!filter_value) {
      btn_cls += " invisible";
    }

    return (
      <td className="column-filter-cell" key={`filter_${key}`}>
        <div className="input-group input-group-sm">
          <SearchableSelect
            value={filter_value}
            options={values}
            placeholder={is_loading ? _t("Loading...") : _t("Type to filter...")}
            disabled={is_loading}
            onChange={(val) => this.on_searchable_select_change(key, val)}
            onSelect={() => this.on_searchable_select_submit()}
            onSubmit={() => this.on_searchable_select_submit()}
            onFocus={() => this.fetch_index_values(key)}
          />
          <div className="input-group-append">
            <button
              type="button"
              className={btn_cls}
              data-column-key={key}
              onClick={this.on_clear}
              title={_t("Clear filter")}
            >
              <i className="fas fa-times"></i>
            </button>
          </div>
        </div>
      </td>
    );
  }

  render_text_filter(key, filter_value) {
    /**
     * Render a simple text input for filters
     */
    let btn_cls = "btn btn-outline-secondary";
    if (!filter_value) {
      btn_cls += " invisible";
    }

    return (
      <td className="column-filter-cell" key={`filter_${key}`}>
        <div className="input-group input-group-sm">
          <input
            type="text"
            className="form-control form-control-sm"
            data-column-key={key}
            placeholder={_t("Filter...")}
            value={filter_value}
            onChange={this.on_filter_change}
            onKeyDown={this.on_keydown}
          />
          <div className="input-group-append">
            <button
              type="button"
              className={btn_cls}
              data-column-key={key}
              onClick={this.on_clear}
              title={_t("Clear filter")}
            >
              <i className="fas fa-times"></i>
            </button>
          </div>
        </div>
      </td>
    );
  }

  render_filter_input(key) {
    /**
     * Render the appropriate filter input based on index type
     */
    const column = this.props.columns?.[key];
    const index_type = column?.index_type;
    const filter_value = (this.props.column_filters || {})[key] || "";

    // Get cached index values
    const cached = this.get_cached_values(key);
    const values = cached?.values || [];

    // Render based on index type
    switch (index_type) {
      case "BooleanIndex":
        return this.render_boolean_filter(key, filter_value);
      case "DateIndex":
      case "DateRecurringIndex":
        return this.render_date_filter(key, filter_value);
      case "FieldIndex":
      case "KeywordIndex":
        // Use searchable select with autocomplete for these indexes
        return this.render_searchable_select_filter(key, filter_value, values);
      case "ZCTextIndex":
        // Use text input for full-text search indexes
        return this.render_text_filter(key, filter_value);
      default:
        return this.render_text_filter(key, filter_value);
    }
  }

  build_cells() {
    /**
     * Build all filter input cells for the row
     */
    const cells = [];

    // Insert spacer for select column
    if (this.props.show_select_column) {
      cells.push(
        <td className="select-column" key="filter_select"></td>
      );
    }

    // Insert spacer for row dnd column
    if (this.props.allow_row_reorder) {
      cells.push(
        <td className="dnd-column" key="filter_dnd"></td>
      );
    }

    // Insert filter cells for each visible column
    for (const key of this.props.visible_columns) {
      const active_filters = this.props.active_column_filters || [];
      const is_active = active_filters.includes(key);

      // Only show input if this column's filter is active
      if (is_active) {
        cells.push(this.render_filter_input(key));
      } else {
        cells.push(
          <td className="column-filter-cell empty" key={`filter_${key}`}></td>
        );
      }
    }

    return cells;
  }

  render() {
    // Only render if any column filter is active
    const active_filters = this.props.active_column_filters || [];
    if (active_filters.length === 0) {
      return null;
    }

    return (
      <tr className="column-filter-row">
        {this.build_cells()}
      </tr>
    );
  }
}


export default ColumnFilterRow;
