import React from "react"
import { useRef } from 'react'
import TableCells from "./TableCells.coffee"
import { ItemTypes } from "./Constants.coffee"
import { useDrag } from "react-dnd";
import { useDrop } from "react-dnd";


const style = {
  border: '1px dashed gray',
  padding: '0.5rem 1rem',
  marginBottom: '.5rem',
  backgroundColor: 'white',
  cursor: 'move',
}

/**Draggable table row
 *
 * */
function TableRow(props) {

  const ref = useRef(null)

  const moveRow =

  // Drop Handler
  const [{ handlerId }, drop] = useDrop({
    accept: ItemTypes.ROW,
    collect(monitor) {
      return {
        handlerId: monitor.getHandlerId(),
      }
    },
    hover(item, monitor) {
      if (!ref.current) {
        return
      }
      const dragIndex = item.index
      const hoverIndex = props.row_index
      // Don't replace items with themselves
      if (dragIndex === hoverIndex) {
        return
      }
      // Determine rectangle on screen
      const hoverBoundingRect = ref.current?.getBoundingClientRect()
      // Get vertical middle
      const hoverMiddleY =
        (hoverBoundingRect.bottom - hoverBoundingRect.top) / 2
      // Determine mouse position
      const clientOffset = monitor.getClientOffset()
      // Get pixels to the top
      const hoverClientY = clientOffset.y - hoverBoundingRect.top
      // Only perform the move when the mouse has crossed half of the items height
      // When dragging downwards, only move when the cursor is below 50%
      // When dragging upwards, only move when the cursor is above 50%
      // Dragging downwards
      if (dragIndex < hoverIndex && hoverClientY < hoverMiddleY) {
        return
      }
      // Dragging upwards
      if (dragIndex > hoverIndex && hoverClientY > hoverMiddleY) {
        return
      }
      // Time to actually perform the action
      if (props.on_move_row) {
        props.on_move_row(dragIndex, hoverIndex)
      }
      // Note: we're mutating the monitor item here!
      // Generally it's better to avoid mutations,
      // but it's good here for the sake of performance
      // to avoid expensive index searches.
      item.index = hoverIndex
    }
  })

  const [{ isDragging }, drag] = useDrag({
    type: ItemTypes.ROW,
    item: () => {
      return {
        uid: props.uid,
        index: props.row_index,
        item: props.item
      }
    },
    collect: (monitor) => ({
      isDragging: monitor.isDragging(),
    }),
  })

  const opacity = isDragging ? 0.4 : 1
  drag(drop(ref))

  return (
    <tr className={props.className}
        ref={ref}
        style={{ ...style, opacity }}
        onClick={props.onClick}
        category={props.category}
        uid={props.uid}>
      <TableCells {...props}/>
    </tr>
  )
}


export default TableRow
