import { useCallback, useRef } from "react";
import { useDrag, useDrop } from "react-dnd";

import Checkbox from "./Checkbox.coffee";
import TableHeaderCell from "./TableHeaderCell.js";
import { ItemTypes } from "./Constants";
import { move_key } from "../storage/column_config.js";


function is_required_column(folderitems, key) {
  if (!folderitems || folderitems.length === 0) return false;
  const required = folderitems[0].required || [];
  return required.includes(key);
}


function is_sortable(column, key, sortable_columns) {
  if (column.sortable === false) return false;
  if (column.index) return true;
  if (sortable_columns && sortable_columns.includes(key)) return true;
  return false;
}


// One <th> wrapped in react-dnd's useDrag + useDrop. Lives in the
// same DnD context as TableRow (DndProvider in listing.coffee) so
// our column drags do not collide with the row backend.
//
// The drop indicator (`is-drop-before` / `is-drop-after`) is decided
// in the `hover` callback, not `dragover`, so we get react-dnd's
// throttled, monitor-aware updates instead of competing with the
// raw HTML5 stream the row backend has hijacked.
function DraggableHeaderCell(props) {
  const {
    column_key, can_reorder, visible_columns,
    on_columns_order_change, cls_base, ...rest
  } = props;

  const ref = useRef(null);

  const [{ is_dragging }, drag_connector] = useDrag({
    type: ItemTypes.COLUMN,
    item: () => ({ key: column_key, target_key: null, position: null }),
    canDrag: () => can_reorder,
    collect: (monitor) => ({
      is_dragging: !!monitor.isDragging(),
    }),
    // Commit the reorder in `end`, after react-dnd's endDrag cycle
    // has cleaned up the monitor.  Calling `on_columns_order_change`
    // inside `drop` re-renders the parent synchronously and strands
    // the source <th> with isDragging = true — visible as the greyed
    // cell that never releases.
    //
    // We additionally defer the parent update to the next animation
    // frame: react-dnd's endDrag bookkeeping runs in a microtask
    // after `end` returns, and a synchronous reorder here re-renders
    // the whole table (rows + cells) before that bookkeeping
    // finishes.  On large listings the browser cannot paint a hover
    // update until the cascade settles, which surfaces as "no hover
    // for ~10s" after a drag.  rAF lets the browser paint a clean
    // post-drag frame first; the reorder lands one frame later.
    end: (item, monitor) => {
      if (!monitor.didDrop()) return;
      if (!item.target_key || item.target_key === item.key) return;
      const next = move_key(
        visible_columns, item.key, item.target_key,
        item.position || "after");
      window.requestAnimationFrame(() => on_columns_order_change(next));
    },
  }, [column_key, can_reorder, visible_columns, on_columns_order_change]);

  const [{ is_over, drop_position }, drop_connector] = useDrop({
    accept: ItemTypes.COLUMN,
    canDrop: (item) => can_reorder && item.key !== column_key,
    hover: (item, monitor) => {
      if (!ref.current || item.key === column_key) return;
      const offset = monitor.getClientOffset();
      if (!offset) return;
      const rect = ref.current.getBoundingClientRect();
      const position = (offset.x - rect.left) < rect.width / 2
        ? "before" : "after";
      // Stash on the drag item so the source's `end` can commit it.
      item.target_key = column_key;
      item.position = position;
    },
    // `collect` re-runs whenever monitor state changes (item moves,
    // isOver flips), so deriving the visual indicator from the live
    // monitor offset keeps the borders in sync without extra state.
    collect: (monitor) => {
      if (!monitor.isOver({ shallow: true })) {
        return { is_over: false, drop_position: null };
      }
      if (!ref.current) return { is_over: true, drop_position: null };
      const offset = monitor.getClientOffset();
      if (!offset) return { is_over: true, drop_position: null };
      const rect = ref.current.getBoundingClientRect();
      return {
        is_over: true,
        drop_position: (offset.x - rect.left) < rect.width / 2
          ? "before" : "after",
      };
    },
  }, [column_key, can_reorder]);

  drag_connector(drop_connector(ref));

  const cls = [...cls_base];
  if (can_reorder) cls.push("reorderable");
  if (is_dragging) cls.push("is-dragging");
  if (is_over && drop_position === "before") cls.push("is-drop-before");
  if (is_over && drop_position === "after") cls.push("is-drop-after");

  return (
    <TableHeaderCell
      {...rest}
      column_key={column_key}
      className={cls.join(" ")}
      draggable={can_reorder}
      outer_ref={ref}
    />
  );
}


function TableHeaderRow(props) {
  const {
    show_select_column,
    show_select_all_checkbox,
    all_items_selected,
    on_select_checkbox_checked,
    allow_row_reorder,
    visible_columns,
    columns,
    folderitems,
    sortable_columns,
    sort_on,
    sort_order,
    on_header_column_click,
    on_columns_order_change,
    on_context_menu,
  } = props;

  const can_reorder = typeof on_columns_order_change === "function";

  const on_header_click = useCallback((event) => {
    const el = event.currentTarget;
    const index = el.getAttribute("index");
    let order = el.getAttribute("sort_order");
    if (!index) return;
    if (el.classList.contains("active")) {
      order = order === "ascending" ? "descending" : "ascending";
    }
    on_header_column_click(index, order);
  }, [on_header_column_click]);

  const cells = [];

  if (show_select_column) {
    cells.push(
      <th className="select-column" key="select_all">
        {show_select_all_checkbox &&
          <Checkbox
            name="select_all"
            value="all"
            checked={all_items_selected}
            onChange={on_select_checkbox_checked}/>}
      </th>
    );
  }

  if (allow_row_reorder) {
    cells.push(<th className="dnd-column" key="dnd"></th>);
  }

  for (const key of visible_columns) {
    const column = columns[key];
    const sortable = is_sortable(column, key, sortable_columns);
    const index = column.index || key;
    const title = column.title;
    const alt = column.alt || title;
    const current_sort_on = sort_on || "created";
    const current_sort_order = sort_order || "ascending";
    const is_sort_column = index === current_sort_on;
    const required = is_required_column(folderitems, key);

    const cls_base = [key];
    if (sortable) cls_base.push("sortable");
    if (is_sort_column && sortable) {
      cls_base.push("active " + current_sort_order);
    }
    if (required) cls_base.push("required");

    cells.push(
      <DraggableHeaderCell
        key={key}
        {...props}
        column_key={key}
        title={title}
        alt={alt}
        index={index}
        sort_on={current_sort_on}
        sort_order={current_sort_order}
        cls_base={cls_base}
        can_reorder={can_reorder}
        visible_columns={visible_columns}
        on_columns_order_change={on_columns_order_change}
        onClick={sortable ? on_header_click : undefined}
        on_sort_click={on_header_column_click}
      />
    );
  }

  return (
    <tr onContextMenu={on_context_menu}>
      {cells}
    </tr>
  );
}


export default TableHeaderRow;
