import React from "react";

import Checkbox from "./Checkbox.coffee";
import TableHeaderCell from "./TableHeaderCell.coffee";


class TableHeaderRow extends React.Component {
  /**
   * The table header row component renders a single row with cells
   */

  constructor(props) {
    super(props);
    this.on_header_column_click = this.on_header_column_click.bind(this);
  }

  on_header_column_click(event) {
    /**
     * Event handler when a header columns was clicked
     */
    const el = event.currentTarget;

    const index = el.getAttribute("index");
    let sort_order = el.getAttribute("sort_order");

    if (!index) {
      return;
    }

    console.debug(
      `HEADER CLICKED sort_on='${index}' sort_order=${sort_order}`
    );

    // toggle the sort order if the clicked column was the active one
    if (el.classList.contains("active")) {
      if (sort_order === "ascending") {
        sort_order = "descending";
      } else {
        sort_order = "ascending";
      }
    }

    // call the parent event handler with the sort index and the sort order
    this.props.on_header_column_click(index, sort_order);
  }

  is_required_column(key) {
    /**
     * Check if the column is required
     */

    // XXX This is a workaround for a missing key within the column definition
    const folderitems = this.props.folderitems || [];
    if (folderitems.length === 0) {
      return false;
    }
    const first_item = folderitems[0];
    const required = first_item.required || [];
    return required.includes(key);
  }

  is_sortable(column, key) {
    /**
     * Check if the column is sortable
     */
    if (column.sortable === false) {
      return false;
    }
    if (column.index) {
      return true;
    }
    if (this.props.sortable_columns.includes(key)) {
      return true;
    }
    return false;
  }

  build_cells() {
    /**
     * Build all cells for the row
     */

    const cells = [];

    const checkbox_name = "select_all";
    const checkbox_value = "all";

    // insert select column
    if (this.props.show_select_column) {
      const show_select_all_checkbox = this.props.show_select_all_checkbox;

      cells.push(
        <th className="select-column" key="select_all">
          {show_select_all_checkbox &&
            <Checkbox
              name={checkbox_name}
              value={checkbox_value}
              checked={this.props.all_items_selected}
              onChange={this.props.on_select_checkbox_checked}/>}
        </th>
      );
    }

    // insert row dnd column
    if (this.props.allow_row_reorder) {
      cells.push(
        <th className="dnd-column" key="dnd">
        </th>
      );
    }

    // insert table columns in the right order
    for (const key of this.props.visible_columns) {
      // get the column object
      const column = this.props.columns[key];
      // check if the key is in the sortable columns
      const sortable = this.is_sortable(column, key);
      // sort index
      const index = column.index || key;

      const title = column.title;
      const alt = column.alt || title;
      // sort_on is the current sort index/metadata
      const sort_on = this.props.sort_on || "created";
      const sort_order = this.props.sort_order || "ascending";
      // check if the current sort_on is the index of this column
      const is_sort_column = index === sort_on;
      // check if the column is required
      const required = this.is_required_column(key);

      const cls = [key];
      if (sortable) {
        cls.push("sortable");
      }
      if (is_sort_column && sortable) {
        cls.push("active " + sort_order);
      }
      if (required) {
        cls.push("required");
      }

      cells.push(
        <TableHeaderCell
          key={key}
          {...this.props}
          column_key={key}
          title={title}
          alt={alt}
          index={index}
          sort_order={sort_order}
          className={cls.join(" ")}
          onClick={sortable ? this.on_header_column_click : undefined}
          />
      );
    }

    return cells;
  }

  render() {
    return (
      <tr onContextMenu={this.props.on_context_menu}>
        {this.build_cells()}
      </tr>
    );
  }
}


export default TableHeaderRow;
