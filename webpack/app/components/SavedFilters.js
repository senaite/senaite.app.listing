import { useCallback, useEffect, useRef, useState } from "react";

import {
  capture_payload,
  generate_preset_id,
  load_presets,
  payloads_equal,
  save_presets,
} from "../storage/preset_storage.js";


// Mode reducer states for the dropdown's local UI state.
const IDLE = { kind: "idle" };
const SAVING = (draft) => ({ kind: "saving", draft });
const RENAMING = (id, draft) => ({ kind: "renaming", id, draft });
const DELETING = (id) => ({ kind: "deleting", id });


/**
 * Stop the click from reaching document-level outside-click listeners.
 *
 * React attaches synthetic-event listeners to the root container, so
 * calling stopPropagation() on a React event does NOT stop the native
 * bubble from reaching window.document. We have to reach into the
 * native event too.
 */
function stop_native_propagation(event) {
  event.stopPropagation();
  if (event.nativeEvent && event.nativeEvent.stopImmediatePropagation) {
    event.nativeEvent.stopImmediatePropagation();
  }
}


/**
 * Inline name input used for both "save new" and "rename existing".
 * Autofocuses + selects its content on mount; Enter confirms, Esc cancels.
 */
function InlineNameEditor(props) {
  const { value, placeholder, on_change, on_cancel, on_confirm } = props;
  const input_ref = useRef(null);

  useEffect(() => {
    if (input_ref.current) {
      input_ref.current.focus();
      input_ref.current.select();
    }
  }, []);

  const handle_change = useCallback(
    (event) => on_change(event.target.value),
    [on_change]);

  const handle_confirm = useCallback(() => {
    const name = (value || "").trim();
    if (name) on_confirm(name);
  }, [value, on_confirm]);

  const handle_keydown = useCallback((event) => {
    if (event.key === "Enter") {
      event.preventDefault();
      handle_confirm();
    } else if (event.key === "Escape") {
      event.preventDefault();
      on_cancel();
    }
  }, [handle_confirm, on_cancel]);

  return (
    <div className="saved-filter-edit">
      <input
        ref={input_ref}
        type="text"
        className="saved-filter-edit-input"
        value={value || ""}
        maxLength={80}
        placeholder={placeholder}
        onChange={handle_change}
        onKeyDown={handle_keydown}
      />
      <button
        type="button"
        className="saved-filter-edit-confirm"
        title={_t("Save")}
        onClick={handle_confirm}
      >
        <i className="fas fa-check"></i>
      </button>
      <button
        type="button"
        className="saved-filter-edit-cancel"
        onClick={on_cancel}
        title={_t("Cancel")}
      >
        <i className="fas fa-times"></i>
      </button>
    </div>
  );
}


/**
 * Per-listing collection of filter presets.
 *
 * Storage and payload equality live in ./preset_storage.js. This
 * component owns the dropdown's UI state, the edit/delete machinery
 * and translates user intent into on_apply / on_clear / on_reset
 * callbacks against the listing controller.
 */
function SavedFilters(props) {
  const {
    storage_id,
    current,
    applied_preset_id,
    on_apply,
    on_clear,
    on_reset,
  } = props;

  const [open, set_open] = useState(false);
  const [presets, set_presets] = useState(() => load_presets(storage_id));
  const [mode, set_mode] = useState(IDLE);
  const root_ref = useRef(null);

  // ---------- outside-click → close ----------

  // `mousedown` (not `click`) so the dismiss fires before any outer
  // control's click handler — matches the behaviour of useDismissOn
  // for the column-config popover and avoids the case where clicking
  // an unrelated trigger first registers as "close the menu, then
  // open the trigger's panel" in the wrong order.
  useEffect(() => {
    if (!open) return undefined;
    const on_outside = (event) => {
      if (root_ref.current && !root_ref.current.contains(event.target)) {
        set_open(false);
        set_mode(IDLE);
      }
    };
    document.addEventListener("mousedown", on_outside);
    return () => document.removeEventListener("mousedown", on_outside);
  }, [open]);

  // ---------- write-through helpers ----------

  const close_menu = useCallback(() => {
    set_open(false);
    set_mode(IDLE);
  }, []);

  const go_idle = useCallback(() => set_mode(IDLE), []);

  const persist = useCallback((next_presets) => {
    save_presets(storage_id, next_presets);
    set_presets(next_presets);
    set_mode(IDLE);
  }, [storage_id]);

  const find_preset = useCallback(
    (id) => presets.find((p) => p.id === id) || null,
    [presets]);

  const preset_from_event = useCallback(
    (event) => find_preset(event.currentTarget.dataset.presetId),
    [find_preset]);

  // ---------- dirty detection ----------

  const is_dirty = useCallback((preset) => {
    return preset
      && !payloads_equal(capture_payload(current), preset.payload);
  }, [current]);

  // ---------- toggle / apply / revert / update / default ----------

  const toggle_open = useCallback((event) => {
    event.preventDefault();
    set_open((was) => !was);
    set_mode(IDLE);
  }, []);

  const on_apply_click = useCallback((event) => {
    event.preventDefault();
    const preset = preset_from_event(event);
    if (!preset) return;
    // Click the already-applied row to release; the listing controller
    // decides whether to wipe filters or just drop the marker.
    if (applied_preset_id === preset.id) {
      on_clear && on_clear();
    } else {
      on_apply && on_apply(preset);
    }
    close_menu();
  }, [applied_preset_id, on_apply, on_clear, preset_from_event, close_menu]);

  const on_revert_click = useCallback((event) => {
    event.preventDefault();
    event.stopPropagation();
    const preset = preset_from_event(event);
    if (preset && on_apply) on_apply(preset);
    close_menu();
  }, [on_apply, preset_from_event, close_menu]);

  const on_update_click = useCallback((event) => {
    event.preventDefault();
    event.stopPropagation();
    const id = event.currentTarget.dataset.presetId;
    const payload = capture_payload(current);
    persist(presets.map((p) =>
      p.id === id ? { ...p, payload } : p));
  }, [current, presets, persist]);

  const on_set_default_click = useCallback((event) => {
    event.preventDefault();
    event.stopPropagation();
    const id = event.currentTarget.dataset.presetId;
    // Only one default at a time; clicking the current default unstars.
    persist(presets.map((p) => ({
      ...p,
      is_default: p.id === id ? !p.is_default : false,
    })));
  }, [presets, persist]);

  // ---------- save / rename / delete (inline editors) ----------

  const update_draft = useCallback((draft) => {
    set_mode((m) =>
      (m.kind === "saving" || m.kind === "renaming")
        ? { ...m, draft }
        : m);
  }, []);

  const on_save_open = useCallback((event) => {
    event.preventDefault();
    stop_native_propagation(event);
    set_mode(SAVING(_t("My filter") || "My filter"));
  }, []);

  const on_save_confirm = useCallback((name) => {
    const preset = {
      id: generate_preset_id(),
      name,
      is_default: false,
      payload: capture_payload(current),
    };
    persist([...presets, preset]);
    // Flag the new preset as applied so the dirty detector has a baseline.
    on_apply && on_apply(preset);
  }, [current, presets, persist, on_apply]);

  const on_rename_open = useCallback((event) => {
    event.preventDefault();
    event.stopPropagation();
    const preset = preset_from_event(event);
    if (preset) set_mode(RENAMING(preset.id, preset.name));
  }, [preset_from_event]);

  const on_rename_confirm = useCallback((name) => {
    if (mode.kind !== "renaming") return;
    const id = mode.id;
    persist(presets.map((p) => p.id === id ? { ...p, name } : p));
  }, [mode, presets, persist]);

  const on_delete_open = useCallback((event) => {
    event.preventDefault();
    event.stopPropagation();
    const preset = preset_from_event(event);
    if (preset) set_mode(DELETING(preset.id));
  }, [preset_from_event]);

  const on_delete_confirm = useCallback((event) => {
    event.preventDefault();
    if (mode.kind !== "deleting") return;
    const id = mode.id;
    const was_applied = applied_preset_id === id;
    persist(presets.filter((p) => p.id !== id));
    // Deleting the applied preset would leave an orphaned filter set
    // with no preset to manage it — drop the view too.
    if (was_applied && on_reset) on_reset();
  }, [mode, applied_preset_id, on_reset, presets, persist]);

  // ---------- rendering ----------

  return (
    <div className="saved-filters" ref={root_ref}>
      <PresetToggle
        open={open}
        applied={!!applied_preset_id}
        count={presets.length}
        on_click={toggle_open}
      />
      {open && (
        <PresetMenu
          presets={presets}
          mode={mode}
          applied_preset_id={applied_preset_id}
          is_dirty={is_dirty}
          on_apply={on_apply_click}
          on_rename_open={on_rename_open}
          on_rename_confirm={on_rename_confirm}
          on_delete_open={on_delete_open}
          on_delete_confirm={on_delete_confirm}
          on_update={on_update_click}
          on_revert={on_revert_click}
          on_set_default={on_set_default_click}
          on_save_open={on_save_open}
          on_save_confirm={on_save_confirm}
          on_cancel={go_idle}
          on_draft_change={update_draft}
        />
      )}
    </div>
  );
}


// ---------- presentational sub-components ----------

function PresetToggle(props) {
  const { open, applied, count, on_click } = props;
  const cls = "saved-filters-toggle" +
    (open ? " is-open" : "") +
    (applied ? " has-applied" : "");
  return (
    <button
      type="button"
      className={cls}
      onClick={on_click}
      title={_t("Saved filters")}
      aria-haspopup="true"
      aria-expanded={open}
    >
      <i className="fas fa-bookmark"></i>
      {count > 0 && (
        <span className="saved-filters-count">{count}</span>
      )}
    </button>
  );
}


function PresetMenu(props) {
  const {
    presets, mode, applied_preset_id, is_dirty,
    on_apply, on_rename_open, on_rename_confirm,
    on_delete_open, on_delete_confirm,
    on_update, on_revert, on_set_default,
    on_save_open, on_save_confirm,
    on_cancel, on_draft_change,
  } = props;

  return (
    <div
      className="saved-filters-menu"
      role="menu"
      onClick={stop_native_propagation}
      onMouseDown={stop_native_propagation}
    >
      <div className="saved-filters-header">
        <span className="saved-filters-title">{_t("Saved filters")}</span>
        <span className="saved-filters-hint">{_t("per listing")}</span>
      </div>
      {presets.length > 0 ? (
        <ul className="saved-filter-list">
          {presets.map((preset) => (
            <PresetRow
              key={preset.id}
              preset={preset}
              mode={mode}
              is_applied={applied_preset_id === preset.id}
              dirty={applied_preset_id === preset.id && is_dirty(preset)}
              on_apply={on_apply}
              on_rename_open={on_rename_open}
              on_rename_confirm={on_rename_confirm}
              on_delete_open={on_delete_open}
              on_delete_confirm={on_delete_confirm}
              on_update={on_update}
              on_revert={on_revert}
              on_set_default={on_set_default}
              on_cancel={on_cancel}
              on_draft_change={on_draft_change}
            />
          ))}
        </ul>
      ) : (
        <div className="saved-filter-empty">
          {_t("No saved filters yet.")}
        </div>
      )}
      <SaveFooter
        mode={mode}
        on_save_open={on_save_open}
        on_save_confirm={on_save_confirm}
        on_cancel={on_cancel}
        on_draft_change={on_draft_change}
      />
    </div>
  );
}


function PresetRow(props) {
  const {
    preset, mode, is_applied, dirty,
    on_apply, on_rename_open, on_rename_confirm,
    on_delete_open, on_delete_confirm,
    on_update, on_revert, on_set_default,
    on_cancel, on_draft_change,
  } = props;

  if (mode.kind === "renaming" && mode.id === preset.id) {
    return (
      <li className="saved-filter-item is-editing">
        <InlineNameEditor
          value={mode.draft}
          placeholder={preset.name}
          on_change={on_draft_change}
          on_cancel={on_cancel}
          on_confirm={on_rename_confirm}
        />
      </li>
    );
  }

  if (mode.kind === "deleting" && mode.id === preset.id) {
    return <DeleteConfirmRow
      preset={preset}
      on_cancel={on_cancel}
      on_confirm={on_delete_confirm}
    />;
  }

  return <DefaultRow
    preset={preset}
    is_applied={is_applied}
    dirty={dirty}
    on_apply={on_apply}
    on_rename_open={on_rename_open}
    on_delete_open={on_delete_open}
    on_update={on_update}
    on_revert={on_revert}
    on_set_default={on_set_default}
  />;
}


function DefaultRow(props) {
  const {
    preset, is_applied, dirty,
    on_apply, on_rename_open, on_delete_open,
    on_update, on_revert, on_set_default,
  } = props;
  const is_default = !!preset.is_default;
  const cls = ["saved-filter-item"];
  if (is_default) cls.push("is-default");
  if (is_applied) cls.push("is-applied");
  if (dirty) cls.push("is-dirty");

  return (
    <li className={cls.join(" ")}>
      <button
        type="button"
        className="saved-filter-apply"
        data-preset-id={preset.id}
        onClick={on_apply}
        title={is_applied
          ? _t("Click to release this filter")
          : _t("Apply this filter")}
      >
        <span className="saved-filter-marker">
          {is_applied
            ? <i className="fas fa-check"></i>
            : <i className="far fa-circle"></i>}
        </span>
        <span className="saved-filter-name">{preset.name}</span>
        {dirty && (
          <span
            className="saved-filter-dirty-tag"
            title={_t("Current view differs from saved")}
          >
            {_t("modified")}
          </span>
        )}
        {is_default && !dirty && (
          <span className="saved-filter-default-tag">{_t("auto")}</span>
        )}
      </button>
      <span className="saved-filter-actions">
        {dirty && (
          <>
            <button
              type="button"
              className="saved-filter-action saved-filter-action-update"
              data-preset-id={preset.id}
              onClick={on_update}
              title={_t("Update preset with current view")}>
              <i className="fas fa-save"></i>
            </button>
            <button
              type="button"
              className="saved-filter-action saved-filter-action-revert"
              data-preset-id={preset.id}
              onClick={on_revert}
              title={_t("Discard edits and restore preset")}>
              <i className="fas fa-undo"></i>
            </button>
          </>
        )}
        <button
          type="button"
          className="saved-filter-action saved-filter-action-rename"
          data-preset-id={preset.id}
          onClick={on_rename_open}
          title={_t("Rename filter")}>
          <i className="fas fa-pen"></i>
        </button>
        <button
          type="button"
          className={"saved-filter-action saved-filter-action-star" +
            (is_default ? " is-on" : "")}
          data-preset-id={preset.id}
          onClick={on_set_default}
          title={is_default
            ? _t("Stop auto-applying")
            : _t("Auto-apply on open")}
          aria-pressed={is_default}>
          <i className={is_default ? "fas fa-star" : "far fa-star"}></i>
        </button>
        <button
          type="button"
          className="saved-filter-action saved-filter-action-delete"
          data-preset-id={preset.id}
          onClick={on_delete_open}
          title={_t("Delete filter")}>
          <i className="fas fa-times"></i>
        </button>
      </span>
    </li>
  );
}


function DeleteConfirmRow(props) {
  const { preset, on_cancel, on_confirm } = props;
  return (
    <li className="saved-filter-item is-confirming">
      <div className="saved-filter-confirm">
        <span className="saved-filter-confirm-text">
          {_t("Delete")} <strong>{preset.name}</strong>?
        </span>
        <span className="saved-filter-confirm-actions">
          <button
            type="button"
            className="saved-filter-confirm-cancel"
            onClick={on_cancel}
            title={_t("Cancel")}
            aria-label={_t("Cancel")}>
            <i className="fas fa-times"></i>
          </button>
          <button
            type="button"
            className="saved-filter-confirm-confirm"
            onClick={on_confirm}
            title={_t("Delete")}
            aria-label={_t("Delete")}>
            <i className="fas fa-trash"></i>
          </button>
        </span>
      </div>
    </li>
  );
}


function SaveFooter(props) {
  const { mode, on_save_open, on_save_confirm, on_cancel, on_draft_change } =
    props;
  if (mode.kind === "saving") {
    return (
      <div className="saved-filters-footer saved-filters-save-row">
        <InlineNameEditor
          value={mode.draft}
          placeholder={_t("Filter name")}
          on_change={on_draft_change}
          on_cancel={on_cancel}
          on_confirm={on_save_confirm}
        />
      </div>
    );
  }
  return (
    <div className="saved-filters-footer">
      <button
        type="button"
        className="saved-filters-save"
        onClick={on_save_open}>
        <i className="fas fa-plus"></i>
        <span>{_t("Save current view")}</span>
      </button>
    </div>
  );
}


export default SavedFilters;
