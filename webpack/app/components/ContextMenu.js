import { useEffect } from "react"
import { Menu, Item, Separator } from "react-contexify"
import "react-contexify/dist/ReactContexify.css"
import { CONFIRM_TRANSITION_IDS }from "./Constants.js"


const ContextMenu = function ContextMenu({...props}) {

  const callback = props.on_menu_item_click

  useEffect(() => {
    // componentDidUpdate
  });

  function on_menu_item_click({event, props, triggerEvent, data}) {
    console.log(event, props, triggerEvent, data)
    if (callback) {
      if (CONFIRM_TRANSITION_IDS.includes(data.id)) {
        // add confirmation dialog on the menu item
        let el = $(event.currentTarget)
        const on_ok = () => callback(data.id, data.url, props.item)
        el.confirmation({
          rootSelector: "[data-toggle=confirmation]",
          title: `${window._t(data.title)}?`,
          btnOkLabel: window._t("Yes"),
          btnOkClass: "btn btn-outline-primary",
          btnOkIconClass: "fas fa-check-circle mr-1",
          btnCancelLabel: window._t("No"),
          btnCancelClass: "btn btn-outline-secondary",
          btnCancelIconClass: "fas fa-circle mr-1",
          container: "body",
          onConfirm: on_ok,
          singleton: true
        })
        el.confirmation("show")
      } else {
        callback(data.id, data.url, props.item)
      }
    }
  }

  function render_menu_items() {
    let menu_items = []

    let title = window._t("Selected items")
    let folderitems = props.menu.folderitems || []
    let count = folderitems.length

    // use the item title if we have only one (regular) folderitem
    if (count == 1 && folderitems[0].title) {
      title = folderitems[0].title
    }

    // Title item
    menu_items = [
      <Item key="title" disabled>
        {count > 1 && <span className="badge badge-secondary mr-1">{count}</span>}
        {title}
      </Item>,
      <Separator key="separator_title" />
    ]

    // Transitions
    let transitions = props.menu.transitions || []
    for (let transition of transitions) {
      menu_items.push(
        <Item closeOnClick={false} key={transition.id} data={transition} onClick={on_menu_item_click}>
          {window._t(transition.title)}
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
          {window._t(action.title)}
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
