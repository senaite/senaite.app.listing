import React, {
  useCallback, useEffect, useMemo, useRef, useState,
} from "react";
import ReactDOM from "react-dom";

import usePopoverPosition from "../hooks/usePopoverPosition.js";
import useDismissOn from "../hooks/useDismissOn.js";


// A column is visible unless its `toggle` flag is explicitly false.
const is_visible = (column) => !!column && column.toggle !== false;

// Display label for a column row; falls back to the key when the
// server-supplied title is empty.
const column_label = (column, key) =>
  (column && column.title) || key;

const matches_search = (key, column, needle) => {
  if (!needle) return true;
  const title = String(column_label(column, key)).toLowerCase();
  return title.indexOf(needle) > -1
    || key.toLowerCase().indexOf(needle) > -1;
};


/**
 * Column configuration panel. Two sections — visible (ordered, reorder
 * by drag handle) and hidden (flat, restore with one click) — sharing
 * a search input and a counter at the top.
 *
 * Props:
 *   id, className, title, description
 *   columns                  {key: {title, toggle, ...}}
 *   columns_order            [key]
 *   on_column_toggle_click   (key) → void
 *   on_columns_order_change  ([key]) → void
 *   on_reset                 () → void; optional, falls back to a
 *                            no-op (the popover hides the button)
 *   anchor_ref               React ref of the trigger element
 *   on_request_close         () → void; popover dismiss
 */
function TableColumnConfig(props) {
  const {
    id, className, title, description,
    columns, columns_order,
    on_column_toggle_click, on_columns_order_change, on_reset,
    anchor_ref, on_request_close,
  } = props;

  const panel_ref = useRef(null);
  const pos = usePopoverPosition(anchor_ref);
  useDismissOn({
    when: !!on_request_close,
    on_dismiss: on_request_close,
    panel_ref,
    ignore_refs: [anchor_ref],
  });

  // Local order so drag operations are smooth; sync with the parent
  // both ways.
  const [order, set_order] = useState(columns_order);
  useEffect(() => set_order(columns_order), [columns_order]);

  const [search, set_search] = useState("");
  const needle = search.trim().toLowerCase();

  // Drag state: which key the user is dragging, and where (above/below
  // which key) the drop will land. Both live in component state so the
  // drop indicator renders deterministically.
  const [drag_key, set_drag_key] = useState(null);
  const [drop_target, set_drop_target] = useState(null);
  // Suppress the click that fires when a drag completes on the handle.
  const just_dragged_ref = useRef(false);

  // ---------- derived lists ----------

  const visible_keys = useMemo(
    () => order.filter((k) => is_visible(columns[k])),
    [order, columns]);

  // Hidden columns, sorted alphabetically by label so the user can find
  // a specific one quickly (the hidden section has no meaningful order).
  const hidden_keys = useMemo(() => {
    const keys = order.filter((k) => !is_visible(columns[k]));
    return keys.sort((a, b) => {
      const la = String(column_label(columns[a], a)).toLowerCase();
      const lb = String(column_label(columns[b], b)).toLowerCase();
      return la.localeCompare(lb);
    });
  }, [order, columns]);

  const filtered_visible = useMemo(
    () => visible_keys.filter((k) => matches_search(k, columns[k], needle)),
    [visible_keys, columns, needle]);
  const filtered_hidden = useMemo(
    () => hidden_keys.filter((k) => matches_search(k, columns[k], needle)),
    [hidden_keys, columns, needle]);

  const total = order.length;
  const visible_count = visible_keys.length;

  // ---------- toggle / bulk ----------

  const toggle = useCallback((key) => {
    on_column_toggle_click && on_column_toggle_click(key);
  }, [on_column_toggle_click]);

  const set_all_visibility = useCallback((target_visible) => {
    if (!on_column_toggle_click) return;
    for (const key of order) {
      const visible = is_visible(columns[key]);
      if (visible !== target_visible) on_column_toggle_click(key);
    }
  }, [on_column_toggle_click, order, columns]);

  const reset = useCallback(() => {
    on_reset && on_reset();
  }, [on_reset]);
  const can_reset = typeof on_reset === "function";

  // ---------- drag & drop ----------

  const on_drag_start = useCallback((event, key) => {
    set_drag_key(key);
    event.dataTransfer.effectAllowed = "move";
    // Required for Firefox to actually start the drag.
    event.dataTransfer.setData("text/plain", key);
    // Use the row (the handle's parent <li>) as the drag image so the
    // user sees the whole row hovering.
    const row = event.currentTarget.closest(".tcc-row");
    if (row) event.dataTransfer.setDragImage(row, 14, 14);
  }, []);

  const on_drag_over_row = useCallback((event, key) => {
    if (!drag_key || drag_key === key) return;
    event.preventDefault();
    event.dataTransfer.dropEffect = "move";
    const rect = event.currentTarget.getBoundingClientRect();
    const where = (event.clientY - rect.top) < rect.height / 2
      ? "above" : "below";
    set_drop_target((prev) =>
      (prev && prev.key === key && prev.where === where)
        ? prev
        : { key, where });
  }, [drag_key]);

  const on_drop_row = useCallback((event, key) => {
    event.preventDefault();
    if (!drag_key || drag_key === key) {
      set_drag_key(null);
      set_drop_target(null);
      return;
    }
    const where = drop_target?.key === key ? drop_target.where : "below";
    const next = order.filter((k) => k !== drag_key);
    const target_idx = next.indexOf(key);
    const insert_at = where === "above" ? target_idx : target_idx + 1;
    next.splice(insert_at, 0, drag_key);

    set_order(next);
    set_drag_key(null);
    set_drop_target(null);
    just_dragged_ref.current = true;
    setTimeout(() => { just_dragged_ref.current = false; }, 0);
    on_columns_order_change && on_columns_order_change(next);
  }, [drag_key, drop_target, order, on_columns_order_change]);

  const on_drag_end = useCallback(() => {
    set_drag_key(null);
    set_drop_target(null);
  }, []);

  // ---------- rendering ----------

  const panel = (
    <div
      ref={panel_ref}
      id={id}
      className={`tcc-panel ${className || ""}`.trim()}
      style={{
        top: `${pos.top}px`,
        left: `${pos.left}px`,
        width: `${pos.width}px`,
      }}
    >
      <Header
        title={title}
        description={description}
        visible_count={visible_count}
        total={total}
        search={search}
        on_search_change={set_search}
        on_show_all={() => set_all_visibility(true)}
        on_hide_all={() => set_all_visibility(false)}
        has_visible={visible_count > 0}
        has_hidden={visible_count < total}
      />

      <div className="tcc-body">
        <Section
          label={_t("Visible")}
          empty_label={needle
            ? _t("No matches in visible columns.")
            : _t("All columns are hidden.")}
        >
          {filtered_visible.map((key) => (
            <VisibleRow
              key={key}
              column_key={key}
              column={columns[key]}
              is_dragging={drag_key === key}
              drop_target={drop_target?.key === key ? drop_target.where : null}
              on_drag_start={on_drag_start}
              on_drag_over={on_drag_over_row}
              on_drop={on_drop_row}
              on_drag_end={on_drag_end}
              on_hide={toggle}
              just_dragged_ref={just_dragged_ref}
            />
          ))}
        </Section>

        {hidden_keys.length > 0 && (
          <Section
            label={_t("Hidden")}
            count={`${hidden_keys.length}`}
            muted
            empty_label={needle ? _t("No matches in hidden columns.") : null}
          >
            {filtered_hidden.map((key) => (
              <HiddenRow
                key={key}
                column_key={key}
                column={columns[key]}
                on_show={toggle}
              />
            ))}
          </Section>
        )}
      </div>

      {can_reset && (
        <div className="tcc-footer">
          <button
            type="button"
            className="tcc-reset"
            onClick={reset}
            title={_t("Reset to default columns and order")}>
            <i className="fas fa-rotate-left"></i>
            <span>{_t("Reset columns")}</span>
          </button>
        </div>
      )}
    </div>
  );

  // Portal to document.body so the panel escapes any parent overflow
  // / stacking context (the column-config trigger lives inside
  // .col-sm-12.table-responsive, whose overflow-x would otherwise clip).
  return ReactDOM.createPortal(panel, document.body);
}


// ---------- presentational sub-components ----------

function Header(props) {
  const {
    title, description,
    visible_count, total,
    search, on_search_change,
    on_show_all, on_hide_all,
    has_visible, has_hidden,
  } = props;
  return (
    <div className="tcc-header">
      <div className="tcc-header-top">
        <div className="tcc-title-block">
          <strong className="tcc-title">{title}</strong>
          {description && (
            <span className="tcc-description">{description}</span>
          )}
        </div>
        <span className="tcc-counter" title={_t("Visible / total columns")}>
          {visible_count}<span className="tcc-counter-sep">/</span>{total}
        </span>
      </div>
      <div className="tcc-header-tools">
        <div className="input-group input-group-sm tcc-search">
          <div className="input-group-prepend">
            <span className="input-group-text">
              <i className="fas fa-search"></i>
            </span>
          </div>
          <input
            type="text"
            className="form-control"
            placeholder={_t("Search columns…")}
            value={search}
            onChange={(e) => on_search_change(e.target.value)}
            autoFocus
          />
          {search && (
            <div className="input-group-append">
              <button
                type="button"
                className="btn btn-outline-secondary"
                onClick={() => on_search_change("")}
                title={_t("Clear search")}>
                <i className="fas fa-times"></i>
              </button>
            </div>
          )}
        </div>
        <div className="tcc-bulk">
          <button
            type="button"
            className="btn btn-sm btn-outline-secondary"
            onClick={on_show_all}
            disabled={!has_hidden}>
            {_t("Show all")}
          </button>
          <button
            type="button"
            className="btn btn-sm btn-outline-secondary"
            onClick={on_hide_all}
            disabled={!has_visible}>
            {_t("Hide all")}
          </button>
        </div>
      </div>
    </div>
  );
}


function Section(props) {
  const { label, count, muted, empty_label, children } = props;
  const rows = React.Children.toArray(children);
  return (
    <div className={"tcc-section" + (muted ? " is-muted" : "")}>
      <div className="tcc-section-header">
        <span className="tcc-section-label">{label}</span>
        {count && <span className="tcc-section-count">{count}</span>}
      </div>
      {rows.length > 0 ? (
        <ul className="tcc-list">{rows}</ul>
      ) : (
        empty_label && (
          <div className="tcc-empty">{empty_label}</div>
        )
      )}
    </div>
  );
}


function VisibleRow(props) {
  const {
    column_key, column,
    is_dragging, drop_target,
    on_drag_start, on_drag_over, on_drop, on_drag_end,
    on_hide, just_dragged_ref,
  } = props;
  const row_cls = "tcc-row"
    + (is_dragging ? " is-dragging" : "")
    + (drop_target === "above" ? " is-drop-above" : "")
    + (drop_target === "below" ? " is-drop-below" : "");
  return (
    <li
      className={row_cls}
      data-column-key={column_key}
      onDragOver={(e) => on_drag_over(e, column_key)}
      onDrop={(e) => on_drop(e, column_key)}
    >
      <button
        type="button"
        className="tcc-handle"
        draggable
        onDragStart={(e) => on_drag_start(e, column_key)}
        onDragEnd={on_drag_end}
        title={_t("Drag to reorder")}
        aria-label={_t("Drag to reorder")}>
        <i className="fas fa-grip-vertical"></i>
      </button>
      <span className="tcc-label">
        {column_label(column, column_key)}
      </span>
      <button
        type="button"
        className="tcc-hide"
        onClick={() => {
          // A drop that ends on the same row would otherwise fire a
          // click — guard against it.
          if (just_dragged_ref.current) return;
          on_hide(column_key);
        }}
        title={_t("Hide this column")}
        aria-label={_t("Hide this column")}>
        <i className="fas fa-eye-slash"></i>
      </button>
    </li>
  );
}


function HiddenRow(props) {
  const { column_key, column, on_show } = props;
  return (
    <li className="tcc-row is-hidden-row">
      <span className="tcc-handle is-placeholder" aria-hidden="true"></span>
      <span className="tcc-label">
        {column_label(column, column_key)}
      </span>
      <button
        type="button"
        className="tcc-show"
        onClick={() => on_show(column_key)}
        title={_t("Show this column")}
        aria-label={_t("Show this column")}>
        <i className="fas fa-plus"></i>
      </button>
    </li>
  );
}


export default TableColumnConfig;
