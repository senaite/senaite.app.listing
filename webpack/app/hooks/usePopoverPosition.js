import { useCallback, useEffect, useLayoutEffect, useState } from "react";


// Maximum and minimum widths, in pixels, for a floating popover.
const MAX_POPOVER_WIDTH = 512;   // ~32rem at the default 16px root
const MIN_POPOVER_WIDTH = 280;
// Side gutter when the popover is clamped to the viewport edge.
const VIEWPORT_GUTTER = 8;
// Estimated panel height used to decide whether to open below or
// above the anchor. Caller code can pass a measured height in via
// the `panel_height_ref` if it has one.
const ESTIMATED_PANEL_HEIGHT = 200;


/**
 * Compute a popover-shaped {top, left, width} relative to the
 * viewport, anchored to the left edge of an element (the "trigger").
 *
 *   - Width: as wide as the viewport allows, clamped between
 *     MIN_POPOVER_WIDTH and MAX_POPOVER_WIDTH.
 *   - Horizontal placement: left-align with the trigger, clamped so
 *     the popover always sits inside the viewport.
 *   - Vertical placement: drop below the trigger by default; if the
 *     viewport is too short, open above instead.
 *
 * The position recomputes on `resize` and capture-phase `scroll` so
 * the popover follows the trigger when an inner container scrolls.
 *
 * @param {React.RefObject} anchor_ref  Ref to the trigger element.
 * @param {object}          options
 * @param {React.RefObject?} options.panel_height_ref  Optional ref;
 *        if its .current carries a height (px), it overrides the
 *        ESTIMATED_PANEL_HEIGHT used by the flip check.
 * @returns {{top:number, left:number, width:number}}
 */
export default function usePopoverPosition(anchor_ref, options) {
  const panel_height_ref = options?.panel_height_ref;
  const [pos, set_pos] = useState({ top: 0, left: 0, width: 0 });

  const update_position = useCallback(() => {
    const el = anchor_ref && anchor_ref.current;
    if (!el) return;
    const rect = el.getBoundingClientRect();

    // Ideal width = MAX, reduce if the viewport doesn't fit, but
    // never drop below MIN even if the viewport is smaller (we'd
    // rather overflow a tiny viewport than render an unusable strip).
    const viewport_w = window.innerWidth - 2 * VIEWPORT_GUTTER;
    const width = Math.max(
      MIN_POPOVER_WIDTH, Math.min(MAX_POPOVER_WIDTH, viewport_w));

    const desired_left = rect.left;
    const left = Math.max(
      VIEWPORT_GUTTER,
      Math.min(desired_left, window.innerWidth - width - VIEWPORT_GUTTER));

    const panel_h = panel_height_ref?.current || ESTIMATED_PANEL_HEIGHT;
    let top = rect.bottom + 6;
    if (top + panel_h > window.innerHeight) {
      // Best-effort: open above. Falls back to flush against the top.
      top = Math.max(VIEWPORT_GUTTER, rect.top - 6 - panel_h);
    }

    set_pos({
      top: Math.round(top),
      left: Math.round(left),
      width: Math.round(width),
    });
  }, [anchor_ref, panel_height_ref]);

  useLayoutEffect(() => {
    update_position();
  }, [update_position]);

  useEffect(() => {
    const on_resize = () => update_position();
    window.addEventListener("resize", on_resize);
    // Capture-phase scroll catches scroll events on inner containers
    // (e.g. `.table-responsive`), not just on the window.
    window.addEventListener("scroll", on_resize, true);
    return () => {
      window.removeEventListener("resize", on_resize);
      window.removeEventListener("scroll", on_resize, true);
    };
  }, [update_position]);

  return pos;
}
