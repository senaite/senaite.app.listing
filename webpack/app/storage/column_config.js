/**
 * Per-listing column-config storage + merge helpers.
 *
 * A column config is a list of `{key, toggle}` records — order is
 * meaningful (it is the user's chosen column order), `toggle` is the
 * visibility flag (default true).
 *
 * Storage is per `listing_identifier` (same scoping as the saved
 * presets) so different listing kinds keep independent configs.
 *
 * The module is intentionally pure data: no React, no controller
 * state.  This makes `merge_column_config` straightforward to reason
 * about and easy to unit-test from outside.
 */


const STORAGE_PREFIX = "columns-";


function storage_key(storage_id) {
  return STORAGE_PREFIX + (storage_id || "default");
}


export function read_column_config(storage_id) {
  try {
    const raw = window.localStorage.getItem(storage_key(storage_id));
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch (error) {
    console.warn("column_config: failed to read config", error);
    return [];
  }
}


export function write_column_config(storage_id, config) {
  try {
    window.localStorage.setItem(
      storage_key(storage_id), JSON.stringify(config));
    return true;
  } catch (error) {
    console.warn("column_config: failed to write config", error);
    return false;
  }
}


export function clear_column_config(storage_id) {
  try {
    window.localStorage.removeItem(storage_key(storage_id));
    return true;
  } catch (error) {
    console.warn("column_config: failed to clear config", error);
    return false;
  }
}


/**
 * Reconcile a stored column config with the current server-defined
 * columns. Three things happen here, in order:
 *
 *   1. Drop entries whose key no longer exists server-side.
 *      Add-on packages that remove columns no longer leave dead
 *      entries floating in the user's config.
 *
 *   2. Walk the server keys and APPEND any that are missing from the
 *      stored config, defaulting them to `toggle: true` (visible).
 *      This is what makes new add-on columns auto-visible without
 *      the user having to hit "Reset columns".
 *
 *   3. Preserve the user's chosen order for keys that already lived
 *      in the stored config.
 *
 * `allowed_keys`, if provided, limits the result to keys the current
 * review_state declares as allowed; unknown keys are dropped.
 *
 * `server_columns` may be either:
 *   - an Array of keys (legacy): all newly-appended entries default to
 *     `toggle: true` because no server-side default is available
 *   - an Object dict `{key: {toggle, ...}}`: the server's per-column
 *     `toggle` value is honored when appending NEW entries, so columns
 *     the server marks hidden stay hidden on first render.
 *
 * Stored entries always win for keys already in the stored config —
 * the user has expressed a preference and we respect it.
 *
 * @param {Array}         stored         Stored config `[{key, toggle}]`
 * @param {Array|Object}  server_columns Keys or `{key: column}` dict
 * @param {Array=}        allowed_keys   Optional review_state-allowed keys
 * @returns {Array} merged config `[{key, toggle}]`
 */
export function merge_column_config(stored, server_columns, allowed_keys) {
  stored = Array.isArray(stored) ? stored : [];

  let server_keys;
  let server_defaults;
  if (Array.isArray(server_columns)) {
    server_keys = server_columns;
    server_defaults = null;
  } else if (server_columns && typeof server_columns === "object") {
    server_keys = Object.keys(server_columns);
    server_defaults = server_columns;
  } else {
    server_keys = [];
    server_defaults = null;
  }

  const allowed = (allowed_keys && allowed_keys.length > 0)
    ? new Set(allowed_keys)
    : null;
  const is_allowed = (key) => !allowed || allowed.has(key);

  const default_toggle_for = (key) => {
    if (!server_defaults) return true;
    const col = server_defaults[key];
    if (!col || typeof col !== "object") return true;
    return col.toggle !== false;  // server default: visible unless false
  };

  const server_set = new Set(server_keys);
  const seen = new Set();
  const out = [];

  // 1 + 3: keep stored entries that still exist server-side AND are
  // allowed in the current review_state, in the user's chosen order.
  for (const entry of stored) {
    if (!entry || typeof entry.key !== "string") continue;
    if (seen.has(entry.key)) continue;
    if (!server_set.has(entry.key)) continue;
    if (!is_allowed(entry.key)) continue;
    out.push({
      key: entry.key,
      toggle: entry.toggle !== false,  // default true
    });
    seen.add(entry.key);
  }

  // 2: append server keys that weren't in stored, in server order.
  // Honor the server's default `toggle` so columns the server hides
  // (e.g. opt-in detail columns) stay hidden until the user reveals
  // them.  This is what auto-detects new add-on columns AND respects
  // their declared default visibility.
  for (const key of server_keys) {
    if (seen.has(key)) continue;
    if (!is_allowed(key)) continue;
    out.push({ key, toggle: default_toggle_for(key) });
    seen.add(key);
  }

  return out;
}


/**
 * Convenience: derive the {key: toggle} visibility map from a merged
 * config. Defaults absent keys to `true`.
 */
export function visibility_from(config) {
  const out = {};
  for (const entry of config || []) {
    out[entry.key] = entry.toggle !== false;
  }
  return out;
}


/**
 * Convenience: pull just the key array (the order) from a config.
 */
export function keys_from(config) {
  return (config || []).map((entry) => entry.key);
}


/**
 * Apply a visibility toggle to a config without mutating the input.
 *
 * The caller is expected to pass a merged config (via
 * `merge_column_config`) so the key is guaranteed to be present.
 * Keys absent from the config are a no-op — we do not invent
 * entries here, because doing so would silently mask a bug at the
 * call site.
 */
export function toggle_in(config, key) {
  return (config || []).map((entry) =>
    entry.key === key
      ? { ...entry, toggle: !(entry.toggle !== false) }
      : entry);
}


/**
 * Move `dragged_key` so it lands at the slot indicated by
 * (`target_key`, `position`) inside `keys`. Position is one of
 * "before" | "after". Stable: only the moved key changes its slot.
 *
 * Used by the header-cell drag-and-drop reorder; the resulting key
 * list is what the controller persists via `reorder_in`.
 */
export function move_key(keys, dragged_key, target_key, position) {
  const without = (keys || []).filter((k) => k !== dragged_key);
  const idx = without.indexOf(target_key);
  if (idx < 0) return keys || [];
  const insert_at = position === "after" ? idx + 1 : idx;
  return [
    ...without.slice(0, insert_at),
    dragged_key,
    ...without.slice(insert_at),
  ];
}


/**
 * Reorder a config to match the given key sequence.  Keys not in the
 * sequence keep their relative order at the end (defensive against
 * partial orders).
 */
export function reorder_in(config, ordered_keys) {
  const by_key = new Map();
  for (const entry of config || []) by_key.set(entry.key, entry);
  const out = [];
  const seen = new Set();
  for (const key of ordered_keys || []) {
    const entry = by_key.get(key);
    if (entry && !seen.has(key)) {
      out.push(entry);
      seen.add(key);
    }
  }
  // Append any config entries that weren't in the order — should be
  // rare (caller bug), but we never want to silently drop data.
  for (const entry of config || []) {
    if (!seen.has(entry.key)) out.push(entry);
  }
  return out;
}
