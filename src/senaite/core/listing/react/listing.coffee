###* ReactJS controlled component
 *
 * Please use JSDoc comments: https://jsdoc.app
###
import React from "react"
import ReactDOM from "react-dom"

import Messages from "./components/Messages.coffee"
import ButtonBar from "./components/ButtonBar.coffee"
import FilterBar from "./components/FilterBar.coffee"
import ListingAPI from "./api.coffee"
import Loader from "./components/Loader.coffee"
import Pagination from "./components/Pagination.coffee"
import SearchBox from "./components/SearchBox.coffee"
import Table from "./components/Table.coffee"
import TableContextMenu from "./components/TableContextMenu.coffee"
import TableColumnConfig from "./components/TableColumnConfig.coffee"

import "./listing.css"


# DOCUMENT READY ENTRY POINT
document.addEventListener "DOMContentLoaded", ->
  console.debug "*** SENAITE.CORE.LISTING::DOMContentLoaded: --> Loading ReactJS Controller"

  tables = document.getElementsByClassName "ajax-contents-table"
  window.listings ?= {}
  for table in tables
    form_id = table.dataset.form_id
    controller = ReactDOM.render <ListingController root_el={table} />, table
    # Keep a reference to the listing
    window.listings[form_id] = controller


class ListingController extends React.Component
  ###
   * Listing Table Controller
  ###

  constructor: (props) ->
    super(props)

    # bind callbacks
    @dismissMessage = @dismissMessage.bind @
    @filterByState = @filterByState.bind @
    @filterBySearchterm = @filterBySearchterm.bind @
    @sortBy = @sortBy.bind @
    @showMore = @showMore.bind @
    @doAction = @doAction.bind @
    @toggleContextMenu = @toggleContextMenu.bind @
    @toggleColumn = @toggleColumn.bind @
    @moveColumn = @moveColumn.bind @
    @toggleCategory = @toggleCategory.bind @
    @toggleRow = @toggleRow.bind @
    @saveEditableField = @saveEditableField.bind @
    @updateEditableField = @updateEditableField.bind @
    @saveAjaxQueue = @saveAjaxQueue.bind @
    @toggleRemarks = @toggleRemarks.bind @
    @on_select_checkbox_checked = @on_select_checkbox_checked.bind @
    @on_api_error = @on_api_error.bind @

    # root element
    @root_el = @props.root_el

    # get initial configuration data from the HTML attribute
    @columns = JSON.parse @root_el.dataset.columns
    @review_states = JSON.parse @root_el.dataset.review_states
    @form_id = @root_el.dataset.form_id
    @api_url = @root_el.dataset.api_url
    @listing_portal_type = @root_el.dataset.listing_portal_type
    @pagesize = parseInt @root_el.dataset.pagesize

    # the API is responsible for async calls and knows about the endpoints
    @api = new ListingAPI
      api_url: @api_url
      on_api_error: @on_api_error

    @state =
      # alert messages
      messages: []
      # loading indicator
      loading: yes
      # context menu visibility and coordinates
      contextmenu_show: no
      contextmenu_x: 0
      contextmenu_y: 0
      # filter, pagesize, sort_on, sort_order and review_state are initially set
      # from the request to allow bookmarks to specific searches
      filter: @api.get_url_parameter("#{@form_id}_filter")
      pagesize: parseInt(@api.get_url_parameter("#{@form_id}_pagesize")) or @pagesize
      sort_on: @api.get_url_parameter("#{@form_id}_sort_on")
      sort_order: @api.get_url_parameter("#{@form_id}_sort_order")
      review_state: @api.get_url_parameter("#{@form_id}_review_state") or "default"
      # The query string is computed on the server and allows to bookmark listings
      query_string: ""
      # The column toggles define the visible columns per user setting
      column_toggles: []
      # The API URL to call
      api_url: ""
      # form_id, columns and review_states are defined in the listing view and
      # passed in via a data attribute in the template, because they can be seen
      # as constant values
      form_id: @form_id
      columns: @columns
      review_states: @review_states
      # The data from the folderitems view call
      folderitems: []
      # Mapping of UID -> list of children from the folderitems
      children: {}
      # The categories of the folderitems
      categories: []
      # Expanded categories
      expanded_categories: []
      # Expanded Rows (currently only Partitions)
      expanded_rows: []
      # Expanded Remarks Rows
      expanded_remarks: []
      # total number of items in the database
      total: 0
      # UIDs of selected rows are stored in selected_uids.
      # These are sent when a transition action is clicked.
      selected_uids: []
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
      show_column_toggles: no
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


  dismissMessage: (index=null) ->
    ###
     * Dismiss a message by its message index
    ###
    if index is null
      return @setState messages: []
    messages = [].concat @state.messages
    messages.splice index, 1
    return @setState messages: messages

  addMessage: (title, text, traceback, level="info") ->
    ###*
     * Add a message
    ###
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
    @setState messages: messages


  getRequestOptions: ->
    ###
     * Only these state values should be sent to the server
    ###
    options =
      "review_state": @state.review_state
      "filter": @state.filter
      "sort_on": @state.sort_on
      "sort_order": @state.sort_order
      "pagesize": @state.pagesize
      "limit_from": @state.limit_from
      "selected_uids": @state.selected_uids,

    console.debug("Request Options=", options)
    return options

  componentDidMount: ->
    ###
     * ReactJS event handler when the component did mount
    ###

    # initial fetch of the folderitems
    @fetch_folderitems()

  toggleContextMenu: (x, y, toggle) ->
    ###
     * Toggle the context menu
    ###
    console.debug "ListingController::toggleContextMenu: x=#{x} y=#{y}"

    toggle ?= not @state.contextmenu_show

    @setState
      contextmenu_show: toggle
      contextmenu_x: x
      contextmenu_y: y

  toggleCategory: (category) ->
    ###
     * Expand/Collapse the category
    ###
    console.debug "ListingController::toggleCategory: column=#{category}"

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
    @setState
      expanded_categories: expanded

  toggleRemarks: (uid) ->
    ###
     * Expand/Collapse remarks
    ###
    console.debug "ListingController::toggleRemarks: uid=#{uid}"

    # skip if no uid is given
    return unless uid

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
    @setState
      expanded_remarks: expanded

  toggleRow: (uid) ->
    ###
     * Expand/Collapse the row
    ###
    console.debug "ListingController::toggleRow: uid=#{uid}"

    # skip if no uid is given
    return unless uid

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
      @setState
        expanded_rows: expanded

  toggleColumn: (column) ->
    ###
     * Toggle the column on or off
    ###
    console.debug "ListingController::toggleColumn: column=#{column}"

    # reset the default visible columns
    if column == "reset"
      columns = @get_default_columns()
      @set_column_toggles columns

      return columns

    # get the current displayed columns
    columns = @get_visible_columns()
    # check if the current column is displayed
    index = columns.indexOf column

    if index > -1
      # remove the column
      columns.splice index, 1
    else
      # add the column
      columns.push column

    # set the new column toggles
    @set_column_toggles columns

    return columns

  ###*
   * Move the column behind the other column.
   *
   * Used by the `TableColumnConfig` component to change the column sort order
   *
   * @param column {string} ID of the column to move
   * @param other_column {string} ID of the target column
  ###
  moveColumn: (column, other_column) ->
    console.debug "ListingController::moveColumn:#{column}->#{other_column}"

  filterByState: (review_state="default") ->
    ###
     * Filter the results by the given state
    ###
    console.debug "ListingController::filterByState: review_state=#{review_state}"

    @set_state
      review_state: review_state
      pagesize: @pagesize  # reset to the initial pagesize on state change
      limit_from: 0

  filterBySearchterm: (filter="") ->
    ###
     * Filter the results by the given sarchterm
    ###
    console.debug "ListingController::filterBySearchter: filter=#{filter}"

    @set_state
      filter: filter
      pagesize: @pagesize  # reset to the initial pagesize on search
      limit_from: 0

  sortBy: (sort_on, sort_order) ->
    ###
     * Sort the results by the given sort_on index with the given sort_order
    ###
    console.debug "sort_on=#{sort_on} sort_order=#{sort_order}"

    @set_state
      sort_on: sort_on
      sort_order: sort_order
      pagesize: @get_item_count() # keep the current number of items on sort
      limit_from: 0

  showMore: (pagesize) ->
    ###
     * Show more items
    ###
    console.debug "ListingController::showMore: pagesize=#{pagesize}"

    # the existing folderitems
    folderitems = @state.folderitems

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
          # append the new folderitems to the existing ones
          new_folderitems = folderitems.concat data.folderitems
          me.setState
            folderitems: new_folderitems

  doAction: (id, url) ->
    ###
     * Perform an action coming from the WF Action Buttons
    ###

    # handle clear button separate
    if id == "clear_selection"
      @selectUID "all", off
      return

    # get the form element
    form = document.getElementById @state.form_id

    # N.B. Transition submit buttons are suffixed with `_transition`, because
    #      otherwise the form.submit call below retrieves the element instead of
    #      doing the method call.
    action = id.split("_transition")[0]

    # inject workflow action id for `BikaListing._get_form_workflow_action`
    input = document.createElement "input"
    input.setAttribute "type", "hidden"
    input.setAttribute "id", id
    input.setAttribute "name", "workflow_action_id"
    input.setAttribute "value", action
    form.appendChild input

    # Override the form action when a custom URL is given
    if url then form.action = url

    return form.submit()

  selectUID: (uid, toggle) ->
    ###
     * select/deselect the UID
    ###

    # copy the selected UIDs from the state
    #
    # N.B. We use [].concat(@state.selected_uids) to get a copy, otherwise it
    #      would be a reference of the state value!
    selected_uids = [].concat @state.selected_uids

    if toggle is yes
      # handle the select all checkbox
      if uid == "all"
        # Do not select disabled items
        items = @state.folderitems.filter (item) ->
          return not item.disabled
        # Get all uids from enabled items
        all_uids = items.map (item) -> item.uid
        # keep existing selected uids
        for uid in all_uids
          if uid not in selected_uids
            selected_uids.push uid
      else
        if uid not in selected_uids
          # push the uid into the list of selected_uids
          selected_uids.push uid
    else
      # flush all selected UIDs when the select_all checkbox is deselected or
      # when the deselect all button was clicked
      if uid == "all"
        # Keep readonly items
        by_uid = @group_by_uid @state.folderitems
        selected_uids = selected_uids.filter (uid) ->
          item = by_uid[uid]
          return item.readonly
      else
        # remove the selected UID from the list of selected_uids
        pos = selected_uids.indexOf uid
        selected_uids.splice pos, 1

    # Only set the state and refetch transitions if the selected UIDs changed
    added = selected_uids.filter((uid) =>
       @state.selected_uids.indexOf(uid)==-1).length > 0
    removed = @state.selected_uids.filter((uid) =>
       selected_uids.indexOf(uid)==-1).length > 0
    return unless added or removed

    # return a promise which is resolved when the state was successfully set
    return new Promise (resolve, reject) =>
      @setState
        selected_uids: selected_uids, resolve

  saveAjaxQueue: ->
    ###
     * Save the whole ajax queue
    ###
    uids = Object.keys @state.ajax_save_queue
    return unless uids.length > 0
    promise = @ajax_save()

  saveEditableField: (uid, name, value, item) ->
    ###
     * Save the editable field of a table cell
    ###

    # Skip fields which are not editable
    return unless name in item.allow_edit

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
      , ->
        if column.autosave
          me.ajax_save()

  updateEditableField: (uid, name, value, item) ->
    ###
     * Update the editable field
    ###
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

  is_uid_selected: (uid) ->
    ###
     * Check if the UID is selected
    ###
    return uid in @state.selected_uids

  get_review_state_by_id: (id) ->
    ###
     * Fetch the current review_state item by id
    ###
    current = null

    # review_states is the list of review_state items from the listing view
    for review_state in @state.review_states
      if review_state.id == id
        current = review_state
        break

    if not current
      throw "No review_state definition found for ID #{id}"

    return current

  ###*
   * Get the allowed columns of the current review state.
   *
   * This is defined in the view config by tge review_states list, e.g.:
   *
   *  review_states = [
   *      {
   *          "id": "default",
   *          "title": _("All"),
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
  get_display_columns: ->
    # get the current active state filter, e.g. "default"
    review_state = @state.review_state
    # get the defined review state item from the config
    review_state_item = @get_review_state_by_id review_state
    columns = review_state_item.columns
    if not columns
      # return the keys of the columns object
      Object.keys @state.columns
    return columns

  ###*
   * Get a list of ordered column objects
   * @returns {array} columns of column objects
  ###
  get_columns: ->
    columns = []

    # We iterate over the defined columns of the revies_states item to only
    # include columns in the order that is listed there.
    for key in @get_display_columns()
      column = @state.columns[key]
      # TODO: check if the column is manually toggled on/off

      # Add the column
      columns.push column
    return columns
  get_column_order: ->
    ###
     * Get the column order defined in the current selected review_state item
    ###
    review_state_item = @get_review_state_by_id @state.review_state
    return review_state_item.columns or []

  get_visible_columns: ->
    ###
     * Get the visible columns according to the user settings
    ###

    # get the current user defined column toggles
    column_toggles = @get_column_toggles()

    if column_toggles.length > 0
      columns = []
      for key in @get_column_order()
        if key in column_toggles
          columns.push key
      return columns

    return @get_default_columns()

  get_default_columns: ->
    ###
     * Get the default visible columns of the listing
    ###

    columns = []
    for key in @get_column_order()
      column = @state.columns[key]
      # only skip columns explicitly set to false
      if column.toggle is no
          continue
      columns.push key
    return columns

  get_local_storage_key: ->
    ###
     * Return the key for the local storage
    ###
    key = @listing_portal_type
    if @listing_portal_type is undefined
      key = location.pathname
    return "listing-columns-#{@listing_portal_type}"

  set_column_toggles: (columns) ->
    ###
     * Set the user defined column toggles to the local state and local storage
    ###
    console.debug "ListingController::set_column_toggles: columns=", columns

    key = @get_local_storage_key()
    storage = window.localStorage
    storage.setItem key, JSON.stringify(columns)

    @setState
      column_toggles: columns

  get_column_toggles: ->
    ###
     * Return the current column toggles from the local storage
    ###

    key = @get_local_storage_key()
    storage = window.localStorage
    columns = storage.getItem key

    if not columns
      return @state.column_toggles

    try
      return JSON.parse columns
    catch
      return @state.column_toggles

  get_column_count: ->
    ###
     * Calculate the current number of displayed columns
    ###
    # get the current visible columns
    visible_columns = @get_visible_columns()

    count = visible_columns.length
    # add 1 if the select column is rendered
    if @state.show_select_column
      count += 1
    return count

  get_expanded_categories: ->
    ###
     * Get the expanded categories
    ###

    # return all categories if the flag is on
    if @state.expand_all_categories
      return [].concat @state.categories

    # expand all categories for searches
    if @state.filter
      return [].concat @state.categories

    return []

  group_by_uid: (folderitems) ->
    ###
     * Create a mapping of UID -> folderitem
    ###
    folderitems ?= @state.folderitems
    mapping = {}
    folderitems.map (item, index) ->
      # transposed cells have no uid, but a column_key
      uid = item.uid or item.column_key or index
      mapping[uid] = item
    return mapping

  get_item_count: ->
    ###
     * Return the current shown items
    ###
    return @state.folderitems.length

  toggle_loader: (toggle=off) ->
    ###
     * Toggle the loader on/off
    ###
    @setState loading: toggle

  set_state: (data, fetch=yes) ->
    ###
     * Helper to set the state and reload the folderitems
    ###
    me = this

    @setState data, ->
      if fetch then me.fetch_folderitems()

  fetch_transitions: ->
    ###
     * Fetch the possible transitions
    ###
    selected_uids = @state.selected_uids

    # empty the possible transitions if no UID is selected
    if selected_uids.length == 0
      @setState transitions: []
      return

    # turn loader on
    @toggle_loader on

    # fetch the transitions from the server
    promise = @api.fetch_transitions @getRequestOptions()

    me = this
    promise.then (data) ->
      # data looks like this: {"transitions": [...]}
      me.setState data, ->
        console.debug "ListingController::fetch_transitions: NEW STATE=", me.state
        # turn loader off
        me.toggle_loader off

  fetch_folderitems: ->
    ###
     * Fetch folderitems from the server
     *
     * @param uids {array} List of UIDs to fetch (all if omitted)
    ###

    # turn loader on
    @toggle_loader on

    # fetch the folderitems from the server
    promise = @api.fetch_folderitems @getRequestOptions()

    me = this
    promise.then (data) ->
      console.debug "ListingController::fetch_folderitems: GOT RESPONSE=", data

      # N.B. Always keep selected folderitems, because otherwise modified fields
      #      won't get send to the server on form submit.
      #
      # This is needed e.g. in "Manage Analyses" when the users searches for
      # analyses to add. Keeping only the UID is there not sufficient, because
      #      we would lose the Mix/Max values.
      #
      # TODO refactor this logic
      # -------------------------------8<--------------------------------------
      # existing folderitems from the state as a UID -> folderitem mapping
      existing_folderitems = me.group_by_uid me.state.folderitems
      # new folderitems from the server as a UID -> folderitem mapping
      new_folderitems = me.group_by_uid data.folderitems
      # new categories from the server
      new_categories = data.categories or []

      # keep selected and potentially modified folderitems in the table
      for uid in me.state.selected_uids
        # inject missing folderitems into the server sent folderitems
        if uid not of new_folderitems
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

      # write back new categories
      data.categories = new_categories
      # write back new folderitems
      data.folderitems = Object.values new_folderitems
      # -------------------------------->8-------------------------------------

      me.setState data, ->
        # calculate the new expanded categories and the internal folderitems mapping
        me.setState
          expanded_categories: me.get_expanded_categories()
        , ->
          console.debug "ListingController::fetch_folderitems: NEW STATE=", me.state
        # turn loader off
        me.toggle_loader off

    return promise

  fetch_children: ({parent_uid, child_uids}={}) ->
    ###
     * Fetch the children of the parent by uid
    ###

    # turn loader on
    @toggle_loader on

    # lookup child_uids from the folderitem
    if not child_uids
      by_uid = @group_by_uid()
      folderitem = by_uid[parent_uid]
      if not folderitem
        throw "No folderitem could be found for UID #{uid}"
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

  render_toolbar_top: ->
    ###
     * Control if the top toolbar should be loaded
    ###
    if @state.show_more
      return yes
    if @state.show_search
      return yes
    if @state.review_states.length > 1
      return yes
    return no

  ajax_save: ->
    ###
     * Save the items of the `ajax_save_queue`
    ###
    console.debug "ListingController::ajax_save:ajax_save_queue=", @state.ajax_save_queue

    # turn loader on
    @toggle_loader on

    promise = @api.set_fields
      save_queue: @state.ajax_save_queue

    me = this
    promise.then (data) ->
      console.debug "ListingController::ajax_save: GOT DATA=", data

      # uids of the updated objects
      uids = data.uids or []

      # ensure that all updated UIDs are also selected
      uids.map (uid, index) -> me.selectUID uid, yes

      # folderitems of the updated objects and their dependencies
      folderitems = data.folderitems or []

      # update the existing folderitems
      me.update_existing_folderitems_with folderitems

      # fetch all possible transitions
      if me.state.fetch_transitions_on_select
        me.fetch_transitions()

      # empty the ajax save queue and hide the save button
      me.setState
        show_ajax_save: no
        ajax_save_queue: {}

      # toggle loader off
      me.toggle_loader off

  update_existing_folderitems_with: (folderitems) ->
    ###
     * Update existing folderitems
    ###
    console.log "ListingController::update_existing_folderitems_with: ", folderitems

    # These folderitems get set to the state
    new_folderitems = []

    # The updated items from the server
    updated_folderitems = @group_by_uid folderitems

    # The current folderitems in our @state
    existing_folderitems = @group_by_uid @state.folderitems

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
          if key in ["rowspan", "colspan", "skip"]
            new_item[key] = old_item[key]
          if not new_item.hasOwnProperty key
            new_item[key] = old_item[key]
        # add the new folderitem
        new_folderitems.push new_item

    # updated the state with the new folderitems
    @setState
      folderitems: new_folderitems

  ###*
    * EVENT HANDLERS
    *
    * N.B. All `event` objects are ReactJS events
    *      https://reactjs.org/docs/handling-events.html
  ###

  on_select_checkbox_checked: (event) ->
    ###
     * Event handler when a folderitem (row) was selected
    ###
    console.debug "°°° ListingController::on_select_checkbox_checked"
    me = this
    el = event.currentTarget
    uid = el.value
    checked = el.checked

    @selectUID(uid, checked).then ->
      if me.state.fetch_transitions_on_select
        # fetch all possible transitions
        me.fetch_transitions()

  on_api_error: (response) ->
    ###
     * API Error handler
     * This method stops the loader animation and adds a status message
    ###
    @toggle_loader off
    console.debug "°°° ListingController::on_api_error: GOT AN ERROR RESPONSE: ", response

    me = this
    response.json().then (data) ->
      title = _("Oops, an error occured! 🙈")
      message = _("The server responded with the status #{data.status}: #{data.message}")
      me.addMessage title, message, data.traceback, level="danger"

  ###*
    * VIEW
  ###

  render: ->
    ###
     * Listing Table
    ###
    <div className="listing-container">
      <Messages on_dismiss_message={@dismissMessage} id="messages" className="messages" messages={@state.messages} />
      {@state.loading and <div id="table-overlay"/>}
      {not @render_toolbar_top() and @state.loading and <Loader loading={@state.loading} />}
      {@render_toolbar_top() and
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
          <div className="col-sm-3 text-right">
            <SearchBox
              show_search={@state.show_search}
              on_search={@filterBySearchterm}
              filter={@state.filter}
              placeholder={_("Search")} />
          </div>
        </div>
      }
      <div className="row">
        <div className="col-sm-12 table-responsive">
          {@state.show_column_toggles and
            <TableContextMenu
              show={@state.contextmenu_show}
              x={@state.contextmenu_x}
              y={@state.contextmenu_y}
              title={_("Display Columns")}
              reset_title={_("Reset")}
              columns={@state.columns}
              column_order={@get_column_order()}
              table_columns={@get_visible_columns()}
              on_column_toggle={@toggleColumn}
              on_context_menu={@toggleContextMenu}
              />}
          {@state.show_column_toggles and
            <a
              href="#"
              onClick={(event) -> event.preventDefault()}
              className="pull-right"
              data-toggle="collapse"
              data-target="#table-config">
              <span className="glyphicon glyphicon-option-horizontal"></span>
            </a>}
          <TableColumnConfig
            title={_("Configure Table Columns")}
            columns={@state.columns}
            table_columns={@get_visible_columns()}
            on_column_toggle={@toggleColumn}
            on_column_move={@moveColumn}
            id="table-config"
            className="collapse"/>
          <Table
            className="contentstable table table-condensed table-hover small"
            allow_edit={@state.allow_edit}
            on_header_column_click={@sortBy}
            on_select_checkbox_checked={@on_select_checkbox_checked}
            on_context_menu={@toggleContextMenu}
            sort_on={@state.sort_on}
            sort_order={@state.sort_order}
            catalog_indexes={@state.catalog_indexes}
            catalog_columns={@state.catalog_columns}
            sortable_columns={@state.sortable_columns}
            columns={@state.columns}
            column_toggles={@state.column_toggles}
            column_count={@get_column_count()}
            table_columns={@get_visible_columns()}
            review_state={@state.review_state}
            review_states={@state.review_states}
            folderitems={@state.folderitems}
            children={@state.children}
            selected_uids={@state.selected_uids}
            select_checkbox_name={@state.select_checkbox_name}
            show_select_column={@state.show_select_column}
            show_select_all_checkbox={@state.show_select_all_checkbox}
            categories={@state.categories}
            expanded_categories={@state.expanded_categories}
            expanded_rows={@state.expanded_rows}
            expanded_remarks={@state.expanded_remarks}
            show_categories={@state.show_categories}
            on_category_click={@toggleCategory}
            on_row_expand_click={@toggleRow}
            on_remarks_expand_click={@toggleRemarks}
            filter={@state.filter}
            update_editable_field={@updateEditableField}
            save_editable_field={@saveEditableField}
            />
        </div>
      </div>
      {@state.show_table_footer and
        <div className="row">
          <div className="col-sm-8">
            <ButtonBar
              className="buttonbar nav nav-pills"
              show_ajax_save={@state.show_ajax_save}
              ajax_save_button_title={_("Save")}
              on_transition_button_click={@doAction}
              on_ajax_save_button_click={@saveAjaxQueue}
              selected_uids={@state.selected_uids}
              show_select_column={@state.show_select_column}
              transitions={@state.transitions}
              review_state={@get_review_state_by_id(@state.review_state)}
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
              show_more_button_title={_("Show more")}
              onShowMore={@showMore}
              show_more={@state.show_more}
              count={@get_item_count()}
              pagesize={@state.pagesize}/>
          </div>
        </div>
      }
    </div>
