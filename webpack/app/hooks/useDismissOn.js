import { useEffect, useRef } from "react";


/**
 * Register `on_dismiss` to fire on outside mousedown and on Esc.
 *
 * Clicks inside `panel_ref` or any element listed in `ignore_refs`
 * (typically the trigger that opens the panel) are ignored, so the
 * trigger keeps its normal open/close toggle.  Listening on
 * `mousedown` rather than `click` means the panel closes before the
 * underlying control resolves its click — important when the panel
 * floats above an interactive table.
 *
 * `ignore_refs` is read through a ref so callers can pass an inline
 * array literal (`[anchor_ref]`) without re-binding the listeners on
 * every render — the array identity changes, but the listeners only
 * need to see the up-to-date contents at event time.
 *
 * @param {object} options
 * @param {boolean} options.when          When false, no listeners
 *                                        register (cheap pass-through).
 * @param {function} options.on_dismiss   Called with no arguments.
 * @param {React.RefObject} options.panel_ref
 * @param {Array<React.RefObject>=} options.ignore_refs
 */
export default function useDismissOn(options) {
  const {
    when = true,
    on_dismiss,
    panel_ref,
    ignore_refs,
  } = options || {};

  const ignore_refs_ref = useRef(ignore_refs);
  ignore_refs_ref.current = ignore_refs;

  useEffect(() => {
    if (!when || !on_dismiss) return undefined;
    const is_inside = (event, ref) =>
      ref && ref.current && ref.current.contains(event.target);
    const on_mousedown = (event) => {
      if (is_inside(event, panel_ref)) return;
      for (const ref of ignore_refs_ref.current || []) {
        if (is_inside(event, ref)) return;
      }
      on_dismiss();
    };
    const on_keydown = (event) => {
      if (event.key === "Escape") on_dismiss();
    };
    document.addEventListener("mousedown", on_mousedown);
    document.addEventListener("keydown", on_keydown);
    return () => {
      document.removeEventListener("mousedown", on_mousedown);
      document.removeEventListener("keydown", on_keydown);
    };
  }, [when, on_dismiss, panel_ref]);
}
