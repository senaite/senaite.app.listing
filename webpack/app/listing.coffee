###* ReactJS controlled component
 *
 * Please use JSDoc comments: https://jsdoc.app
 *
 * Note: Each comment must start with a `/**` sequence in order to be recognized
 *       by the JSDoc parser.
###
import React from "react"
import ReactDOM from "react-dom"
import { createRoot } from 'react-dom/client';
import { v4 as uuidv4 } from "uuid"

import ButtonBar from "./components/ButtonBar.coffee"
import FilterBar from "./components/FilterBar.coffee"
import ListingAPI from "./api.coffee"
import Loader from "./components/Loader.coffee"
import Messages from "./components/Messages.coffee"
import Modal from "./components/Modal.coffee"
import Pagination from "./components/Pagination.coffee"
import SearchBox from "./components/SearchBox.coffee"
import SavedFilters from "./components/SavedFilters.js"
import { find_default_preset } from "./storage/preset_storage.js"
import {
  clear_column_config,
  keys_from as column_keys_from,
  merge_column_config,
  read_column_config,
  reorder_in,
  toggle_in,
  visibility_from,
  write_column_config,
} from "./storage/column_config.js"
import Table from "./components/Table.js"
import TableColumnConfig from "./components/TableColumnConfig.js"
import ToastNotification from "./components/Toast.js"

import { DndProvider } from "react-dnd"
import { HTML5Backend } from "react-dnd-html5-backend"

import ContextMenu from "./components/ContextMenu.js"
import {useContextMenu} from "react-contexify"

import "./listing.css"

###* DOCUMENT READY ENTRY POINT ###
document.addEventListener "DOMContentLoaded", ->
  console.debug "*** SENAITE.APP.LISTING::DOMContentLoaded: --> Loading ReactJS Controller"

  if not window._t?
    console.warn("Global translation variable `_t` not found! Translations won't work!")
    # Mock the variable to return the input as output
    window._t = (text, ...) -> text

  tables = document.getElementsByClassName "ajax-contents-table"

  # ensure global namespace for listing controllers
  # -> see componentDidMount for the reference
  window.senaite ?= {}
  window.senaite.core ?= {}
  window.senaite.core.listings ?= {}

  for table in tables
    if not table._reactRootContainer?
      table._reactRootContainer = createRoot(table)
    table._reactRootContainer.render <ListingController root_el={table} />


###*
 * Controller class for one listing table.
 * The idea is to handle all API calls and logic here and pass the callback
 * methods to the contained components.
 * @class
###
class ListingController extends React.Component

  ###*
   * Bind all event handlers and define the state
   * @constructor
  ###
  constructor: (props) ->
    super(props)

    # bind callbacks
    @dismissMessage = @dismissMessage.bind @
    @doAction = @doAction.bind @
    @filterBySearchterm = @filterBySearchterm.bind @
    @filterByState = @filterByState.bind @
    @on_api_error = @on_api_error.bind @
    @on_column_config_click = @on_column_config_click.bind @
    @close_column_config = @close_column_config.bind @
    @resetColumns = @resetColumns.bind @
    # Anchor for the column-config popover so it can attach to a
    # portal at the document root yet still position itself under the
    # `⋯` trigger button.
    @column_config_anchor_ref = React.createRef()
    @on_select_checkbox_checked = @on_select_checkbox_checked.bind @
    @on_multi_select_checkbox_checked = @on_multi_select_checkbox_checked.bind @
    @on_category_click = @on_category_click.bind @
    @on_category_select = @on_category_select.bind @
    @on_reload = @on_reload.bind @
    @saveAjaxQueue = @saveAjaxQueue.bind @
    @saveEditableField = @saveEditableField.bind @
    @setColumnsOrder = @setColumnsOrder.bind @
    @showMore = @showMore.bind @
    @export = @export.bind @
    @sortBy = @sortBy.bind @
    @toggleColumn = @toggleColumn.bind @
    @toggleRemarks = @toggleRemarks.bind @
    @toggleRow = @toggleRow.bind @
    @updateEditableField = @updateEditableField.bind @
    @on_popstate = @on_popstate.bind @
    @moveRow = @moveRow.bind @
    @showRowMenu = @showRowMenu.bind @
    @handleRowMenuAction = @handleRowMenuAction.bind @
    @on_row_order_change = @on_row_order_change.bind @
    @on_click = @on_click.bind @
    @removeToast = @removeToast.bind @
    @toggleColumnFilter = @toggleColumnFilter.bind @
    @onColumnFilterChange = @onColumnFilterChange.bind @
    @onColumnFilterSubmit = @onColumnFilterSubmit.bind @
    @applySavedFilter = @applySavedFilter.bind @
    @clearAppliedPreset = @clearAppliedPreset.bind @
    @resetView = @resetView.bind @

    # root element
    @root_el = @props.root_el

    # get initial configuration data from the HTML attribute
    @api_url = @root_el.dataset.api_url
    @columns = JSON.parse @root_el.dataset.columns
    @form_id = @root_el.dataset.form_id
    @listing_identifier = @root_el.dataset.listing_identifier
    @pagesize = parseInt @root_el.dataset.pagesize
    @review_states = @parse_json @root_el.dataset.review_states
    @default_review_state = @root_el.dataset.default_review_state or "default"
    @show_column_toggles = @parse_json @root_el.dataset.show_column_toggles
    @enable_ajax_transitions = @parse_json @root_el.dataset.enable_ajax_transitions, no
    @active_ajax_transitions = @parse_json @root_el.dataset.active_ajax_transitions, []
    @row_context_menu_id = "row-context-menu-#{@form_id}"

    # bind event handlers
    @root_el.addEventListener "reload", @on_reload

    # the API is responsible for async calls and knows about the endpoints
    @api = new ListingAPI
      api_url: @api_url
      on_api_error: @on_api_error
      form_id: @form_id

    # request parameters
    @filter = @api.get_url_parameter("filter")
    @pagesize = parseInt(@api.get_url_parameter("pagesize")) or @pagesize
    @sort_on = @api.get_url_parameter("sort_on")
    @sort_order = @api.get_url_parameter("sort_order")
    @review_state = @api.get_url_parameter("review_state") or @default_review_state

    # column filter parameters from URL
    @column_filters = @parse_json(
      @api.get_url_parameter("column_filters"), {})
    # Keep the editor cells hidden on initial load — funnel icons in
    # the column headers already mark which columns are filtered. The
    # user can click a funnel to open the editor for that column.
    @active_column_filters = []

    # Auto-apply the user's default saved preset only when the URL
    # carries no explicit listing state, so bookmarked share-links
    # win over the personal default.
    @apply_default_preset_unless_url_state()

    # last selected item
    @last_select = null

    @state =
      # alert messages
      messages: []
      # loading indicator
      loading: yes
      # show column config toggle
      show_column_config: no
      # filter, pagesize, sort_on, sort_order and review_state are initially set
      # from the request to allow bookmarks to specific searches
      filter: @filter
      pagesize: @pagesize
      sort_on: @sort_on
      sort_order: @sort_order
      review_state: @review_state
      # The query string is computed on the server and allows to bookmark listings
      query_string: ""
      # The API URL to call
      api_url: ""
      # form_id, columns and review_states are defined in the listing view and
      # passed in via a data attribute in the template, because they can be seen
      # as constant values
      form_id: @form_id
      columns: @get_default_columns()
      review_states: @review_states
      # The data from the folderitems view call
      folderitems: []
      # Mapping of UID -> list of children from the folderitems
      children: {}
      # The categories of the folderitems
      categories: []
      # Expanded categories
      expanded_categories: []
      # selected categories
      selected_categories: []
      # Expanded Rows (currently only Partitions)
      expanded_rows: []
      # Expanded Remarks Rows
      expanded_remarks: []
      # total number of items in the database
      total: 0
      # UIDs of selected rows are stored in selected_uids.
      # These are sent when a transition action is clicked.
      selected_uids: []
      # UIDs (rows) that are in loading state
      loading_uids: []
      # Mapping of UID -> List of error messages
      errors: {}
      # The possible transition buttons
      transitions: []
      # The available catalog indexes for sorting
      catalog_indexes: []
      # The available catalog columns for sorting
      catalog_columns: []
      # The possible sortable columns
      sortable_columns: []
      # ajax save queue: mapping of uid: name -> value mapping
      ajax_save_queue: {}
      # Listing specific configs
      content_filter: {}
      allow_edit: no
      show_select_all_checkbox: no
      show_select_column: no
      show_column_toggles: @show_column_toggles
      select_checkbox_name: "uids"
      post_action: "workflow_action"
      show_categories: no
      expand_all_categories: no
      show_more: no
      limit_from: 0
      show_search: no
      show_ajax_save: no
      show_table_footer: no
      fetch_transitions_on_select: yes
      show_export: yes
      # signal full folderitems refetch in ajax_save
      refetch: false
      # allow to reorder table rows with drag&drop
      allow_row_reorder: yes
      # Lock all action buttons
      lock_buttons: no
      # table row context menu config
      row_context_menu: {}
      # progress bar
      progress: null
      progress_label: null
      # toast notifications
      toasts: []
      # column filters: {columnKey: filterValue}
      column_filters: @column_filters or {}
      # active column filters (which filters are shown)
      active_column_filters: @active_column_filters or []
      # id of the saved preset currently driving the view, if any.
      # The SavedFilters menu uses this both to mark the preset as
      # applied and to compare current state against the preset's
      # stored payload (dirty detection).
      applied_preset_id: @applied_preset_id or null

  ###*
   * Translate the given i18n string
   *
   * @param s {string} String to translate
   * @returns {string} Translated string
  ###
  translate: (s, domain="senaite") ->
    if domain is "plone"
      return window._p(s)
    return window._t(s)

  ###*
   * Dismisses a message by its message index
   *
   * @param index {int} Index of the message to dismiss
   * @returns {bool} true
  ###
  dismissMessage: (index=null) ->
    # dismiss all messages
    if index is null
      @setState {messages: []}
    else
      # dismiss message by index
      messages = [].concat @state.messages
      messages.splice index, 1
      @setState {messages: messages}
    return true

  ###*
   * Display a new bootstrap alert message above the table
   *
   * @param title {string} Title to be displayed in the alert box
   *              {object} Config object for all parameters
   * @param text {string} The message text
   * @param traceback {string} Preformatted traceback
   * @param level {string} info, success, warning, danger
   * @returns {bool} true
  ###
  addMessage: (title, text, traceback, level="info") ->
    if typeof title is "object"
      props = Object.assign title
      title = props.title
      text = props.text
      traceback = props.traceback
      level = props.level

    messages = [].concat @state.messages
    messages.push({
      title: title,
      text: text
      traceback: traceback,
      level: level,
    })
    @setState {messages: messages}
    return true

  ###*
   * Show Bootstrap Toast notification
   *
   * @param message {string} message to show
   * @param title {string} title to show
  ###
  showToast: (message, title=_t("Notification")) ->
    toast =
      id: uuidv4()
      title: title
      message: message
    @setState (prevState) ->
      toasts: [...prevState.toasts, toast]

    # remove message after 5 seconds
    remove = () =>
      console.log "Remove toast ID #{toast.id}"
      @removeToast(toast.id)
    setTimeout(remove, 5000)

  ###*
   * Remove Bootstrap Toast notification by ID
   *
   * @param id {string} ID of the message
  ###
  removeToast: (id) ->
    @setState (prevState) ->
      toasts: prevState.toasts.filter (toast) -> toast.id isnt id


  ###*
   * Show element loader
   *
   * This method renders an overlay in the element with an animated loader
   *
   * @param element {Object} The loading element
  ###
  showLoader: (el = "body") ->
    loader = $('<div class="loader-overlay d-flex justify-content-center align-items-center">
                  <i class="fas fa-spinner fa-spin fa-3x text-primary"></i>
                </div>')
    loader.css
      position: "absolute"
      top: 0
      left: 0
      width: "100%"
      height: "100%"
      background: "rgba(255, 255, 255, 0.5)"
      zIndex: 1051
    # always hide any existing loaders first
    @hideLoader()
    $(el).css("position", "relative").append(loader)


  ###*
   * Hide element loader
   *
   * This method removes the loader from the modal
   *
   * @param element {Object} The loading element
  ###
  hideLoader: (el = "body") ->
    $(el).find('.loader-overlay').remove()


  ###*
   * Set the cursor to loading
   *
   * This method changes the cursor to a loading cursor
   *
   * @param element {Object} The loading element
  ###
  setLoadingCursor: (el = "body") ->
    $(el).css("cursor", "wait")


  ###*
   * Unset the cursor to loading
   *
   * This method changes the loading cursor back to normal
   *
   * @param element {Object} The loading element
  ###
  resetLoadingCursor: (el = "body") ->
    $(el).css("cursor", "")


  ###*
   * Load a listing action asynchronously
   *
   * @param url {string} URL to load
   * @param reload {boolean} reload folderitems if true
  ###
  ajaxLoadActionURL: (url, reload=yes) ->
    me = this

    # turn loader on
    @toggle_loader on

    fetch(url, { method: "GET" })
      .then (response) ->
        return response.json()
      .then (json) ->
        if reload then me.fetch_folderitems()
        me.showToast(json.message, title=json.title)
        me.toggle_loader off
      .catch (error) ->
        me.showToast("Action failed: ", error)
        me.toggle_loader off

  ###*
   * Parameters to be sent in each Ajax POST request
   * @returns {object} current state values
  ###
  getRequestOptions: ->
    options =
      "review_state": @state.review_state
      "filter": @state.filter
      "sort_on": @state.sort_on
      "sort_order": @state.sort_order
      "pagesize": @state.pagesize
      "limit_from": @state.limit_from
      "selected_uids": @state.selected_uids
      "column_filters": @state.column_filters

    console.debug("Request Options=", options)
    return options

  ###*
   * ReactJS event handler when the component did mount
   * Fetches the initial folderitems
  ###
  componentDidMount: ->
    window.addEventListener("popstate", @on_popstate, false);
    @fetch_folderitems().then (data) =>
      # send a listing loaded event as soon as the folderitems are initially loaded
      @trigger_event "listing:loaded",
       form_id: @form_id
       root_el: @root_el
       data: data
    @root_el.addEventListener("click", @on_click)
    window.senaite.core.listings[@form_id] = @


  ###*
   * ReactJS event handler when the component unmounts
  ###
  componentWillUnmount: ->
    window.removeEventListener("popstate", @on_popstate, false);
    @root_el.removeEventListener("click", @on_click)

  ###*
   * componentDidUpdate(prevProps, prevState, snapshot)
   *
   * This is invoked immediately after updating occurs.
   * This method is not called for the initial render.
  ###
  componentDidUpdate: (prevProps, prevState, snapshot) ->

  ###
   * Toggle the loading state of an UID (row)
   *
   * @param uid {string} UID of the item
   * @returns {bool} true if the UID was added set in loading state, otherwise false
  ###
  toggleUIDLoading: (uid, toggle) ->
    console.debug "ListingController::toggleRowLoading: uid=#{uid}"

    # skip if no uid is given
    return false unless uid

    # get the current expanded rows
    loading_uids = @state.loading_uids

    # check if the current UID is in there
    index = loading_uids.indexOf uid
    # set the default toggle flag value to "on" if the UID is not in the array
    toggle ?= index == -1

    if index > -1
      # remove the UID if the toggle flag is set to "off"
      if not toggle then loading_uids.splice index, 1
    else
      # add the UID if the toggle flag is set to "on"
      if toggle then loading_uids.push uid

    @setState {loading_uids: loading_uids}

  ###*
   * Add an error message for a given UID
   *
   * @param uid {string} UID of the object
   * @param message {string} Error message
   * @returns {bool} true if the error message was set
  ###
  setErrors: (uid, message) ->
    if not (uid? or message?)
      return false

    message ?= ""

    if not uid?
      # display global error message
      title = _t("Oops, an error occured! 🙈")
      return @addMessage title, message, null, level="danger"

    # append the message to the given UID
    errors = @state.errors
    messages = errors[uid] or []
    if message.length > 0 and messages.indexOf(message) < 0
      messages = messages.concat message
    errors[uid] = messages
    @setState {errors: errors}

  ###*
   * Flush error messages for a given UID (or all)
   *
   * @param uid {string} UID of the object
  ###
  flushErrors: (uid) ->
    errors = @state.errors
    if not uid?
      # flush all errors
      errors = {}
      @dismissMessage()
    else
      # flush error messages for the given UID
      errors[uid] = []
    @setState {errors: errors}

  ###*
   * Expand/Collapse a listing category row by adding the category ID to the
   * state `expanded_categories`
   *
   * @param category {string} Title of the category
   * @returns {bool} true if the category was expanded, otherwise false
  ###
  toggleCategory: (category) ->
    console.debug "ListingController::toggleCategory: category=#{category}"

    # get the current expanded categories
    expanded = @state.expanded_categories
    # check if the current category is in there
    index = expanded.indexOf category

    if index > -1
      # remove the category
      expanded.splice index, 1
    else
      # add the category
      expanded.push category

    # set the new expanded categories
    @setState {expanded_categories: expanded}
    return expanded.length > 0

  ###*
   * Select/Deselect all items within a category
   *
   * @param category {string} Title of the category
   * @returns {bool} true if the category was selected, otherwise false
  ###
  selectCategory: (category) ->
    console.debug "ListingController::selectCategory: category=#{category}"

    # unique set of current selected category names
    selected = new Set(@state.selected_categories)

    if selected.has category
      # remove the category
      selected.delete category
    else
      # add the category
      selected.add category

    # set the new selected categories
    @setState
      selected_categories: Array.from(selected)

    return selected.has category

  ###*
   * Expand/Collapse remarks
   *
   * @param uid {string} UID of the item
   * @returns {bool} true if the remarks were expanded, otherwise false
  ###
  toggleRemarks: (uid) ->
    console.debug "ListingController::toggleRemarks: uid=#{uid}"

    # skip if no uid is given
    return false unless uid

    # get the current expanded remarks
    expanded = @state.expanded_remarks

    # check if the current UID is in there
    index = expanded.indexOf uid

    if index > -1
      # remove the UID
      expanded.splice index, 1
    else
      # add the UID
      expanded.push uid

    # set the new expanded remarks
    @setState {expanded_remarks: expanded}
    return expanded.length > 0

  ###
   * Expand/Collapse the row
   *
   * @param uid {string} UID of the item
   * @returns {bool} true if the row was expanded, otherwise false
  ###
  toggleRow: (uid) ->
    console.debug "ListingController::toggleRow: uid=#{uid}"

    # skip if no uid is given
    return false unless uid

    # get the current expanded rows
    expanded = @state.expanded_rows

    # check if the current row is in there
    index = expanded.indexOf uid

    if index > -1
      # remove the category
      expanded.splice index, 1
    else
      # add the category
      expanded.push uid

    # check if the children are already fetched
    me = this
    if uid not of @state.children
      promise = @fetch_children parent_uid: uid
      promise.then (data) ->
        children = me.state.children
        item_children = data.children or []
        children[uid] = item_children
        for child in item_children
          if child.selected
            me.selectUID child.uid, yes
        me.setState
          children: children
          expanded_rows: expanded
    else
      # set the new expanded categories
      @setState {expanded_rows: expanded}

    return expanded.length > 0

  ###*
   * Toggle the visibility of a column by its column key.
   *
   * This method also stores the visibility of the column in the browser's
   * localstorage.
   *
   * @param key {string} The ID of the column, or "reset" to restore all columns
   * @returns {bool} true if the column was expanded, otherwise false
  ###
  toggleColumn: (key) ->
    console.debug "ListingController::toggleColumn: key=#{key}"
    config = @_merged_column_config()
    next_config = toggle_in config, key
    @_persist_column_config next_config

    # Mirror the visibility flag onto @state.columns so consumers that
    # read column.toggle directly stay in sync. Only the changed
    # column is reallocated; every other entry shares its old object
    # reference, so React.memo'd children skip re-renders.
    column = @state.columns[key]
    return unless column?
    visible = visibility_from(next_config)[key]
    @setState columns: Object.assign({}, @state.columns,
      "#{key}": Object.assign({}, column, toggle: visible))
    return visible

  ###*
   * Reset all column visibility + order back to the server defaults
   * and drop the local-storage record.
  ###
  resetColumns: ->
    console.debug "ListingController::resetColumns"
    clear_column_config @get_storage_id()
    @setState {columns: @get_default_columns()}
    return true

  ###*
   * Handle context menu action
  ###
  handleRowMenuAction: (id, url, item) ->
    # either use the already selected UIDs or, if nothing is selected, the UIDs
    # from the row item where the context menu was opened.
    # N.B. Transposed folderitems might contain multiple folderitems/UIDs!
    uids = @get_uids_from([item])
    if @state.selected_uids.length > 0
      uids = [].concat(@state.selected_uids)
    # execute the transition
    @doAction(id, url, uids)

  ###*
   * Displays a context menu with all possible transitions for the clicked row
   *
   * Callback triggered by row onContextMenu handler (see TableRows.js)
  ###
  showRowMenu: (event, item) ->
    event.preventDefault()

    # show a loading cursor
    @setLoadingCursor(@root_el)

    # https://fkhadra.github.io/react-contexify/api/use-context-menu
    menu = useContextMenu({
      id: @row_context_menu_id
    })

    uids = []
    if @state.selected_uids.length > 0
      # operate on selected UIDs
      uids = @state.selected_uids
    else
      # extract UIDs of the folderitem (including transposed items)
      uids = @get_uids_from([item])

    # get the folderitems of the selected UIDS
    folderitems = @get_folderitems().filter((item) -> item.uid in uids)

    @fetch_transitions(uids, loader=no).then (data) =>
      transitions = []

      # inject save button
      if @state.show_ajax_save
        transitions.unshift({
          "id": "save"
          "title": "Save"
        })
      transitions = transitions.concat(data.transitions)

      configurations = []
      if @state.fetch_transitions_on_select
        configurations.push({
          "id": "toggle_auto_fetch_transitions"
          "title": "Disable auto fetch transitions"
        })
      else
        configurations.push({
          "id": "toggle_auto_fetch_transitions"
          "title": "Enable auto fetch transitions"
        })
      configurations.push({
        "id": "reset_columns"
        "title": "Reset columns"
      })

      # build context menu state config
      new_state = {
        row_context_menu: {
          folderitems: folderitems
          transitions: transitions
          actions: [
            {
              id: "all",
              title: "Select all"
            }, {
              id: "clear_selection",
              title: "Deselect all"
            }, {
              id: "fetch_transitions",
              title: "Fetch Transitions"
            }, {
              id: "reload",
              title: "Reload"
            }

          ]
          configurations: configurations
        }
      }

      # Transitions are set by the fetch_transitions method.
      # If auto fetch is disabled, we do not want to set them implicitly.
      if not @state.fetch_transitions_on_select
        new_state["transitions"] = []

      # set the new state and show the context menu afterwards
      @setState new_state, =>
        # show a loading cursor
        @resetLoadingCursor(@root_el)
        # show the context menu
        queueMicrotask(() =>
          menu.show(
            event: event
            props:
              item: item
          )
        )

  ###*
   * Move the table row by the given indexes
  ###
  moveRow: (index_from, index_to) ->
    source_folderitem = @state.folderitems[index_from]
    folderitems = [].concat @state.folderitems
    target_folderitem = folderitems.splice(index_to, 1, source_folderitem)
    folderitems.splice(index_from, 1, target_folderitem[0])
    @setState {folderitems: folderitems}

  ###*
   * Update the order of all columns
   *
   * This method also stores the order of the columns in the browser's
   * localstorage.
   *
   * @param order {array} Array of column IDs to be used as new order
   * @returns {object} New ordered columns object
  ###
  setColumnsOrder: (order) ->
    console.debug "ListingController::setColumnsOrder: order=", order
    next_config = reorder_in @_merged_column_config(), order
    @_persist_column_config next_config

    # Rebuild @state.columns in the new key order so consumers that
    # iterate Object.keys / Object.entries see the reordered set.
    next_columns = {}
    for {key} in next_config
      column = @state.columns[key]
      next_columns[key] = column if column?
    @setState {columns: next_columns}
    return next_columns

  ###*
   * Compute the merged column config (stored config reconciled with
   * current server-defined columns).  The pure helper auto-appends
   * new add-on columns and drops vanished ones.
   *
   * Internal — call sites should use the public get_columns* methods.
  ###
  _merged_column_config: ->
    # Pass the full columns dict (not just the keys) so the merge
    # helper can honor the server's default `toggle` for columns the
    # user has never customised.  Skipping this caused every column
    # to appear visible on first load, even ones the server marked
    # `toggle: false` by default.
    #
    # Visibility filtering by review_state still happens later in
    # get_visible_columns — every server-defined key stays in the
    # merged config so downstream consumers (e.g. TableTransposedCell)
    # can still look columns up by key.
    stored = read_column_config @get_storage_id()
    return merge_column_config stored, (@state.columns or {})

  _persist_column_config: (config) ->
    write_column_config @get_storage_id(), config

  ###*
   * Returns all column keys where the visibility toggle is true and
   * the column is allowed in the current review_state.
   *
   * @returns columns {array} Array of ordered and visible column keys
  ###
  get_visible_columns: ->
    config = @_merged_column_config()
    allowed = new Set @get_allowed_column_keys()
    return (entry.key for entry in config when entry.toggle and allowed.has(entry.key))

  ###*
   * Get the default columns (server-defined, no local customisation).
  ###
  get_default_columns: ->
    return JSON.parse @root_el.dataset.columns

  ###*
   * Get columns in the right order and visibility.  The result is an
   * ordered dict (insertion-ordered object) of {key: column} where
   * each column object carries the resolved `toggle` flag.
  ###
  get_columns: ->
    columns = {}
    for entry in @_merged_column_config()
      column = @state.columns[entry.key]
      continue unless column?
      columns[entry.key] = Object.assign {}, column, {toggle: entry.toggle}
    return columns

  ###*
   * Keys defined server-side, regardless of customisation.
  ###
  get_columns_keys: ->
    return Object.keys @state.columns

  ###*
   * Return the order of all columns, taking the local column config
   * into consideration.
  ###
  get_columns_order: ->
    return column_keys_from @_merged_column_config()

  ###*
   * Return the set visibility of all columns (merged config).
  ###
  get_columns_visibility: ->
    return visibility_from @_merged_column_config()

  ###*
   * Filter the results by the given state
   *
   * This method executes an Ajax request to the server.
   *
   * @param review_state {string} The state to filter, e.g. verified, published
   * @returns {bool} true
  ###
  ###*
   * Listing parameters that participate in saved presets and in the
   * "URL state present?" detection used during auto-apply.
  ###
  PRESET_URL_PARAMS: [
    "filter", "review_state", "column_filters",
    "sort_on", "sort_order", "pagesize", "labels"
  ]

  ###*
   * Parse the active labels filter from the page URL.
   *
   * The labels filter lives outside the form_id-prefixed listing state
   * (review_state, sort, etc.) on the plain ``?labels=…`` query
   * parameter so it can be shared / bookmarked as a SENAITE-wide
   * cross-listing filter.
   *
   * @returns {Array<string>} sorted unique non-empty label names
  ###
  get_url_labels: ->
    params = new URLSearchParams window.location.search
    raw = (params.getAll "labels")
      .reduce ((acc, v) -> acc.concat v.split ","), []
      .map (s) -> s.trim()
      .filter (s) -> s.length > 0
    seen = {}
    raw.filter (s) ->
      return no if seen[s]
      seen[s] = yes
      yes

  ###*
   * Build a URL that replaces the active labels filter with the given
   * list. Preserves all other URL parameters and the hash fragment.
   *
   * @param labels {Array<string>}
   * @returns {string}
  ###
  build_labels_url: (labels) ->
    params = new URLSearchParams window.location.search
    params.delete "labels"
    if labels and labels.length
      params.set "labels", labels.join ","
    qs = params.toString()
    url = window.location.pathname
    url += "?" + qs if qs
    url += window.location.hash if window.location.hash
    return url

  ###*
   * Fetch and cache the available labels (name → color map).
   *
   * The fetch is lazy-fired the first time
   * ``render_active_label_filters`` runs; once it resolves the
   * controller forces a re-render so the chips paint in their
   * canonical color.
  ###
  ensure_label_colors_loaded: ->
    return if @_label_colors_promise
    me = this
    @_label_colors_promise = fetch "./@@senaite_labels/available",
      credentials: "same-origin"
      headers:
        "X-Requested-With": "XMLHttpRequest"
        "Accept": "application/json"
    .then (response) ->
      return {} unless response.ok
      response.json().then (data) ->
        out = {}
        for label in (data.labels or [])
          out[label.name] = label.color or ""
        out
    .then (map) ->
      me._label_colors = map
      me.forceUpdate?()
      map
    .catch ->
      me._label_colors = {}
      {}

  get_label_color: (name) ->
    return "" unless @_label_colors
    @_label_colors[name] or ""

  ###*
   * Render the active labels filter as a row of removable chips
   * shown right before the search box. Each chip is painted in the
   * color of its Label content type so the inline filter chip
   * matches the row chips of the same name.
  ###
  render_active_label_filters: ->
    labels = @get_url_labels()
    return null unless labels.length
    @ensure_label_colors_loaded()
    me = this
    on_remove = (label) -> (event) ->
      event.preventDefault()
      next = labels.filter (l) -> l != label
      # In-place URL update + refetch so the rest of the listing
      # state (preset id, column filters, ...) survives the chip
      # removal.
      window.history.replaceState null, "", me.build_labels_url next
      me.fetch_folderitems()
      me.forceUpdate?()
    <div className="active-label-filters">
      {labels.map (label) ->
        color = me.get_label_color label
        chip_style = if color
          backgroundColor: color
          borderColor: color
          color: "#fff"
        else
          null
        <span key={"label-" + label}
              className="active-label-filter"
              style={chip_style}>
          <span className="active-label-filter__name">{label}</span>
          <button type="button"
                  className="active-label-filter__remove"
                  title={_t("Remove filter")}
                  onClick={on_remove(label)}>×</button>
        </span>
      }
    </div>

  ###*
   * localStorage scope key for saved presets and other per-listing
   * client-side state.
   *
   * Prefers `listing_identifier` (calculated server-side per listing
   * kind — e.g. "AnalysisRequestsListing" for the global samples
   * folder vs the per-client folder, "Batch", "Worksheet", …) so
   * presets do not bleed between unrelated listings that happen to
   * reuse the same `form_id` ("folder_contents" et al). Falls back
   * to `form_id` only when no identifier is provided.
   *
   * @returns {string}
  ###
  get_storage_id: ->
    return @listing_identifier or @form_id

  ###*
   * Auto-apply the user's default saved preset on first mount —
   * unless the URL already carries explicit listing state, so a
   * bookmarked share-link still wins.
   *
   * Mutates @filter / @review_state / @column_filters / @sort_on /
   * @sort_order / @pagesize / @applied_preset_id in place; intended
   * to be called from the constructor before @state is built.
  ###
  apply_default_preset_unless_url_state: ->
    for name in @PRESET_URL_PARAMS
      if @api.get_url_parameter(name) != ""
        return  # URL state wins
    preset = find_default_preset(@get_storage_id())
    return unless preset?.payload
    payload = preset.payload
    # Push the preset's labels into the URL `?labels=` filter so the
    # first folderitems fetch carries them (api.coffee#get_api_url
    # reads location.search fresh). React state (@filter,
    # @review_state, ...) is mutated below and picked up when
    # @state is built; labels live outside React state by design.
    saved_labels = if Array.isArray(payload.labels) then payload.labels else []
    if saved_labels.length
      window.history.replaceState null, "", @build_labels_url saved_labels
    @filter = payload.filter or @filter
    @review_state = payload.review_state if payload.review_state
    if payload.column_filters
      @column_filters = Object.assign {}, payload.column_filters
      # keep editor cells closed; the funnel icons mark filtered cols
      @active_column_filters = []
    @sort_on = payload.sort_on if payload.sort_on
    @sort_order = payload.sort_order if payload.sort_order
    @pagesize = payload.pagesize if payload.pagesize
    @applied_preset_id = preset.id
    return

  ###*
   * Apply a saved filter preset
   *
   * Replaces the current review_state, column_filters, sort, pagesize
   * and search term in one go and triggers a single refetch.
   *
   * @param preset {object} preset object from localStorage
   * @returns {bool} true
  ###
  applySavedFilter: (preset={}) ->
    console.debug "ListingController::applySavedFilter: preset=", preset
    payload = preset.payload or {}
    # Sync the URL `?labels=` query without a full reload so the
    # preset's other state (review_state, filter, sort, ...) and the
    # `applied_preset_id` marker survive the apply. The next
    # folderitems fetch reads `location.search` fresh (see
    # api.coffee#get_api_url), so the new label set takes effect on
    # the refetch triggered by `set_state` below.
    saved_labels = if Array.isArray(payload.labels) then payload.labels else []
    url_labels = @get_url_labels()
    saved_sorted = [].concat(saved_labels).sort()
    url_sorted = [].concat(url_labels).sort()
    if saved_sorted.join(",") != url_sorted.join(",")
      window.history.replaceState null, "", @build_labels_url saved_labels
    # Do not open the column-filter editor cells on preset apply. The
    # filter is in effect via column_filters and the header funnel
    # already marks the column as filtered.
    @set_state
      review_state: payload.review_state or @default_review_state
      column_filters: Object.assign {}, payload.column_filters or {}
      active_column_filters: []
      filter: payload.filter or ""
      sort_on: payload.sort_on or @state.sort_on
      sort_order: payload.sort_order or @state.sort_order
      pagesize: payload.pagesize or @pagesize
      limit_from: 0
      applied_preset_id: preset.id or null
    return true

  ###*
   * Release the currently applied preset and reset the view in one
   * step. The user asked for a clean slate, not a half-applied view
   * they would have to clear by hand.
   *
   * @returns {bool} true
  ###
  clearAppliedPreset: ->
    console.debug "ListingController::clearAppliedPreset (→ resetView)"
    return @resetView()

  ###*
   * Reset the listing to its initial state — drops every filter,
   * the search term, the sort, the active preset, and resets the
   * review state to its default. Triggers one refetch.
   *
   * @returns {bool} true
  ###
  resetView: ->
    console.debug "ListingController::resetView"
    # Drop the cross-listing labels filter from the URL in place,
    # without a full reload, so the rest of the reset (set_state
    # below) still runs in this turn.
    if @get_url_labels().length
      window.history.replaceState null, "", @build_labels_url []
    @set_state
      review_state: @default_review_state
      column_filters: {}
      active_column_filters: []
      filter: ""
      sort_on: ""
      sort_order: ""
      pagesize: @pagesize
      limit_from: 0
      applied_preset_id: null
    return true

  filterByState: (review_state="default") ->
    console.debug "ListingController::filterByState: review_state=#{review_state}"
    state = @get_review_state_by_id review_state
    content_filter = state.contentFilter or {}
    # allow to update the listing config per state
    state_listing_config = state.listing_config or {}
    @set_state Object.assign
      review_state: review_state
      pagesize: @pagesize  # reset to the initial pagesize on state change
      sort_on: content_filter.sort_on or @state.sort_on
      sort_order: content_filter.sort_order or @state.sort_order
      limit_from: 0
    , state_listing_config
    return true

  ###*
   * Filter the results by the given searchterm
   *
   * This method executes an Ajax request to the server.
   *
   * @param filter {string} An arbitrary search string
   * @returns {bool} true
  ###
  filterBySearchterm: (filter="") ->
    console.debug "ListingController::filterBySearchter: filter=#{filter}"
    # Peel `label:Foo` / `labels:Foo,Bar` tokens out of the search
    # term and treat them as URL ?labels= filters (additive). What
    # remains becomes the regular search filter.
    parsed = @parse_label_search_prefixes filter
    if parsed.labels.length
      current = @get_url_labels()
      merged = current.slice()
      for name in parsed.labels
        merged.push name unless name in merged
      window.history.replaceState null, "", @build_labels_url merged
    @set_state
      filter: parsed.residual
      pagesize: @pagesize  # reset to the initial pagesize on search
      limit_from: 0
    return true

  ###*
   * Extract `label:Foo` / `labels:Foo,Bar` tokens from a search
   * term. Returns an object with the list of labels found and the
   * residual search string (the tokens that were not label prefixes,
   * rejoined with single spaces).
   *
   * Whitespace inside a single quoted token is not supported — the
   * parser splits on /\s+/. Names containing spaces should be added
   * via chip click instead.
   *
   * @param term {string} the raw search box value
   * @returns {{labels: string[], residual: string}}
  ###
  parse_label_search_prefixes: (term) ->
    labels = []
    residual = []
    seen = {}
    for tok in (term or "").split /\s+/
      m = tok.match /^labels?:(.+)$/i
      if m
        for raw in m[1].split ","
          name = raw.trim()
          continue if not name
          continue if seen[name]
          seen[name] = yes
          labels.push name
      else if tok
        residual.push tok
    {labels: labels, residual: residual.join(" ")}

  ###*
   * Sort a column with a specific order
   *
   * This method executes an Ajax request to the server.
   *
   * @param sort_on {string} Sort index, e.g. getId, created
   * @param sort_order {string} Sort order, e.g. ascending, descending
   * @returns {bool} true
  ###
  sortBy: (sort_on, sort_order) ->
    console.debug "sort_on=#{sort_on} sort_order=#{sort_order}"
    @set_state
      sort_on: sort_on
      sort_order: sort_order
      pagesize: @get_item_count() # keep the current number of items on sort
      limit_from: 0
    return true

  ###*
   * Toggle visibility of column filter input
   *
   * @param column_key {string} The column key to toggle filter for
   * @returns {bool} true
  ###
  toggleColumnFilter: (column_key) ->
    console.debug "ListingController::toggleColumnFilter: key=#{column_key}"

    # Get current active filters
    active_filters = [].concat @state.active_column_filters

    # Check if the filter is already active
    index = active_filters.indexOf column_key

    if index > -1
      # Remove the filter
      active_filters.splice index, 1
      # Also clear the filter value
      had_value = !!@state.column_filters[column_key]
      column_filters = Object.assign {}, @state.column_filters
      delete column_filters[column_key]
      @setState
        active_column_filters: active_filters
        column_filters: column_filters
      , =>
        if had_value
          @fetch_folderitems()
    else
      # Add the filter
      active_filters.push column_key
      @setState
        active_column_filters: active_filters

    return true

  ###*
   * Handle column filter value change
   *
   * @param column_key {string} The column key
   * @param value {string} The filter value
   * @returns {bool} true
  ###
  onColumnFilterChange: (column_key, value) ->
    console.debug "ListingController::onColumnFilterChange: " +
                  "key=#{column_key} value=#{value}"

    column_filters = Object.assign {}, @state.column_filters
    if value
      column_filters[column_key] = value
    else
      delete column_filters[column_key]

    @setState
      column_filters: column_filters

    return true

  ###*
   * Submit column filters and refetch results
   *
   * @returns {bool} true
  ###
  onColumnFilterSubmit: () ->
    console.debug "ListingController::onColumnFilterSubmit"
    @set_state
      pagesize: @pagesize  # reset to initial pagesize on filter
      limit_from: 0
    return true

  ###*
   * Show more results
   *
   * This method executes an Ajax request to the server.
   *
   * @param pagesize {int} The amount of additional items to request
   * @returns {bool} true
  ###
  showMore: (pagesize) ->
    console.debug "ListingController::showMore: pagesize=#{pagesize}"

    # the existing folderitems
    folderitems = @state.folderitems
    # set of current selected UIDs
    selected_uids = new Set(@state.selected_uids)

    me = this
    @setState
      pagesize: parseInt pagesize
      limit_from: @state.folderitems.length
      loading: yes
    , ->
      # N.B. we're using limit_from here, so we must append the returning
      #      folderitems to the existing ones
      promise = me.api.fetch_folderitems me.getRequestOptions()
      promise.then (data) ->
        me.toggle_loader off
        if data.folderitems.length > 0
          console.debug "Adding #{data.folderitems.length} more folderitems..."
          # update selected UIDs from the server
          for item in data.folderitems
            if item.selected
              selected_uids.add item.uid
          # append the new folderitems to the existing ones
          new_folderitems = folderitems.concat data.folderitems
          # array of new selected UIDs
          new_selected_uids = Array.from selected_uids

          me.setState
            folderitems: new_folderitems
            selected_uids: new_selected_uids
    return true

  ###
  Export the current displayed items to a CSV
  ###
  export: ()  ->
    console.debug "ListingController::export"

    # Column keys, sorted properly
    columns_keys = @get_columns_order()

    # Only interested in visible columns
    columns_visibility = @get_columns_visibility()
    columns_keys = (col for col in columns_keys when columns_visibility[col] is yes)

    # Generate the header
    columns = @get_columns()
    header = (JSON.stringify columns[key]["title"] or key for key in columns_keys)

    # Generate the list of rows
    folderitems = @state.folderitems
    rows = (@to_csv_row(item, columns_keys) for item in folderitems)

    # Join all together
    csv = header.join ","
    csv = csv + "\n" + rows.join "\n"
    @download_csv csv, "download.csv"

  ###
  Triggers the download of the csv
  ###
  download_csv: (csv, filename) ->
    universalBOM = "\uFEFF"
    csv_properties =
      encoding: "UTF-8"
      type: "text/csv;charset=UTF-8"

    csv_file = new Blob [universalBOM, csv], csv_properties
    down_link = document.createElement "a"
    down_link.download = filename
    down_link.href = window.URL.createObjectURL csv_file
    down_link.display = "none"
    document.body.appendChild down_link
    down_link.click()

  ###
  Converts the item to a well-formed csv row
  ###
  to_csv_row: (item, columns) ->
    cells = []
    console.debug item
    for column in columns

      cell = item[column] or ""
      if column == "Result"
        # Give priority to formatted_result
        cell = item.formatted_result or cell

      else if cell.constructor == Object
        # Handle interim fields gracefully
        cell = cell.formatted_value or cell.value

      if item.choices?
        # Handle choices
        choices = item.choices[column]
        if choices?
          choice = (c.ResultText for c in choices when c.ResultValue == cell)
          cell = choice[0] or cell

      cell = JSON.stringify cell
      cells.push cell
    cells.join(',')


  ###*
   * Load modal popup
   *
   * This method renders a modal window with the HTML loaded from the URL
   *
   * @param url {string} The form action URL
   * @param event {object} ReactJS event object
  ###
  loadModal: (url, selected_uids) ->
    el = $("#modal_#{@form_id}")

    # make it draggable
    el.draggable()

    # allow to override selected uids
    selected_uids ?= @state.selected_uids

    url = new URL(url)
    url.searchParams.append("uids", selected_uids)

    # submit callback
    on_submit = (event) =>
      event.preventDefault()
      form = event.target

      if not form.action
        console.error "Modal form has no action defined"
        return

      # show the loader in the modal content
      content = el.find(".modal-content")
      @showLoader(content)

      # process form submit
      fetch form.action,
        method: "POST",
        body: new FormData(form)
      .then (response) =>
        if not response.ok
          return Promise.reject(response)
        return response.text().then (text) =>
          # allow redirects when the modal form returns an URL
          if text.startsWith("http")
            window.location = text
          else
            @fetch_folderitems()
      .catch (error) =>
        @on_api_error(error)
      .finally =>
        # always hide the loader and modal
        @hideLoader(content)
        el.modal("hide")

    request = new Request(url)
    fetch(request)
    .then (response) ->
      return response.text().then (text) ->
        el.empty()
        el.append(text)
        el.one "submit", on_submit
        el.modal("show")

  ###*
   * Execute an action
   *
   * @param id {string} The workflow action id
   * @param url {string} The form action URL
   * @param url {array} List of affected UIDs
   * @returns form submission
  ###
  doAction: (id, url, selected_uids) ->

    # perform action on selected uids
    selected_uids ?= @state.selected_uids

    # handle local actions directly
    switch id
      when "save" then return @saveAjaxQueue()
      when "reload" then return @fetch_folderitems()
      when "fetch_transitions" then return @fetch_transitions(selected_uids)
      when "clear_selection" then return @selectUID("all", off)
      when "all"
        return @selectUID("all", on).then () =>
          if @state.fetch_transitions_on_select
            @fetch_transitions()
      when "toggle_auto_fetch_transitions"
        toggle = not @state.fetch_transitions_on_select
        return @setState
          fetch_transitions_on_select: toggle
          transitions: []
      when "reset_columns" then return @resetColumns()

    # load action in modal popup if id starts/ends with `modal`
    if id.startsWith("modal") or id.endsWith("modal_transition")
      @loadModal url, selected_uids
      return

    # N.B. Transition submit buttons are suffixed with `_transition`, because
    #      otherwise the form.submit call below retrieves the element instead of
    #      doing the method call.
    action = id.split("_transition")[0]

    # Process configured transitions sequentially via ajax
    if @enable_ajax_transitions and action in @active_ajax_transitions
      # sort UIDs according to the list
      sorted_uids = []
      for item in @get_folderitems()
        if item.uid in selected_uids
          sorted_uids.push item.uid
      # execute transitions
      return @ajax_do_transition_for(sorted_uids, action)

    ###
     Classic Form Submission
    ###

    # get the form element
    form = document.getElementById(@state.form_id)

    # Ensure all previous added hidden fields are removed
    document.querySelectorAll("input[name='workflow_action_id']", form).forEach (input) ->
      input.remove()
    document.querySelectorAll("input[name='form_id']", form).forEach (input) ->
      input.remove()

    # Make sure all checkboxes for the selected UIDs are checked
    # => this happens when a transition is triggered from the context menu directly on the row
    selected_uids.forEach (uid) =>
      input = document.querySelector("input[value='#{uid}']")
      input.checked = yes

    # inject hidden fields for workflow action adapters
    action_id_input = @create_input_element "hidden", id, "workflow_action_id", action
    form.appendChild action_id_input

    form_id_input = @create_input_element "hidden", "form_id", "form_id", @state.form_id
    form.appendChild form_id_input

    # Override the form action when a custom URL is given
    if url then form.action = url

    # Submit the form
    form.submit()

  ###*
   * Transition multiple UIDs batchwise
   *
   * @param form {element} The form to post
  ###
  ajax_do_transition_for: (uids, transition) ->
    # lock the buttons
    @setState lock_buttons: yes
    # total number of numbers to process
    total = uids.length
    # combined redirect URL of all transitions
    redirect_url = ""
    # always save pending items of the save_queue
    promise = @saveAjaxQueue().then (data) =>
      chain = Promise.resolve()
      uids.forEach (uid, index) =>
        # flush previous errors
        @flushErrors uid
        chain = chain.then () =>
          # toggle row loading on
          @toggleUIDLoading uid, on
          api_call = @api.do_action_for
            uids: [uid]
            chained_uids: uids
            transition: transition
          api_call.then (data) =>
            # handle eventual errors
            message = data.errors[uid]
            if message
              # display an error for the given UID
              @setErrors uid, message

            # generate redirect url
            redirect_url = @api.combine_urls(redirect_url, data.redirects[uid])

            # folderitems of the updated objects and their dependencies
            folderitems = data.folderitems or []
            # update the existing folderitems
            @update_existing_folderitems_with folderitems
            # toggle row loading off
            @toggleUIDLoading uid, off
            # update the progress bar
            count = index + 1
            transition_title = transition.charAt(0).toUpperCase() + transition.slice(1)
            label = "#{window._t(transition_title)}: #{count}/#{total}"
            @set_progress count, total, label

      # all objects transitioned
      chain.then () =>
        # reset progress counter
        @reset_progress()
        # redirect
        if redirect_url
          return window.location.href = redirect_url
        # fetch transitions
        if @state.fetch_transitions_on_select
          @fetch_transitions()
        # unlock the buttons
        @setState lock_buttons: no
        # check if the whole site needs to be reloaded, e.g. if all analyses are
        # submitted or verified etc.
        promise = @api.fetch_listing_config()
        promise.then (config) =>
          # send after-transition event to update e.g. the transition menu or reload the whole page.
          # see: senaite.core.js for event handler
          @trigger_event "listing:after_transition_event",
            uids: uids
            transition: transition
            config: config
            folderitems: @state.folderitems

    return promise

  ###*
   * Trigger a named event
   *
   * @param {String} event_name: The name of the event to dispatch
   * @param {Object} event_data: The data to send with the event
  ###
  trigger_event: (event_name, event_data, el) ->
    # Trigger a custom event
    el ?= document.body
    event = new CustomEvent event_name,
      detail: event_data
      bubbles: yes
    el.dispatchEvent event


  ###*
   * JSON parse the given value
   *
   * @param {String} value: The JSON value to parse
  ###
  parse_json: (value, default_value) ->
    try
      return JSON.parse(value)
    catch
      return default_value


  ###*
   * Creates an input element with the attributes passed-in
   *
   * @param type {string} The type of the input element
   * @param id {string} The id of the input element
   * @param name {string} The name of the input element
   * @param value {string} The value of the input element
   * @returns {object} html input element
  ###
  create_input_element: (type, id, name, value) ->
    input = document.createElement "input"
    input.setAttribute "type", type
    input.setAttribute "id", id
    input.setAttribute "name", name
    input.setAttribute "value", value
    return input

  ###*
   * Returns the folderitems of the state
   *
   * @returns {array} copy of folderitems
  ###
  get_folderitems: (folderitems) ->
    items = []

    folderitems ?= @state.folderitems
    for folderitem in folderitems
      # regular folderitem
      if not folderitem.transposed_keys
        items = items.concat folderitem
        continue
      # transposed folderitem
      for key in folderitem.transposed_keys
        transposed = folderitem[key]
        items = items.concat transposed

    return items

  ###*
   * Select folder items where the filter predicate returns true
   *
   * This method also selects/deselects the categories of the toggled items
   *
   * @param items {Array} Array of folderitems
   * @param predicate {Function} Filter function for folderitems to select/deselect
   * @param toggle {bool} true for select, false for deselect
   * @returns {Promise} Resolved when the state was sucessfully set
  ###
  selectItems: (items, predicate, toggle) ->
    items ?= @get_folderitems()
    predicate ?= (item) -> true
    toggle ?= yes

    # the current selected UIDs
    selected_uids = new Set(@state.selected_uids)
    # the current selected Categories
    selected_categories = new Set(@state.selected_categories)
    # the current expanded Categories
    expanded_categories = new Set(@state.expanded_categories)

    # filter items to select/deselect
    items = items.filter (item) ->
      # always skip disabled/readonly items
      if item.disabled or item.readonly
        return false
      return predicate(item)

    # extract the UIDs
    uids = items.map (item, index) -> item.uid
    # extract the categories
    categories = new Set(items.map (item, index) -> item.category or null)
    # remove empty category
    categories.delete(null)

    if toggle
      # select the UIDs
      uids.forEach (uid) -> selected_uids.add(uid)
      # select and expand the categories
      categories.forEach (category) ->
        selected_categories.add(category)
        expanded_categories.add(category)
    else
      # deselect the UIDs
      uids.forEach (uid) -> selected_uids.delete(uid)
      # deselect the categories, but leave category expanded
      categories.forEach (category) ->
        selected_categories.delete(category)

    # return a promise which is resolved when the state was successfully set
    return new Promise (resolve, reject) =>
      @setState
        selected_uids: Array.from(selected_uids)
        selected_categories: Array.from(selected_categories)
        expanded_categories: Array.from(expanded_categories)
      , resolve

  ###*
   * Select a row checkbox by UID
   *
   * @param uid {string} The UID of the row
   * @param toggle {bool} true for select, false for deselect
   * @returns {Promise} which is resolved when the state was sucessfully set
  ###
  selectUID: (uid, toggle) ->
    toggle ?= yes
    predicate = (item) -> item.uid == uid

    # get the folderitems
    items = @get_folderitems()

    # Expanded children are not part of the folder items, but are remembered
    # when fetched in the `state.children` object.
    # => Expand child items to the regular folderitems to be selectable, see:
    #    https://github.com/senaite/senaite.app.listing/pull/106
    items = items.concat.apply(items, Object.values(@state.children))

    if toggle is yes
      if uid == "all"
        # select all
        return @selectItems items, null, yes
      # select single item
      return @selectItems items, predicate, yes
    else
      if uid == "all"
        # deselect all
        return @selectItems items, null, no
      # deselect single item
      return @selectItems items, predicate, no


  ###*
   * Select a range of UIDs
   *
   * @param start_uid {string} The UID of first selected item
   * @param end_uid {string} The UID of the last selected item
   * @param toggle {bool} true for select, false for deselect
   * @returns {Promise} which is resolved when the state was sucessfully set
  ###
  selectUIDRange: (start_uid, end_uid, toggle) ->
    items = []
    folderitems = @get_folderitems()

    # sort the folderitems by their category if categorized
    if @state.categories.length > 0
      for category in @state.categories
        categorized = folderitems.filter (item) -> item.category == category
        items = items.concat categorized
    else
      items = folderitems

    # calculate the range of UIDs
    uids =items.map (item, index) -> item.uid
    start_idx = uids.indexOf(start_uid)
    end_idx = uids.indexOf(end_uid)
    if end_idx > start_idx
      range = uids.slice(start_idx, end_idx + 1)
    else
      # support upwards select
      range = uids.slice(end_idx, start_idx)

    predicate = (item) ->
      item.uid in range

    return @selectItems null, predicate, toggle


  ###*
   * Save the values of the state's `ajax_save_queue`
   *
   * This method executes an Ajax request to the server.
   *
   * @returns {Promise} of the Ajax Save Request
  ###
  saveAjaxQueue: ->
    uids = Object.keys @state.ajax_save_queue
    if uids.length == 0
      promise = new Promise (resolve, reject) =>
          resolve()
      return promise
    return @ajax_save()

  ###*
   * Save a named value by UID to the ajax_save_queue
   *
   * If the column has the `autosave` property set,
   * the value will be send immediately to the server
   *
   * @param uid {string} UID of the object
   * @param name {string} name of the field
   * @param value {string} value to set
   * @param item {object} additional server data
   * @returns {bool} true
  ###
  saveEditableField: (uid, name, value, item) ->
    # Skip fields which are not editable
    return false unless name in item.allow_edit
    console.debug "ListingController::saveEditableField: uid=#{uid} name=#{name} value=#{value}"

    column = @state.columns[name] or {}

    # store the value in the ajax_save_queue
    if column.ajax
      me = this
      ajax_save_queue = @state.ajax_save_queue
      ajax_save_queue[uid] ?= {}
      ajax_save_queue[uid][name] = value
      @setState
        show_ajax_save: yes
        ajax_save_queue: ajax_save_queue
        refetch: column.refetch or false
      , ->
        if column.autosave
          me.ajax_save()

    # call the on_change handler
    handler = column.on_change
    if handler
      @ajax_on_change handler,
        uid: uid
        name: name
        value: value
        item: item

    return true

  ###*
   * Update a named value by UID
   *
   * Saves the value and selects the row.
   *
   * @param uid {string} UID of the object
   * @param name {string} name of the field
   * @param value {string} value to set
   * @param item {object} additional server data
   * @returns {bool} true
  ###
  updateEditableField: (uid, name, value, item) ->
    console.debug "ListingController::updateEditableField: uid=#{uid} name=#{name} value=#{value}"

    # immediately fill the `ajax_save_queue` to show the "Save" button
    @saveEditableField uid, name, value, item

    # Select the whole row if an editable field changed its value
    me = this
    if not @is_uid_selected uid
      me = this
      @selectUID(uid, on).then ->
        # fetch all possible transitions
        if me.state.fetch_transitions_on_select
          me.fetch_transitions()
    return true

  ###*
   * Checks if the UID is selected.
   *
   * @param uid {string} UID of the object
   * @returns {bool} true if the UID is selected or false
  ###
  is_uid_selected: (uid) ->
    return uid in @state.selected_uids

  ###*
   * Checks if all items are selected
   *
   * @returns {bool} true if all visible and enabled items are selected
  ###
  all_items_selected: () ->
    for item in @get_folderitems()
      if not item.disabled and item.uid not in @state.selected_uids
        return no
    return yes

  ###*
   * Checks if the UID is selected.
   *
   * Throws an error if the ID was not found in the review_states list.
   *
   * @param id {string} ID of the review_state, e.g. "default" or "verified"
   * @returns {object} review_states item
  ###
  get_review_state_by_id: (id) ->
    current = null

    # review_states is the list of review_state items from the listing view
    for review_state in @state.review_states
      if review_state.id == id
        current = review_state
        break

    if not current
      console.warn "No review_state with ID '#{id}' found"
      # return the default column keys
      return {id: "default", columns: @get_columns_keys()}

    return current

  ###*
   * Get the allowed columns of the current review state.
   *
   * This is defined in the view config by tge review_states list, e.g.:
   *
   *  review_states = [
   *      {
   *          "id": "default",
   *          "title": _t("All"),
   *          "contentFilter": {},
   *          "transitions": [],
   *          "custom_transitions": [],
   *          "columns": ["Title", "Descritpion"],
   *      }
   *  ]
   *
   * Usually the columns are defined as `self.columns.keys()`, which means that
   * they contain the same columns and order as defined in the `self.columns`
   * ordered dictionary.
   *
   * @returns {array} columns of column keys
  ###
  get_allowed_column_keys: ->
    # get the current active state filter, e.g. "default"
    review_state = @state.review_state
    # get the defined review state item from the config
    review_state_item = @get_review_state_by_id review_state
    keys = review_state_item.columns
    if not keys
      # return the keys of the columns object
      Object.keys @state.columns
    # filter out nonexisting fields
    columns = @state.columns
    keys = keys.filter (key) -> columns[key] isnt undefined
    return keys

  ###*
   * Calculate the number of displayed columns
   *
   * This method also counts the selection column if present.
   *
   * @returns count {int} of displayed columns
  ###
  get_columns_count: ->
    # get the current visible columns
    visible_columns = @get_visible_columns()

    count = visible_columns.length
    # add 1 if the select column is rendered
    if @state.show_select_column
      count += 1
    if @state.allow_row_reorder
        count += 1
    return count

  ###*
   * Get the names of all expanded categories
   *
   * @returns {array} expanded category names
  ###
  get_expanded_categories: ->
    # return all categories if the flag is on
    if @state.expand_all_categories
      return [].concat @state.categories
    # expand all categories for searches
    if @state.filter
      return [].concat @state.categories
    # return the current expanded categories
    return @state.expanded_categories

  ###*
   * Create a mapping of UID -> folderitem
   *
   * @param folderitems {array} Array of folderitem records
   * @returns {object} of {UID:folderitem}
  ###
  group_by_uid: (folderitems) ->
    folderitems ?= @state.folderitems
    mapping = {}
    folderitems.map (item, index) ->
      # transposed cells have no uid, but a column_key
      uid = item.uid or item.column_key or index
      mapping[uid] = item
    return mapping

  ###*
   * Extract UIDs of folderitems
   *
   * @param folderitems {array} Array of folderitem records
   * @returns {array} Array of UIDs
  ###
  get_uids_from: (folderitems) ->
    folderitems ?= @state.folderitems
    uids = []
    folderitems.map (item, index) ->
      if item.uid
        # regular folderitem
        uids.push item.uid
      else if item.transposed_keys
        # transposed folderitem
        # => transposed_keys is an array of object keys
        #    to contained folderitems
        item.transposed_keys.forEach (key) ->
          uid = item[key].uid
          if uid
            uids.push(uid)
    return uids

  ###*
   * Calculate the count of current folderitems
   *
   * @returns {int} Number of folderitems
  ###
  get_item_count: ->
    return @state.folderitems.length

  ###*
   * Set/Update progress bar
  ###
  set_progress: (progress=0, total=0, label=null) ->
    percent = (progress/total) * 100
    if Number.isNaN(percent)
      percent = null
    @setState progress: percent, progress_label: label

  ###*
   * Reset progress bar
  ###
  reset_progress: ->
    return @setState progress: null, progress_label: null

  ###*
   * Toggles the loading animation on/off
   *
   * @param toggle {bool} true to show the loader, false otherwise
   * @returns {bool} toggle state
  ###
  toggle_loader: (toggle=off) ->
    @setState loading: toggle
    return toggle

  ###*
   * Set the state with optional folderitems fetch
   *
   * @param data {object} data to set to the state
   * @param fetch {bool} true to re-fetch the folderitems, false otherwise
   * @returns {bool} true
  ###
  set_state: (data, fetch=yes) ->
    me = this
    @setState data, ->
      if fetch then me.fetch_folderitems()
    return true

  ###*
   * Fetch the possible transitions of the selected UIDs
   *
   * @returns {Promise} for the API fetch transitions call
  ###
  fetch_transitions: (selected_uids, loader=yes) ->
    selected_uids ?= @state.selected_uids

    # empty the possible transitions if no UID is selected
    if selected_uids.length == 0
      @setState {transitions: []}
      return

    # turn loader on
    if loader then @toggle_loader on

    # get the request options
    options = @getRequestOptions()
    options.selected_uids = selected_uids

    # update the location hash
    @update_location_hash options

    # fetch the transitions from the server
    promise = @api.fetch_transitions options

    me = this
    promise.then (data) ->
      # data looks like this: {"transitions": [...]}
      me.setState data, ->
        console.debug "ListingController::fetch_transitions: NEW STATE=", me.state
        # turn loader off
        if loader then me.toggle_loader off
    return promise

  ###
   * Fetch folderitems from the server
   *
   * @returns {Promise} for the API fetch folderitems call
  ###
  fetch_folderitems: (keep_selected=yes) ->

    # turn loader on
    @toggle_loader on

    # get the request options
    options = @getRequestOptions()

    # update the location hash
    @update_location_hash options

    # fetch the folderitems from the server
    promise = @api.fetch_folderitems options

    me = this
    promise.then (data) ->
      console.debug "ListingController::fetch_folderitems: GOT RESPONSE=", data

      # N.B. Always keep selected folderitems, because otherwise modified fields
      #      won't get send to the server on form submit.
      #
      # This is needed e.g. in "Manage Analyses" when the users searches for
      # analyses to add. Keeping only the UID is there not sufficient, because
      #      we would loose the Min/Max values.
      #
      # TODO refactor this logic
      # -------------------------------8<--------------------------------------
      # existing folderitems from the state as a UID -> folderitem mapping
      existing_folderitems = me.group_by_uid me.state.folderitems
      # new folderitems from the server as a UID -> folderitem mapping
      new_folderitems = me.group_by_uid data.folderitems
      # new categories from the server
      new_categories = data.categories or []
      # list of server side selected UIDs
      server_selected_uids = data.selected_uids or []
      # list of current selected UIDs
      selected_uids = new Set(me.state.selected_uids)

      # keep selected and potentially modified folderitems in the table
      for uid in me.state.selected_uids
        # inject missing folderitems into the server sent folderitems
        if uid not of new_folderitems
          if not keep_selected
            # remove UID from selected_uids
            selected_uids.delete uid
            continue
          # get the missing folderitem from the current state
          folderitem = existing_folderitems[uid]
          # skip if the selected UID is not in the existing folderitems
          # -> happens for transposed WS folderitems, e.g.: {0: {uid: ...}, 1: {uid: ...}}
          continue unless folderitem
          # inject it to the new folderitems list from the server
          new_folderitems[uid] = existing_folderitems[uid]
          # also append the category if it is missing
          category = folderitem.category
          if category and category not in new_categories
            new_categories.push category
            # XXX unfortunately any sortKey sorting of the category get lost here
            new_categories.sort()

      # append selected UIDs set from the server
      for uid in server_selected_uids
        selected_uids.add uid
      # convert to array_
      selected_uids = Array.from selected_uids

      # write back new categories
      data.categories = new_categories
      # write back new folderitems
      data.folderitems = Object.values new_folderitems
      # -------------------------------->8-------------------------------------

      me.setState data, ->
        # calculate the new expanded categories and the internal folderitems mapping
        me.setState
          expanded_categories: me.get_expanded_categories()
          selected_uids: selected_uids
        , ->
          console.debug "ListingController::fetch_folderitems: NEW STATE=", me.state
        # turn loader off
        me.toggle_loader off

    return promise

  ###
   * Fetch child-folderitems from the server
   *
   * @param {parent_uid} UID of the parent, e.g. the primary partition
   * @param {child_uids} UIDs of the children (partitions) to load
   * @returns {Promise} for the API fetch folderitems call
  ###
  fetch_children: ({parent_uid, child_uids}={}) ->
    # turn loader on
    @toggle_loader on

    # lookup child_uids from the folderitem
    if not child_uids
      by_uid = @group_by_uid()

      # include folderitems of children to allow nested toggles
      for uid, childitems of @state.children
        by_uid = Object.assign({}, by_uid, @group_by_uid(childitems))

      child_uids = []
      if parent_uid of by_uid
        folderitem = by_uid[parent_uid]
        child_uids = folderitem.children or []

    # fetch the children from the server
    promise = @api.fetch_children
      parent_uid: parent_uid
      child_uids: child_uids

    me = this
    promise.then (data) ->
      console.debug "ListingController::fetch_children: GOT RESPONSE=", data
      # turn loader off
      me.toggle_loader off

    return promise

  ###
   * Checks if the top toolbar should be loaded or not.
   *
   * @returns {bool} true to render the top toolbar, false otherwise
  ###
  render_toolbar_top: ->
    if @state.show_more
      return yes
    if @state.show_search
      return yes
    if @state.review_states.length > 1
      return yes
    return no

  ###
   * Send the `ajax_save_queue` to the server
   *
   * @returns {Promise} of the API set_fields call
  ###
  ajax_save: ->
    console.debug "ListingController::ajax_save:ajax_save_queue=", @state.ajax_save_queue

    # Sort items by the order they are currently listed
    sorted_save_queue = []
    for item in @get_folderitems()
      if item.uid of @state.ajax_save_queue
        uid = item.uid
        payload = @state.ajax_save_queue[uid]
        sorted_save_queue.push {uid: uid, payload: payload}

    # Process ajax_save_queue sequetially
    chain = Promise.resolve()
    sorted_save_queue.forEach (item) =>
      chain = chain.then () =>
        uid = item.uid
        # toggle row loading on
        @toggleUIDLoading uid, on
        # save single uid
        api_call = @api.set_fields
          save_queue: {"#{uid}": item.payload}
        api_call.then (data) =>
          console.debug "ListingController::ajax_save: GOT DATA=", data
          uids = data.uids or []
          # ensure that all updated UIDs are also selected
          uids.map (uid, index) => @selectUID uid, yes
          # folderitems of the updated objects and their dependencies
          folderitems = data.folderitems or []
          # update the existing folderitems
          @update_existing_folderitems_with folderitems
          # toggle row loading off
          @toggleUIDLoading uid, off

    # all objects saved
    chain.then () =>
      # refetch or update folderitems
      if @state.refetch
        # refetch all folderitems
        @fetch_folderitems()
      else
        # fetch all possible transitions
        if @state.fetch_transitions_on_select
          @fetch_transitions()

      # empty the ajax save queue and hide the save button
      @setState
        show_ajax_save: no
        ajax_save_queue: {}
        refetch: false

    return chain


  ajax_on_change: (handler, data) ->
    console.debug "ListingController::ajax_on_change:handler=#{handler}, data=", data

    # turn loader on
    @toggle_loader on

    promise = @api.on_change
      handler: handler
      data: data

    me = this
    promise.then (data) ->
      console.debug "ListingController::ajax_on_change: GOT DATA=", data

      # folderitems of the updated objects and their dependencies
      folderitems = data.folderitems or []

      # update the existing folderitems
      me.update_existing_folderitems_with folderitems

      # toggle loader off
      me.toggle_loader off
    return promise


  ###*
   * Update existing folderitems
   *
   * This is done for performance increase to avoid a complete re-rendering
   *
   * @param folderitems {array} Array of folderitems records from the view
  ###
  update_existing_folderitems_with: (folderitems) ->
    console.log "ListingController::update_existing_folderitems_with: ", folderitems

    # These folderitems get set to the state
    new_folderitems = []

    # The updated items from the server
    updated_folderitems = @group_by_uid folderitems

    # The current folderitems in our @state
    existing_folderitems = @group_by_uid @state.folderitems

    # Update categories if needed
    categories = @state.categories

    # We iterate through the existing folderitems and check if the items was updated.
    for uid, folderitem of existing_folderitems

      # shallow copy of the existing folderitem in @state.folderitems
      old_item = Object.assign {}, folderitem

      if uid not of updated_folderitems
        # nothing changed -> keep the old folderitem
        new_folderitems.push old_item
      else
        # shallow copy of the updated folderitem from the server
        new_item = Object.assign {}, updated_folderitems[uid]
        # keep non-updated properties
        for key, value of old_item
          # XXX Workaround for Worksheet classic/transposed views
          # -> Always keep those values from the original folderitem
          if key in ["rowspan", "colspan", "skip", "transposed_keys"]
            new_item[key] = old_item[key]
          if not new_item.hasOwnProperty key
            new_item[key] = old_item[key]
        # add the new folderitem
        new_folderitems.push new_item

    # Add updated items that were not yet in existing
    for uid, folderitem of updated_folderitems
      category = folderitem.category
      if category and category not in categories
         categories.push category
         # XXX unfortunately any sortKey sorting of the category get lost here
         categories.sort()

      if uid of existing_folderitems
        # this item already exists, do nothing
        continue
      # shallow copy
      item = Object.assign {}, folderitem
      # add the new folderitem
      new_folderitems.push item

    # updated the state with the new folderitems
    @setState
      folderitems: new_folderitems
      categories: categories

  ###*
   * Update the location hash with the given object
   *
  ###
  update_location_hash: (options) ->
    options ?= {}
    params = []
    allowed = ["filter", "pagesize", "review_state", "sort_on", "sort_order"]
    for key, value of options
      if allowed.indexOf(key) == -1
        continue
      name = @api.to_form_name key
      params = params.concat "#{name}=#{value}"

    # Add column_filters as JSON if present
    column_filters = options.column_filters or {}
    if Object.keys(column_filters).length > 0
      name = @api.to_form_name "column_filters"
      encoded = encodeURIComponent(JSON.stringify(column_filters))
      params = params.concat "#{name}=#{encoded}"

    hash = params.join("&")
    next_hash = "#?#{hash}"
    return if location.hash is next_hash
    # Mark this hash write as self-induced so on_popstate can tell
    # it apart from a real back/forward navigation and skip resetting
    # active_column_filters (which would close any open editor cell
    # while the user is still typing — see #174 follow-up).
    @suppress_next_popstate = yes
    location.hash = next_hash

  ###*
   * EVENT HANDLERS
   *
   * N.B. All `event` objects are ReactJS events
   *      https://reactjs.org/docs/handling-events.html
  ###

  on_click: (event) ->
    console.debug "°°° ListingController::on_click"

    target = event.target

    # Label chip click toggles the corresponding URL filter. Only
    # filterable chips opt in; non-filterable ones stay inert. Row
    # chips have no `×` button — removal is done through the
    # manage-labels modal.
    chip = target.closest ".sample-label.is-filterable"
    if chip
      event.preventDefault()
      @on_label_filter_click chip
      return

    link = target.closest "a"

    # asynchornously load the link URL and reload the table
    if link and link.classList.contains("listing-ajax-action")
      event.preventDefault()
      url = link.href
      @ajaxLoadActionURL(url, reload=yes)

  ###
   * Navigate to the listing URL with the clicked label toggled in
   * the `labels` query parameter. Other URL state (review_state,
   * sort, filter, pagesize, …) is preserved.
  ###
  on_label_filter_click: (link) ->
    label = link.dataset.label
    return unless label
    current = @get_url_labels()
    if label in current
      next = current.filter (l) -> l != label
    else
      next = current.concat [label]
    # Update the URL in place and refetch — a full reload would
    # discard the listing's current state (column filters, applied
    # preset id, pagination, etc.).
    window.history.replaceState null, "", @build_labels_url next
    @fetch_folderitems()
    @forceUpdate?()


  on_column_config_click: (event) ->
    event.preventDefault()
    return unless @state.show_column_toggles
    toggle = not @state.show_column_config
    @setState
      show_column_config: toggle

  close_column_config: ->
    @setState show_column_config: no

  on_select_checkbox_checked: (event) ->
    console.debug "°°° ListingController::on_select_checkbox_checked"
    me = this
    el = event.currentTarget
    uid = el.value
    checked = el.checked

    # support multi-select over the shift-key
    if event.nativeEvent.shiftKey and @last_select
      start_uid = @last_select.uid
      toggle = @last_select.checked
      return @selectUIDRange start_uid, uid, toggle

    # remember the last selected UID
    @last_select =
      uid: uid
      checked: checked

    @selectUID(uid, checked).then ->
      if me.state.fetch_transitions_on_select
        # fetch all possible transitions
        me.fetch_transitions()

  on_multi_select_checkbox_checked: (event) ->
    console.debug "°°° ListingController::on_multi_select_checkbox_checked"
    me = this
    el = event.currentTarget
    value = el.value
    uids = value.split ","
    items = @get_folderitems().filter (item) ->
      uids.indexOf(item.uid) > -1
    @selectItems(items, null, el.checked).then ->
      if me.state.fetch_transitions_on_select
        # fetch all possible transitions
        me.fetch_transitions()

  on_category_click: (event) ->
    console.debug "°°° ListingController::on_category_click"
    me = this
    el = event.currentTarget
    category = el.getAttribute "category"
    @toggleCategory category

  on_category_select: (event) ->
    console.debug "°°° ListingController::on_category_select"
    me = this
    el = event.currentTarget
    # get the category of the target element
    category = el.getAttribute "category"
    # create predicate function that matches the given category
    predicate = (item) -> return item.category == category
    # select/deselect category
    selected = @selectCategory category
    # select/deselect all items of this category
    @selectItems( null, predicate, selected).then () ->
      if me.state.fetch_transitions_on_select
        # fetch all possible transitions
        me.fetch_transitions()

  on_api_error: (response) ->
    @toggle_loader off
    console.debug "°°° ListingController::on_api_error: GOT AN ERROR RESPONSE: ", response

    title = _t("Oops, an error occurred! 🙈")
    if response instanceof Error
      message = response.message
      @addMessage title, message, null, level="danger"
    else if response.text
      response.text().then (data) =>
        message = _t("The server responded with the status #{response.status}: #{response.statusText}")
        @addMessage title, message, null, level="danger"
    else
      message = _t("An unkown error occurred: " + response)
      @addMessage title, message, null, level="danger"

    return response

  on_reload: (event) ->
    console.debug "°°° ListingController::on_reload:event=", event
    @fetch_folderitems()

  on_popstate: (event) ->
    console.debug "°°° ListingController::on_popstate:event=", event
    # Browsers fire popstate for hash changes too. set_url() flags
    # its own writes so we can ignore them here and only react to
    # real back/forward navigation.
    if @suppress_next_popstate
      @suppress_next_popstate = no
      return
    params = @api.parse_hash location.hash
    reload = no
    for idx, param of params
      [key, value] = param.split("=")
      # skip parameters that does not belong to our listing
      if not key.startsWith @form_id
        continue
      name = key.replace("#{@form_id}_", "")
      if name not of @state
        continue
      # workaround for string/number comparison
      if name == "pagesize"
        value = parseInt(value)
      if name == "filter"
        value = decodeURI(value)
      # Handle column_filters as JSON
      if name == "column_filters"
        value = decodeURIComponent(value)
        try
          value = JSON.parse(value)
          # Real back/forward to a URL that carries column_filters:
          # keep the editor cells closed (the funnel icons already
          # mark filtered columns) and let the user re-open per
          # column if they want to edit.
          @state.active_column_filters = []
        catch
          value = {}
      if value isnt @state[name]
        @state[name] = value
        reload = yes
    if reload
      console.debug "+++ RELOAD after popstate +++"
      @fetch_folderitems()

  on_row_order_change: () ->
    console.debug "°°° ListingController::on_form_order_change"
    event = new CustomEvent "listing:row_order_change",
      detail:
        folderitems: @state.folderitems
      , bubbles: yes
      , cancelable: yes
      , composed: no
    # dispatch the event on table root element
    @root_el.dispatchEvent event


  ###*
   * Renders the listing table
   * @returns {JSX}
  ###
  render: ->
    console.debug "*** RENDER ***"

    # computed properties at render time
    columns = @get_columns()
    columns_order = @get_columns_order()
    columns_count = @get_columns_count()
    visible_columns = @get_visible_columns()
    item_count = @get_item_count()
    render_toolbar_top = @render_toolbar_top()

    return (
      <DndProvider backend={HTML5Backend}>
        <div style={{ position: "fixed", top: "1rem", right: "1rem", zIndex: 1050 }}>
          { @state.toasts.map (toast) =>
            <ToastNotification key={toast.id} id={toast.id} message={toast.message} title={toast.title or "Info"} onClose={@removeToast} />
          }
        </div>
        <div className="listing-container">
          <Modal className="modal fade" id="modal_#{@form_id}" />
          <Messages on_dismiss_message={@dismissMessage} id="messages" className="messages" messages={@state.messages} />
          {@state.loading and <div id="table-overlay"/>}
          {not render_toolbar_top and @state.loading and <Loader loading={@state.loading} />}
          {render_toolbar_top and
            <div className="row top-toolbar">
              <div className="col-sm-8">
                <FilterBar
                  className="filterbar nav nav-pills"
                  on_filter_button_clicked={@filterByState}
                  review_state={@state.review_state}
                  review_states={@state.review_states}/>
              </div>
              <div className="col-sm-1 text-right">
                <Loader loading={@state.loading} />
              </div>
              <div className="col-sm-3 text-right d-flex align-items-center justify-content-end">
                {@render_active_label_filters()}
                <SearchBox
                  show_search={@state.show_search}
                  on_search={@filterBySearchterm}
                  on_reset={@resetView}
                  filter={@state.filter}
                  placeholder={_t("Search")}
                  prepend={
                    <SavedFilters
                      storage_id={@get_storage_id()}
                      applied_preset_id={@state.applied_preset_id}
                      current={{
                        review_state: @state.review_state,
                        column_filters: @state.column_filters,
                        sort_on: @state.sort_on,
                        sort_order: @state.sort_order,
                        pagesize: @state.pagesize,
                        filter: @state.filter,
                        labels: @get_url_labels(),
                      }}
                      on_apply={@applySavedFilter}
                      on_clear={@clearAppliedPreset}
                      on_reset={@resetView} />
                  } />
              </div>
            </div>
          }
          {@state.progress and
          <div className="progress my-2">
            <div className="progress-bar progress-bar-striped progress-bar-animated"
                  style={{width: "#{@state.progress}%"}}>
              {@state.progress_label or @state.progress + "%"}
            </div>
          </div>}
          <div className="row">
            <div className="col-sm-12 table-responsive">
              {@state.show_column_toggles and
                <div className="tcc-trigger-group">
                  <button
                    type="button"
                    ref={@column_config_anchor_ref}
                    onClick={@on_column_config_click}
                    className="btn btn-sm btn-outline-secondary tcc-trigger"
                    title={_t("Configure Table Columns")}>
                    <i className="fas fa-table-columns mr-1"></i>
                    {_t("Display Columns")}
                  </button>
                  <button
                    type="button"
                    onClick={@resetColumns}
                    className="btn btn-link btn-sm tcc-reset"
                    title={_t("Reset column visibility and order to the defaults")}
                    aria-label={_t("Reset columns")}>
                    <i className="fas fa-rotate-left"></i>
                  </button>
                </div>}
              {@state.show_column_config and
                <TableColumnConfig
                  title={_t("Configure Table Columns")}
                  description={_t("Click to toggle the visibility or drag&drop to change the order")}
                  columns={columns}
                  columns_order={columns_order}
                  anchor_ref={@column_config_anchor_ref}
                  on_request_close={@close_column_config}
                  on_column_toggle_click={@toggleColumn}
                  on_columns_order_change={@setColumnsOrder}
                  on_reset={@resetColumns}/>}
              <ContextMenu
                id={@row_context_menu_id}
                menu={@state.row_context_menu}
                on_menu_item_click={@handleRowMenuAction} />
              <Table
                className="contentstable table table-hover small"
                form_id={@form_id}
                allow_edit={@state.allow_edit}
                on_header_column_click={@sortBy}
                on_columns_order_change={@setColumnsOrder if @show_column_toggles}
                on_select_checkbox_checked={@on_select_checkbox_checked}
                on_multi_select_checkbox_checked={@on_multi_select_checkbox_checked}
                on_context_menu={@on_column_config_click}
                sort_on={@state.sort_on}
                sort_order={@state.sort_order}
                catalog_indexes={@state.catalog_indexes}
                catalog_columns={@state.catalog_columns}
                sortable_columns={@state.sortable_columns}
                columns={columns}
                columns_count={columns_count}
                review_state={@state.review_state}
                visible_columns={visible_columns}
                review_states={@state.review_states}
                folderitems={@state.folderitems}
                children={@state.children}
                selected_uids={@state.selected_uids}
                loading_uids={@state.loading_uids}
                errors={@state.errors}
                select_checkbox_name={@state.select_checkbox_name}
                show_select_column={@state.show_select_column}
                show_select_all_checkbox={@state.show_select_all_checkbox}
                all_items_selected={@all_items_selected()}
                categories={@state.categories}
                expanded_categories={@state.expanded_categories}
                selected_categories={@state.selected_categories}
                expanded_rows={@state.expanded_rows}
                expanded_remarks={@state.expanded_remarks}
                show_categories={@state.show_categories}
                on_category_click={@on_category_click}
                on_category_select={@on_category_select}
                on_row_expand_click={@toggleRow}
                on_remarks_expand_click={@toggleRemarks}
                on_row_context_menu={@showRowMenu}
                filter={@state.filter}
                update_editable_field={@updateEditableField}
                save_editable_field={@saveEditableField}
                move_row={@moveRow}
                allow_row_reorder={@state.allow_row_reorder}
                on_row_order_change={@on_row_order_change}
                column_filters={@state.column_filters}
                active_column_filters={@state.active_column_filters}
                on_filter_toggle={@toggleColumnFilter}
                on_column_filter_change={@onColumnFilterChange}
                on_column_filter_submit={@onColumnFilterSubmit}
                api={@api}
              />
            </div>
          </div>
          {@state.show_table_footer and
            <div className="row">
              <div className="col-sm-8">
                <ButtonBar
                  className="buttonbar nav nav-pills"
                  show_ajax_save={@state.show_ajax_save}
                  ajax_save_button_title={_t("Save")}
                  on_transition_button_click={@doAction}
                  on_ajax_save_button_click={@saveAjaxQueue}
                  selected_uids={@state.selected_uids}
                  show_select_column={@state.show_select_column}
                  transitions={@state.transitions}
                  review_state={@get_review_state_by_id(@state.review_state)}
                  lock_buttons={@state.lock_buttons}
                  />
              </div>
              <div className="col-sm-1 text-right">
                <Loader loading={@state.loading} />
              </div>
              <div className="col-sm-3 text-right">
                <Pagination
                  id="pagination"
                  className="pagination-controls"
                  total={@state.total}
                  show_more_button_title={_t("Show more")}
                  onShowMore={@showMore}
                  show_more={@state.show_more}
                  count={item_count}
                  pagesize={@state.pagesize}
                  export_button_title={_t("Export")}
                  show_export={@state.show_export}
                  onExport={@export} />
              </div>
            </div>
          }
        </div>
      </DndProvider>
    )
