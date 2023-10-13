import React from "react"
import { useCallback, useRef, memo } from "react"
import TableCells from "./TableCells.coffee"
import { ItemTypes } from "./Constants"
import { useDrag } from "react-dnd";
import { useDrop } from "react-dnd";

/**Draggable table row
 *
 * */
const TableRow = memo(function TableRow({...props}) {

  const dragRef = useRef(null)
  const dropRef = useRef(null)

  const moveRow = useCallback(
    (from_index, to_index) => {
      if (props.move_row) {
        props.move_row(from_index, to_index)
      }
    }
  )

  const onRowOrderChange = useCallback(
    () => {
      if (props.on_row_order_change) {
        props.on_row_order_change()
      }
    }
  )

  // Drop Handler
  const [{ handlerId, isOver, canDrop }, drop] = useDrop({
    accept: ItemTypes.ROW,
    collect(monitor) {
      return {
        handlerId: monitor.getHandlerId(),
        isOver: !!monitor.isOver(),
        canDrop: !!monitor.canDrop()
      }
    },
    hover(item, monitor) {
      if (!dragRef.current) {
        return
      }
      const dragIndex = item.index
      const hoverIndex = props.row_index
      // Don't replace items with themselves
      if (dragIndex === hoverIndex) {
        return
      }
      moveRow(dragIndex, hoverIndex)
      // Note: we're mutating the monitor item here!
      // Generally it's better to avoid mutations,
      // but it's good here for the sake of performance
      // to avoid expensive index searches.
      item.index = hoverIndex
    }
  })

  const [{ isDragging }, drag, preview] = useDrag({
    type: ItemTypes.ROW,
    item: () => {
      // dragged item data
      return {
        uid: props.uid,
        category: props.category,
        index: props.row_index,
      }
    },
    canDrag: (monitor) => {
      // global allow/disallow dragging
      return props.allow_row_reorder;
    },
    collect: (monitor) => ({
      isDragging: !!monitor.isDragging()
    }),
    end: (item, monitor) => {
      // notify the changed order
      onRowOrderChange()
    }
  })

  // references
  preview(drop(dropRef))
  drag(dragRef)

  // calculate the CSS class
  let css_class = props.className
  if (isDragging) {
    css_class += " dragging"
  }

  function on_context_menu(event) {
    // call the parent handler with the current item
    if (props.on_row_context_menu) {
      props.on_row_context_menu(event, props.item)
    }
  }

  return (
    <tr className={css_class}
        ref={dropRef}
        onClick={props.onClick}
        onContextMenu={on_context_menu}
        category={props.category}
        uid={props.uid}>
      <TableCells dragref={dragRef} {...props}/>
    </tr>
  )
})


export default TableRow
