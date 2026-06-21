/**
 * Per-listing filter preset storage.
 *
 * A preset is a JSON object of the shape:
 *
 *   {
 *     id: <opaque string>,
 *     name: <human-readable string>,
 *     is_default: <bool>,
 *     payload: {
 *       review_state, column_filters, sort_on, sort_order, pagesize, filter
 *     }
 *   }
 *
 * Presets are persisted in window.localStorage under one key per
 * listing storage_id so different views keep independent collections.
 *
 * The storage_id should be the listing view's `listing_identifier`
 * (a per-listing-kind key calculated server-side that groups similar
 * listings — e.g. "AnalysisRequestsListing" for the global samples
 * folder vs the per-client folders). The form_id alone is NOT a safe
 * key: the same form_id is reused across folder/kind, so presets
 * would bleed between unrelated listings (e.g. "Batches" in a client
 * vs "Batches" at the portal root).
 *
 * This module is pure storage + payload utilities — no React.
 */


const STORAGE_PREFIX = "senaite.listing.saved_filters.";


function storage_key(storage_id) {
  return STORAGE_PREFIX + (storage_id || "default");
}


export function load_presets(storage_id) {
  try {
    const raw = window.localStorage.getItem(storage_key(storage_id));
    if (!raw) {
      return [];
    }
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch (error) {
    console.warn("preset_storage: failed to read presets", error);
    return [];
  }
}


export function save_presets(storage_id, presets) {
  try {
    window.localStorage.setItem(
      storage_key(storage_id), JSON.stringify(presets));
    return true;
  } catch (error) {
    console.warn("preset_storage: failed to write presets", error);
    return false;
  }
}


export function generate_preset_id() {
  return "p_" + Math.random().toString(36).slice(2, 10) +
    "_" + Date.now().toString(36);
}


export function find_default_preset(storage_id) {
  return load_presets(storage_id).find((p) => p.is_default) || null;
}


/**
 * Sort presets by name (case-insensitive) for stable list display.
 */
export function sort_presets(presets) {
  return [...presets].sort((a, b) =>
    (a.name || "").localeCompare(b.name || ""));
}


/**
 * Key-order-independent JSON for shallow equality of payloads.
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
 * Drop empty/null entries from column_filters so a present-but-empty
 * filter does not read as different from an absent one.
 */
function normalize_payload(payload) {
  payload = payload || {};
  const column_filters = {};
  const src = payload.column_filters || {};
  for (const key of Object.keys(src)) {
    if (src[key] !== "" && src[key] != null) {
      column_filters[key] = src[key];
    }
  }
  const labels = Array.isArray(payload.labels) ? payload.labels.slice() : [];
  labels.sort();
  return {
    review_state: payload.review_state || "",
    column_filters: column_filters,
    sort_on: payload.sort_on || "",
    sort_order: payload.sort_order || "",
    pagesize: payload.pagesize || null,
    filter: payload.filter || "",
    labels: labels,
  };
}


export function payloads_equal(a, b) {
  return stable_stringify(normalize_payload(a)) ===
         stable_stringify(normalize_payload(b));
}


/**
 * Build a preset payload from the listing's current view state.
 */
export function capture_payload(current) {
  current = current || {};
  const labels = Array.isArray(current.labels)
    ? current.labels.slice().filter((s) => s).sort()
    : [];
  return {
    review_state: current.review_state || "",
    column_filters: Object.assign({}, current.column_filters || {}),
    sort_on: current.sort_on || "",
    sort_order: current.sort_order || "",
    pagesize: current.pagesize || null,
    filter: current.filter || "",
    labels: labels,
  };
}
