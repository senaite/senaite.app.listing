import {Menu, Item, Separator, Submenu} from "react-contexify"
import "react-contexify/dist/ReactContexify.css"

const ContextMenu = function ContextMenu({...props}) {

  const callback = props.on_menu_item_click

  function on_menu_item_click({event, props, triggerEvent, data}) {
    console.log(event, props, triggerEvent, data)
    if (callback) {
      callback(data.id, data.url, props.item)
    }
  }

  function render_menu_items() {
    let menu_items = []

    let title = window._t("Selected items")
    let folderitems = props.menu.folderitems || []
    let count = folderitems.length

    // Title item
    menu_items = [
      <Item key="title" disabled>
        <span className="badge badge-secondary mr-1">{count}</span> {title}
      </Item>,
      <Separator key="separator_title" />
    ]

    // Transitions
    let transitions = props.menu.transitions || []
    for (let transition of transitions) {
      menu_items.push(
        <Item key={transition.id} data={transition} onClick={on_menu_item_click}>
          {transition.title}
        </Item>
      )
    }

    // Actions
    let actions = props.menu.actions || []
    if (transitions.length > 0) {
      menu_items.push(<Separator key="separator_transitions" />)
    }
    for (let action of actions) {
      menu_items.push(
        <Item key={action.id} data={action} onClick={on_menu_item_click}>
          {action.title}
        </Item>
      )
    }

    return menu_items
  }

  return (
    <Menu id={props.id}>
      {render_menu_items()}
    </Menu>
  )
}

export default ContextMenu
