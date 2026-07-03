import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import SearchableSelect from "./SearchableSelect.js";


// Index types that have a finite list of meaningful values; only
// fetch index values for these.
const SELECTABLE_INDEX_TYPES = ["FieldIndex", "KeywordIndex"];


// Module-level cache for index values, scoped by listing context so a
// FilterBar (review_state) change or a different combination of other
// column filters invalidates entries automatically.
//
//   Structure: { cache_key: { column_key: { values, index_type } } }
//
const INDEX_VALUES_CACHE = {};


/**
 * Key-order-independent JSON used to derive a stable cache key from
 * the {form_id, review_state, other_column_filters} tuple.
 */
function stable_stringify(value) {
  if (value === null || typeof value !== "object") {
    return JSON.stringify(value);
  }
  if (Array.isArray(value)) {
    return "[" + value.map(stable_stringify).join(",") + "]";
  }
  const keys = Object.keys(value).sort();
  return "{" + keys.map(
    (k) => JSON.stringify(k) + ":" + stable_stringify(value[k])
  ).join(",") + "}";
}


/**
 * Build a cache key for a column's unique-value list. The column
 * being computed is excluded from the signature so it doesn't narrow
 * its own value list.
 */
function build_cache_key(form_id, review_state, column_filters, exclude_column) {
  const filters = { ...(column_filters || {}) };
  if (exclude_column) delete filters[exclude_column];
  const signature = {};
  for (const key of Object.keys(filters)) {
    const value = filters[key];
    if (value !== "" && value != null) signature[key] = value;
  }
  return (form_id || "default")
    + "|" + (review_state || "")
    + "|" + stable_stringify(signature);
}


/**
 * Editor row that appears below the column headers when at least one
 * column filter is active. Each cell renders an input appropriate for
 * the column's catalog index type:
 *
 *   BooleanIndex                  → Yes/No select
 *   DateIndex, DateRecurringIndex → <input type="date">
 *   FieldIndex, KeywordIndex      → SearchableSelect (autocomplete)
 *   anything else                 → free-text input
 */
function ColumnFilterRow(props) {
  const {
    form_id,
    review_state,
    column_filters,
    active_column_filters,
    columns,
    visible_columns,
    show_select_column,
    allow_row_reorder,
    api,
    on_column_filter_change,
    on_column_filter_submit,
  } = props;

  // Map column_key → bool while a fetch is in flight.
  const [loading_values, set_loading_values] = useState({});
  // Mirror in a ref so `fetch_index_values` can read it without
  // listing `loading_values` in its dep array (see comment on the
  // useCallback below).
  const loading_values_ref = useRef(loading_values);
  loading_values_ref.current = loading_values;

  // Use a ref to force re-render when we hit a fresh cache slot.
  const [, force_render] = useState(0);
  const bump_render = useCallback(() => force_render((n) => n + 1), []);

  // ---------- cache helpers ----------

  const cache_key_for = useCallback((column_key) => build_cache_key(
    form_id, review_state, column_filters, column_key),
  [form_id, review_state, column_filters]);

  const get_cached = useCallback((column_key) => {
    const bucket = INDEX_VALUES_CACHE[cache_key_for(column_key)];
    return (bucket && bucket[column_key]) || null;
  }, [cache_key_for]);

  const set_cached = useCallback((column_key, data) => {
    const key = cache_key_for(column_key);
    if (!INDEX_VALUES_CACHE[key]) INDEX_VALUES_CACHE[key] = {};
    INDEX_VALUES_CACHE[key][column_key] = data;
  }, [cache_key_for]);

  // ---------- async fetch ----------

  const set_loading = useCallback((column_key, is_loading) => {
    set_loading_values((prev) => ({ ...prev, [column_key]: is_loading }));
  }, []);

  // The in-flight guard reads the loading map through a ref so it
  // does not need to live in the deps array. Putting `loading_values`
  // in deps means every `set_loading` recreates this callback, which
  // in turn recreates `onFocus={() => fetch_index_values(key)}` on
  // every SearchableSelect for every keystroke that toggles loading.
  const fetch_index_values = useCallback((column_key, opts) => {
    if (get_cached(column_key)) {
      // bump_render() is only useful when the call originates outside
      // a render cycle (e.g. an onFocus handler on SearchableSelect),
      // because the module-level cache is invisible to React.
      // Inside an effect we are already in a commit phase so the next
      // render will pick up the cached values naturally.
      if (opts?.bump !== false) bump_render();
      return;
    }
    if (loading_values_ref.current[column_key]) return;
    if (!api || typeof api.fetch_index_values !== "function") return;

    set_loading(column_key, true);
    // Call via api.fetch_index_values(...) so the method keeps its
    // receiver — extracting it into a local variable would detach
    // `this` and break the api's internal helpers (get_json).
    api.fetch_index_values({ column_key })
      .then((data) => {
        set_cached(column_key, data || { values: [], index_type: null });
        set_loading(column_key, false);
      })
      .catch((error) => {
        console.error(
          `Failed to fetch index values for ${column_key}:`, error);
        // Cache empty result so we don't hammer the endpoint on retry.
        set_cached(column_key, { values: [], index_type: null });
        set_loading(column_key, false);
      });
  }, [api, get_cached, set_cached, set_loading, bump_render]);

  const fetch_active_filter_values = useCallback(() => {
    for (const key of active_column_filters || []) {
      const column = columns?.[key];
      if (SELECTABLE_INDEX_TYPES.includes(column?.index_type)) {
        // Called from the context-shift effect; we are already
        // committing, so skip the redundant bump_render on cache hits.
        fetch_index_values(key, { bump: false });
      }
    }
  }, [active_column_filters, columns, fetch_index_values]);

  // ---------- mount + context-change effect ----------

  // Initial fetch on mount.
  useEffect(() => {
    fetch_active_filter_values();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Track previous review_state + column_filters to detect context shifts.
  const prev_review_ref = useRef(review_state);
  const prev_filters_sig_ref = useRef(stable_stringify(column_filters || {}));
  const prev_active_ref = useRef(active_column_filters || []);

  // Keep helpers accessible to the effect via refs so the effect can
  // omit them from its dependency array — otherwise every useCallback
  // recreation would re-run the effect even when nothing observable
  // has changed. (`loading_values_ref` is established at the top of
  // the component so the fetch callback can share it.)
  const fetch_active_filter_values_ref = useRef(fetch_active_filter_values);
  fetch_active_filter_values_ref.current = fetch_active_filter_values;

  // Precompute the column_filters signature once per render and reuse.
  const column_filters_sig = useMemo(
    () => stable_stringify(column_filters || {}),
    [column_filters]);

  useEffect(() => {
    const prev_active = prev_active_ref.current;
    const curr_active = active_column_filters || [];
    const new_filters_added = curr_active.some(
      (f) => !prev_active.includes(f));
    const review_changed = prev_review_ref.current !== review_state;
    const filters_changed = prev_filters_sig_ref.current !== column_filters_sig;

    prev_review_ref.current = review_state;
    prev_filters_sig_ref.current = column_filters_sig;
    prev_active_ref.current = curr_active;

    if (!(new_filters_added || review_changed || filters_changed)) return;

    // Discard stale in-flight markers; any pending response now
    // belongs to the previous context and must not block a refetch.
    if ((review_changed || filters_changed)
        && Object.keys(loading_values_ref.current).length > 0) {
      set_loading_values({});
    }
    fetch_active_filter_values_ref.current();
  }, [review_state, column_filters_sig, active_column_filters]);

  // ---------- input event helpers ----------

  const notify_change = useCallback((column_key, value) => {
    on_column_filter_change && on_column_filter_change(column_key, value);
  }, [on_column_filter_change]);

  const submit_soon = useCallback(() => {
    // setTimeout 0 so React commits the change handler's setState
    // before the parent acts on the (now-stale) state.
    on_column_filter_submit
      && setTimeout(() => on_column_filter_submit(), 0);
  }, [on_column_filter_submit]);

  const on_text_change = useCallback((event) => {
    notify_change(event.target.dataset.columnKey, event.target.value);
  }, [notify_change]);

  const on_select_change = useCallback((event) => {
    notify_change(event.target.dataset.columnKey, event.target.value);
    submit_soon();
  }, [notify_change, submit_soon]);

  const on_date_change = useCallback((event) => {
    // Date inputs submit on blur (and on Enter), not on every change.
    // The native date picker fires onChange for each spinner click,
    // which would otherwise trigger one refetch per click and show an
    // empty table for the intermediate values.
    notify_change(event.target.dataset.columnKey, event.target.value);
  }, [notify_change]);

  const on_date_blur = useCallback(() => {
    submit_soon();
  }, [submit_soon]);

  const on_keydown = useCallback((event) => {
    if (event.key === "Enter") {
      on_column_filter_submit && on_column_filter_submit();
    }
  }, [on_column_filter_submit]);

  const on_clear = useCallback((event) => {
    event.preventDefault();
    notify_change(event.currentTarget.dataset.columnKey, "");
    submit_soon();
  }, [notify_change, submit_soon]);

  // ---------- per-cell rendering ----------

  /**
   * Wrap any input in the standard filter-cell shell:
   * input-group containing the input and a clear (×) button.
   */
  const render_filter_cell = (key, filter_value, input) => {
    const btn_cls = "btn btn-outline-secondary" +
      (filter_value ? "" : " invisible");
    return (
      <td className="column-filter-cell" key={`filter_${key}`}>
        <div className="input-group input-group-sm">
          {input}
          <div className="input-group-append">
            <button
              type="button"
              className={btn_cls}
              data-column-key={key}
              onClick={on_clear}
              title={_t("Clear filter")}
            >
              <i className="fas fa-times"></i>
            </button>
          </div>
        </div>
      </td>
    );
  };

  const render_input_for = (key, index_type, filter_value) => {
    switch (index_type) {
      case "BooleanIndex":
        return (
          <select
            className="form-control form-control-sm"
            data-column-key={key}
            value={filter_value}
            onChange={on_select_change}
          >
            <option value="">{_t("-- Select --")}</option>
            <option value="true">{_t("Yes")}</option>
            <option value="false">{_t("No")}</option>
          </select>
        );
      case "DateIndex":
      case "DateRecurringIndex":
        return (
          <input
            type="date"
            className="form-control form-control-sm"
            data-column-key={key}
            value={filter_value}
            onChange={on_date_change}
            onBlur={on_date_blur}
            onKeyDown={on_keydown}
          />
        );
      case "FieldIndex":
      case "KeywordIndex": {
        const is_loading = loading_values[key];
        const values = get_cached(key)?.values || [];
        return (
          <SearchableSelect
            value={filter_value}
            options={values}
            placeholder={is_loading
              ? _t("Loading...")
              : _t("Type to filter...")}
            disabled={is_loading}
            onChange={(val) => notify_change(key, val)}
            onSelect={submit_soon}
            onSubmit={submit_soon}
            onFocus={() => fetch_index_values(key)}
          />
        );
      }
      default:
        return (
          <input
            type="text"
            className="form-control form-control-sm"
            data-column-key={key}
            placeholder={_t("Filter...")}
            value={filter_value}
            onChange={on_text_change}
            onKeyDown={on_keydown}
          />
        );
    }
  };

  const render_filter_input = (key) => {
    const column = columns?.[key];
    const index_type = column?.index_type;
    const filter_value = (column_filters || {})[key] || "";
    const input = render_input_for(key, index_type, filter_value);
    return render_filter_cell(key, filter_value, input);
  };

  // ---------- row assembly ----------

  const active = active_column_filters || [];
  if (active.length === 0) return null;

  const cells = [];
  if (show_select_column) {
    cells.push(<td className="select-column" key="filter_select"></td>);
  }
  if (allow_row_reorder) {
    cells.push(<td className="dnd-column" key="filter_dnd"></td>);
  }
  for (const key of visible_columns) {
    if (active.includes(key)) {
      cells.push(render_filter_input(key));
    } else {
      cells.push(
        <td className="column-filter-cell empty" key={`filter_${key}`}></td>
      );
    }
  }

  return <tr className="column-filter-row">{cells}</tr>;
}


export default ColumnFilterRow;
