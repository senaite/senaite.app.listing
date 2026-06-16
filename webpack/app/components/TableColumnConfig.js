import React, {
  useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState,
} from "react";
import ReactDOM from "react-dom";


// Column visibility helper: parity with the legacy is_column_visible —
// a missing `toggle` defaults to visible.
function is_visible(column) {
  return column && column.toggle !== false;
}


function column_label(column, key) {
  return (column && column.title) || key;
}


function matches_search(key, column, needle) {
  if (!needle) return true;
  const title = String(column_label(column, key)).toLowerCase();
  return title.indexOf(needle) > -1
    || key.toLowerCase().indexOf(needle) > -1;
}


/**
 * Column configuration panel. Two sections — visible (ordered, reorder
 * by drag handle) and hidden (flat, restore with one click) — sharing
 * a search input and a counter at the top.
 *
 * Props (unchanged from the legacy CoffeeScript component):
 *   id, className, title, description
 *   columns                  {key: {title, toggle, ...}}
 *   columns_order            [key]
 *   on_column_toggle_click   (key) → void; receives "reset" for the
 *                            reset-to-defaults action
 *   on_columns_order_change  ([key]) → void
 */
function TableColumnConfig(props) {
  const {
    id, className, title, description,
    columns, columns_order,
    on_column_toggle_click, on_columns_order_change,
    anchor_ref, on_request_close,
  } = props;

  // Live position + width of the popover. Computed from the anchor's
  // bounding rect (the `⋯` trigger in the toolbar). Stored in state
  // so resize/scroll re-render in the new place.
  const [pos, set_pos] = useState({ top: 0, left: 0, width: 320 });
  const panel_ref = useRef(null);

  const update_position = useCallback(() => {
    const el = anchor_ref && anchor_ref.current;
    if (!el) return;
    const rect = el.getBoundingClientRect();
    // Width: never wider than ~32rem, never wider than viewport - 16px.
    const max_w = Math.min(window.innerWidth - 16, 512);
    const min_w = Math.min(max_w, 280);
    const width = Math.max(min_w, max_w);
    // Left-align the panel with the trigger so the popover opens
    // rightward from the `⋯` icon, then clamp so it always sits
    // fully inside the viewport.
    const desired_left = rect.left;
    const left = Math.max(
      8, Math.min(desired_left, window.innerWidth - width - 8));
    // Drop below the trigger, but if that would push it past the
    // bottom of the viewport, anchor above instead.
    let top = rect.bottom + 6;
    if (top + 200 > window.innerHeight) {
      // best-effort: open above
      top = Math.max(8, rect.top - 6 - 200);
    }
    set_pos({ top: Math.round(top), left: Math.round(left), width });
  }, [anchor_ref]);

  useLayoutEffect(() => {
    update_position();
  }, [update_position]);

  useEffect(() => {
    const on_resize = () => update_position();
    // Capture-phase scroll so we catch scroll events on inner
    // containers (e.g. `.table-responsive`), not just the window.
    window.addEventListener("resize", on_resize);
    window.addEventListener("scroll", on_resize, true);
    return () => {
      window.removeEventListener("resize", on_resize);
      window.removeEventListener("scroll", on_resize, true);
    };
  }, [update_position]);

  // Close on outside click — but ignore clicks on the anchor itself
  // since those are the open/close toggle.
  useEffect(() => {
    if (!on_request_close) return undefined;
    const on_doc_click = (event) => {
      const panel = panel_ref.current;
      const anchor = anchor_ref && anchor_ref.current;
      const t = event.target;
      if (panel && panel.contains(t)) return;
      if (anchor && anchor.contains(t)) return;
      on_request_close();
    };
    // mousedown so we react before the click resolves on the table
    document.addEventListener("mousedown", on_doc_click);
    return () => document.removeEventListener("mousedown", on_doc_click);
  }, [anchor_ref, on_request_close]);

  // Close on Esc.
  useEffect(() => {
    if (!on_request_close) return undefined;
    const on_key = (event) => {
      if (event.key === "Escape") on_request_close();
    };
    document.addEventListener("keydown", on_key);
    return () => document.removeEventListener("keydown", on_key);
  }, [on_request_close]);

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
    on_column_toggle_click && on_column_toggle_click("reset");
  }, [on_column_toggle_click]);

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
