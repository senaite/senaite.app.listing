import React, { useCallback } from "react";


// Columns excluded from filtering by default — they have an index but
// filtering them doesn't make sense for the user.  A column can opt
// back in by setting `filter: true` in its server-side config.
const FILTER_EXCLUDED_COLUMNS = [
  "Progress",
  "progress",
  "getProgress",
  "Priority",
];


function is_filterable(props) {
  const column = (props.columns && props.columns[props.column_key]) || {};
  if (column.filter === false) return false;
  if (FILTER_EXCLUDED_COLUMNS.includes(props.column_key)
      && column.filter !== true) return false;
  if (column.index == null) return false;
  return true;
}


function TableHeaderCell(props) {
  const {
    column_key,
    columns,
    title,
    alt,
    index,
    sort_on,
    sort_order,
    className,
    onClick,
    on_sort_click,
    on_filter_toggle,
    active_column_filters,
    column_filters,
    draggable,
    outer_ref,
  } = props;

  const on_filter_toggle_click = useCallback((event) => {
    event.stopPropagation();
    if (on_filter_toggle) on_filter_toggle(column_key);
  }, [on_filter_toggle, column_key]);

  const on_sort_asc = useCallback((event) => {
    event.stopPropagation();
    event.preventDefault();
    if (on_sort_click && index) on_sort_click(index, "ascending");
  }, [on_sort_click, index]);

  const on_sort_desc = useCallback((event) => {
    event.stopPropagation();
    event.preventDefault();
    if (on_sort_click && index) on_sort_click(index, "descending");
  }, [on_sort_click, index]);

  const show_filter_button = is_filterable({ column_key, columns });

  // The funnel turns "active" whenever the editor cell is open OR the
  // column already carries a filter value (set manually or via a
  // preset).  This way the user sees which columns are filtered even
  // when the editor cells are closed.
  const is_editor_open = (active_column_filters || []).includes(column_key);
  const filters_map = column_filters || {};
  const has_filter_value = !!filters_map[column_key];
  const is_filter_active = is_editor_open || has_filter_value;

  const filter_btn_cls = [
    "btn", "btn-link", "btn-sm", "column-filter-toggle",
  ];
  if (is_filter_active) filter_btn_cls.push("active");

  const sortable = !!className
    && className.split(" ").includes("sortable");
  const is_sort_column = sortable && index === sort_on;
  const asc_active = is_sort_column && sort_order === "ascending";
  const desc_active = is_sort_column && sort_order === "descending";

  const asc_cls = ["column-sort-arrow", "column-sort-asc"];
  if (asc_active) asc_cls.push("active");
  const desc_cls = ["column-sort-arrow", "column-sort-desc"];
  if (desc_active) desc_cls.push("active");

  const has_controls = sortable || show_filter_button || draggable;

  return (
    <th
      title={alt}
      ref={outer_ref}
      index={index}
      sort_order={sort_order}
      className={className}
      onClick={onClick}
    >
      <div className="column-header-inner">
        {/*
          Column titles can carry HTML markup (e.g. an <img> for an
          icon-only header like "Retested", or <sub>/<sup> for unit
          labels). Titles come from server-side view.py config — not
          user input — so the trust class matches ReadonlyField etc.
          which already render via dangerouslySetInnerHTML.
        */}
        <span
          className="column-title"
          dangerouslySetInnerHTML={{ __html: title }}
        />
        {has_controls && (
          <span className="column-header-controls">
            {sortable && (
              <span className="column-sort-arrows">
                <button
                  type="button"
                  className={asc_cls.join(" ")}
                  onClick={on_sort_asc}
                  title={_t("Sort ascending")}
                  aria-label={_t("Sort ascending")}
                >
                  <i className="fas fa-chevron-up"></i>
                </button>
                <button
                  type="button"
                  className={desc_cls.join(" ")}
                  onClick={on_sort_desc}
                  title={_t("Sort descending")}
                  aria-label={_t("Sort descending")}
                >
                  <i className="fas fa-chevron-down"></i>
                </button>
              </span>
            )}
            {show_filter_button && (
              <button
                type="button"
                className={filter_btn_cls.join(" ")}
                onClick={on_filter_toggle_click}
                title={_t("Toggle column filter")}
              >
                <i className="fas fa-filter"></i>
              </button>
            )}
            {/*
              Drag affordance sits at the trailing edge of the controls
              cluster, right of the funnel.  Hidden by default; the
              parent <th>:hover reveals it (see listing.css).  The <th>
              itself is the drag source — this is purely the cue.
            */}
            {draggable && (
              <span
                className="column-drag-handle"
                aria-hidden="true"
                title={_t("Drag to reorder")}
              >
                <i className="fas fa-grip-vertical"></i>
              </span>
            )}
          </span>
        )}
      </div>
    </th>
  );
}


// Memo keeps a 20-column header from re-rendering every cell on every
// parent state change.  The parent passes the full `{...props}`
// spread, so a naive shallow memo would never hit — we hand-pick the
// props that actually drive output.
function arePropsEqual(prev, next) {
  const key = next.column_key;
  if (prev.column_key !== key) return false;
  if (prev.title !== next.title) return false;
  if (prev.alt !== next.alt) return false;
  if (prev.index !== next.index) return false;
  if (prev.className !== next.className) return false;
  if (prev.onClick !== next.onClick) return false;
  if (prev.on_sort_click !== next.on_sort_click) return false;
  if (prev.on_filter_toggle !== next.on_filter_toggle) return false;
  // `outer_ref` is a stable useRef object and the `draggable` /
  // is-dragging / is-drop-* signals already flow through `className`,
  // so the ref itself is excluded from the comparator on purpose.
  if (prev.draggable !== next.draggable) return false;
  if (prev.sort_on !== next.sort_on) return false;
  if (prev.sort_order !== next.sort_order) return false;
  // Filter state only matters for this column's own slot.
  const prev_active = prev.active_column_filters || [];
  const next_active = next.active_column_filters || [];
  if (prev_active.includes(key) !== next_active.includes(key)) return false;
  const prev_value = (prev.column_filters || {})[key] || "";
  const next_value = (next.column_filters || {})[key] || "";
  if (prev_value !== next_value) return false;
  // Column definition is static unless the listing reconfigures.
  const prev_col = prev.columns && prev.columns[key];
  const next_col = next.columns && next.columns[key];
  if (prev_col !== next_col) return false;
  return true;
}


export default React.memo(TableHeaderCell, arePropsEqual);
