import React from "react"

import Checkbox from "./Checkbox.coffee"
import TableCell from "./TableCell.coffee"
import RemarksField from "./RemarksField.coffee"

###*
 * This component is currently only used for the Transposed Layout in Worksheets
###
class TableTransposedCell extends TableCell

  constructor: (props) ->
    super(props)
    # Bind event handler to local context
    @on_result_expand_click = @on_result_expand_click.bind @

  ###*
   * Get the transposed folderitem
   *
   * also see bika.lims.browser.worksheet.views.analyses_transposed.py
   *
   * The "transposed item" is the original folderitem, which is stored below the
   * `column_key` of the transposed column, e.g.
   *
   * columns: {1: {…}, 2: {…}, column_key: {…}}
   * folderitems: [
   *   {1: {original-folderitem}, 2: {original-folderitem}, item_key: "Pos", column_key: "Positions"},
   *   {1: {original-folderitem}, 2: {original-folderitem}, item_key: "Result", column_key: "Calcium"},
   *   {1: {original-folderitem}, 2: {original-folderitem}, item_key: "Result", column_key: "Magnesiumn"},
   * ]
  ###
  get_item: ->
    # @props.item: transposed folderitem (see TableCells.coffee)
    # @props.column_key: current column key rendered, e.g. "1", "2", "column_key"
    return @props.item[@props.column_key]

  ###*
   * Get interimfields of the item
  ###
  get_interimfields: ->
    item = @get_item()
    if not item
      return []
    return item.interimfields or []

  ###*
   * Check if the item has interimfields defined
  ###
  has_interimfields: ->
    interims = @get_interimfields()
    return interims.length > 0

  ###*
   * Get the UID of the transposed item
  ###
  get_uid: ->
    item = @get_item()
    return null unless item
    return item.uid

  get_resultfield_title: ->
    # get the (translated) title of the results column
    result_column = @props.columns["Result"]
    return result_column.title or window._t("Result")

  ###*
   * Get the value within the transposed folderitem to render
   *
   * also see bika.lims.browser.worksheet.views.analyses_transposed.py
   *
   * The `item_key` (see also above) within a transposed folderitems item,
   * points to the value to be rendered from the original folderitem.
   *
  ###
  get_column_key: ->
    # @props.item is a transposed folderitem
    # @props.column_key is the actual column key rendered, e.g. "1", "2", "column_key"
    return @props.item.item_key or @props.item.column_key

  is_header_slot: () ->
    item = @get_item()
    if not item
      return no
    if item.uid
      return no
    if not item?.replace?.Pos
      return no
    return yes

  is_assigned_slot: () ->
    item = @get_item()
    if not item
      return no
    if not item.uid
      return no
    return yes

  is_unassigned_slot: () ->
    return not @is_assigned_slot()

  is_loading: (uid) ->
    loading_uids = this.props.loading_uids or []
    return loading_uids.indexOf(uid) > -1

  ###*
   * Calculate CSS Class for the <td> cell based on the original folderitem
  ###
  get_css: ->
    item = @get_item()
    css = ["transposed", @props.className]
    if @is_result_column()
      css.push "result"
    if not item
      css.push "empty"
    else
      css.push item.state_class
      if item.uid in @props.selected_uids
        css.push "info"
    return css.join " "

  get_remarks_columns: ->
    columns = []
    for key, value of @props.columns
      if value.type == "remarks"
        columns.push key
    return columns

  ###*
   * Creates a select checkbox for an assigned slot
   *
   * @param props {object} properties passed to the component
   * @returns ReadonlyField component
  ###
  render_select_checkbox: ({props}={}) ->
    props ?= {}
    uid = @get_uid()
    item = @get_item()
    # already checked in render(), but just to be sure
    return unless item and uid
    name = "#{@props.select_checkbox_name}:list"
    disabled = @is_disabled()
    selected = @is_selected()
    loading = @is_loading(uid)
    return [
      <div key="select" className="checkbox d-flex d-flex-row align-items-center flex-nowrap">
        {!loading &&
        <Checkbox
          name={name}
          value={uid}
          disabled={disabled}
          checked={selected}
          onChange={@props.on_select_checkbox_checked}
          {...props}
          />}

        {loading &&
        <span className="spinner-border spinner-border-sm mr-2" role="status" aria-hidden="true"></span>}

        <div className="badge badge-secondary">{item.Pos}</div>
        <div className="ml-2 small text-secondary">{item.Service}</div>
      </div>
    ]

  ###*
   * Render all interim fields of the current item
   *
   * @param props {object} properties passed to the component
   * @returns Interim Fields
  ###
  render_interims: ({props}={}) ->
    props ?= {}
    fields = []
    uid = @get_uid()
    item = @get_item()
    # already checked in render(), but just to be sure
    return unless item
    interims = item.interimfields or []
    # [{value: 10, keyword: "F_cl", formatted_value: "10,0", unit: "mg/mL", title: "Faktor cl"}, ...]
    for interim, index in interims
      # get the keyword of the interim field
      keyword = interim.keyword
      # skip interims which are not listed in the columns
      # -> see: bika.lims.browser.analyses.view.folderitems
      continue unless @props.columns.hasOwnProperty keyword
      # get the unit of the interim
      unit = interim.unit or ""
      # title / keyword
      title = interim.title or keyword
      # field size
      size = interim.size or 5
      # prepare the field properties
      props =
        key: keyword
        column_key: keyword
        name: "#{keyword}.#{uid}"
        title: title
        placeholder: title
        defaultValue: interim.value
        formatted_value: interim.formatted_value
        size: size
        before_css: "d-block"
        after_css: "d-inline"
        field_css: "d-block mb-2 small"
        before: "<span class='text-secondary'>#{title}</span>"
        after: "<span class='text-secondary small pl-1'>#{unit}</span>"

      if @is_edit_allowed()
        # add a numeric field per interim
        props.className = "form-control form-control-sm interim"
        type = interim.result_type
        if type in ["select", "choices"]
          fields = fields.concat @create_select_field props: props
        else if type in ["multichoice"]
          fields = fields.concat @create_multichoice_field props: props
        else if type in ["multiselect", "multiselect_duplicates"]
          fields = fields.concat @create_multiselect_field props:props
        else if type in ["multivalue"]
          fields = fields.concat @create_multivalue_field props:props
        else if type == "boolean"
          fields = fields.concat @create_checkbox_field props:props
        else if type == "numeric"
          fields = fields.concat @create_numeric_field props:props
        else if type == "string"
          fields = fields.concat @create_string_field props:props
        else if type in ["date", "datetime"]
          fields = fields.concat @create_datetime_field props:props
        else if type == "fraction"
          fields = fields.concat @create_fraction_field props:props
        else
          fields = fields.concat @create_numeric_field props: props
      else
        props.className = "readonly interim"
        fields = fields.concat @create_readonly_field props: props
    return fields

  ###*
   * Render the remarks toggle icon
  ###
  render_remarks_toggle: ->
    fields = []
    uid = @get_uid()
    item = @get_item()
    # already checked in render(), but just to be sure
    return unless item

    if @get_remarks_columns().length > 0
      fields = fields.concat (
        <a key={uid + "_remarks"}
            href="#"
            className="transposed_remarks"
            uid={uid}
            onClick={@props.on_remarks_expand_click}>
          <i className="remarksicon fas fa-comment"></i>
        </a>)
    return fields

  ###*
   * Render the actual analysis remarks textbox
  ###
  render_remarks: ->
    fields = []
    column_key = @get_column_key()
    uid = @get_uid()
    item = @get_item()
    # already checked in render(), but just to be sure
    return unless item

    # Append Remarks field(s)
    for column_key, column_index in @get_remarks_columns()
      value = item[column_key]
      fields.push(
        <span key={column_index + "_remarks"}>
          <RemarksField
            {...@props}
            uid={uid}
            item={item}
            column_key={column_key}
            value={item[column_key]}
          />
        </span>)
    return fields

  ###*
   * Render analysis attachments
  ###
  render_attachments: ->
    fields = []
    column_key = @get_column_key()
    uid = @get_uid()
    item = @get_item()
    # already checked in render(), but just to be sure
    return unless item

    if item.replace.Attachments
      fields = fields.concat @create_readonly_field
          props:
            key: "attachments"
            uid: uid
            item: item
            column_key: "Attachments"
            formatted_value: item.replace.Attachments
            attrs:
              style: {display: "block"}
    return fields

  ###*
   * Render the result field + additional fields
  ###
  render_result: ->
    column_key = @get_column_key()
    item = @get_item()
    # already checked in render(), but just to be sure
    return unless item
    uid = @get_uid()
    type = @get_type()
    props = {}

    if type == "readonly"
      result_field = @create_readonly_field props:props
    else
      # calculated field
      if type == "calculated"
        result_field = @create_calculated_field props:props
      else if type in ["select", "choices"]
        result_field = @create_select_field props:props
      else if type in ["multichoice"]
        result_field = @create_multichoice_field props:props
      else if type in ["multiselect", "multiselect_duplicates" ]
        result_field = @create_multiselect_field props:props
      else if type in ["multivalue"]
        result_field = @create_multivalue_field props:props
      else if type == "boolean"
        result_field = @create_checkbox_field props:props
      else if type == "numeric"
        result_field = @create_numeric_field props:props
      else if type == "string"
        result_field = @create_string_field props:props
      else if type in ["date", "datetime"]
        result_field = @create_datetime_field props:props
      else if type == "fraction"
        result_field = @create_fraction_field props:props
      else
        result_field = @create_numeric_field props:props

    return (
      <div className="result">
        <div>{@render_before_content()}</div>
        <div className="d-flex d-flex-row flex-nowrap">
          <div className="align-self-center">{result_field}</div>
          <div className="align-self-center">{@render_after_content()}</div>
          <div className="align-self-center">{@render_remarks_toggle()}</div>
        </div>
      </div>)

  ###*
   * Change the icon depending on the visible state of the interim fields
   *
   * NOTE: We could have also used the Bootstrap events:
   *       https://getbootstrap.com/docs/4.6/components/collapse/#events
   *       but this approach takes less boilerplate code
  ###
  on_result_expand_click: (event) ->
    # switch the icon depending on the toggle state
    el = event.currentTarget
    id = el.getAttribute("href")
    target = document.querySelector(id)
    icon = el.querySelector("i")
    if target.classList.contains "show"
      icon.classList.replace "fa-minus-square", "fa-plus-square"
    else
      icon.classList.replace "fa-plus-square", "fa-minus-square"

  render: ->
    <td className={@get_css()}
        colSpan={@props.colspan}
        rowSpan={@props.rowspan}>

      {@is_header_slot() and <div className="position">
        {@create_readonly_field()}
      </div>}

      {@is_assigned_slot() and <div className="card">
        <div className="card-header">
         {@render_select_checkbox()}
        </div>
        <div className="card-body">
          <div className="text-secondary">
            {@has_interimfields() and
              <a onClick={@on_result_expand_click} className="text-decoration-none" data-toggle="collapse" href="#interims_#{@get_uid()}">
                <i className="fas fa-plus-square"></i> {@get_resultfield_title()}
              </a>
            }
            {not @has_interimfields() and @get_resultfield_title()}
          </div>
          {@has_interimfields() and
            <div class="collapse p-1 my-2 border rounded" id="interims_#{@get_uid()}">
              <div className="small text-secondary border-bottom mb-2">{window._t("Result variables")}</div>
              {@render_interims()}
            </div>
          }
          {@render_result()}
        </div>
        <div className="card-footer">
          {@render_remarks()}
          {@render_attachments()}
        </div>
      </div>}

    </td>

export default TableTransposedCell
