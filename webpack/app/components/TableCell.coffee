import React from "react"

import Checkbox from "./Checkbox.coffee"
import HiddenField from "./HiddenField.coffee"
import MultiChoice from "./MultiChoice.coffee"
import MultiSelect from "./MultiSelect.coffee"
import MultiValue from "./MultiValue.coffee"
import NumericField from "./NumericField.coffee"
import CalculatedField from "./CalculatedField.coffee"
import ReadonlyField from "./ReadonlyField.coffee"
import Select from "./Select.coffee"
import StringField from "./StringField.coffee"
import TextField from "./TextField.coffee"
import FractionField from "./FractionField.coffee"
import DateTime from "./DateTime.coffee"


class TableCell extends React.Component

  constructor: (props) ->
    super(props)

    # Zope Publisher Converter Argument Mapping
    @ZPUBLISHER_CONVERTER = {
      "boolean": ":record:ignore_empty"
      "select": ":records"
      "choices": ":records"
      "multiselect": ":list"
      "multichoice": ":list"
      "multivalue": ":list"
      "numeric": ":records"
      "fraction": ":records"
      "string": ":records"
      "text": "records"
      "datetime": ":records"
      "readonly": ""
      "default": ":records"
    }

  get_column: ->
    return @props.column

  get_item: ->
    return @props.item

  get_column_key: ->
    return @props.column_key

  render_before_content: (props={}) ->
    column_key = @get_column_key()
    item = @get_item()
    return unless item
    before = item.before
    if column_key not of before
      return null
    # support to render React components
    before_components = item.before_components or {}
    return (
      <span key={column_key + "_before"}
            className="before-item">
        {before_components[column_key]}
        <span dangerouslySetInnerHTML={{__html: before[column_key]}} {...props}></span>
      </span>)

  render_after_content: (props={}) ->
    column_key = @get_column_key()
    item = @get_item()
    return unless item
    after = item.after
    if column_key not of after
      return null
    # support to render React components
    after_components = item.after_components or {}
    return (
      <span key={column_key + "_after"}
            className="after-item">
        {after_components[column_key]}
        <span dangerouslySetInnerHTML={{__html: after[column_key]}} {...props}></span>
      </span>)

  is_edit_allowed: ->
    column_key = @get_column_key()
    item = @get_item()

    # the global allow_edit overrides all row specific settings
    if not @props.allow_edit
      return no

    # check if the field is listed in the item's allow_edit list
    if column_key in item.allow_edit
      return yes

    return no

  is_disabled: ->
    item = @get_item()
    disabled = item.disabled
    if disabled in [yes, no]
      return disabled

    return no unless disabled?

    # check if the field is listed in the item's disabled list
    column_key = @get_column_key()
    return column_key in disabled

  is_required: ->
    column_key = @get_column_key()
    item = @get_item()
    required_fields = item.required or []
    required = column_key in required_fields
    # make the field conditionally required if the row is selected
    selected = @props.selected
    return required and selected

  get_name: ->
    uid = @get_uid()
    column_key = @get_column_key()
    return "#{column_key}.#{uid}"

  get_uid: ->
    item = @get_item()
    return item.uid

  is_selected: ->
    item = @get_item()
    return item.uid in @props.selected_uids

  get_value: ->
    column_key = @get_column_key()
    item = @get_item()
    value = item[column_key]

    # check if the field is an interim
    interims = @get_interimfields()
    if interims.hasOwnProperty column_key
        # extract the value from the interim field
        # {value: "", keyword: "", formatted_value: "", unit: "", title: ""}
        value = interims[column_key].value or ""

    # values of input fields should not be null
    if value is null
      value = ""

    return value

  ###
  Returns the size for the folderitem or interim field
  ###
  get_size: ->
    default_size = 5
    types_size =
      "string": 30,
      "text": 30,

    item = @get_item()
    column_key = @get_column_key()

    # Maybe the size is defined in the interim field
    if @is_interimfield()
      interim = item[column_key]
      if interim and interim.hasOwnProperty "size"
        return interim.size

    # check the size for this field is defined in current item
    sizes = item.size or {}
    if column_key of sizes
      return sizes[column_key]

    # maybe the size is defined in the column
    column = @props.column or {}
    if "size" of column
      return column.size

    # return default by type
    type = @get_type()
    if type of types_size
      return types_size[type]

    return default_size

  ###*
   * Create a mapping of interim keyword -> interim field
   *
   * Interim fields are record fields with a format like this:
   * {value: "", keyword: "", formatted_value: "", unit: "", title: ""}
  ###
  get_interimfields: ->
    item = @get_item()
    interims = item.interimfields or []
    mapping = {}
    interims.map (item, index) ->
      mapping[item.keyword] = item
    return mapping

  is_interimfield: ->
    column_key = @get_column_key()
    interims = @get_interimfields()
    return interims.hasOwnProperty column_key

  get_choices: ->
    item = @get_item()
    return item.choices or {}

  is_result_column: ->
    column_key = @get_column_key()
    if column_key == "Result"
      return yes
    return no

  get_formatted_value: ->
    column_key = @get_column_key()
    item = @get_item()
    # replacement html or plain value of the current column
    formatted_value = item.replace[column_key] or @get_value()
    # use the formatted result
    if @is_result_column()
      formatted_value = item.formatted_result or formatted_value
    return formatted_value

  get_type: ->
    column_key = @get_column_key()
    item = @get_item()

    # true if the field is editable
    editable = @is_edit_allowed()
    resultfield = @is_result_column()

    # readonly field
    if not editable
      return "readonly"

    # calculated fields are also in editable mode readonly
    if resultfield and item.calculation
      return "calculated"

    # check if the field is a string or datetime field
    if resultfield and item.result_type
      return item.result_type

    # type definition of the column has precedence
    column = @props.column or {}
    if "type" of column
      return column["type"]

    # check if the field is a boolean
    value = @get_value()
    if typeof(value) == "boolean"
      return "boolean"

    # check if the field is listed in choices
    choices = @get_choices()
    if column_key of choices
      # check if the field is a multi-choices
      default_type = "select"
      if resultfield
        return item.result_type or default_type
      # Maybe is an interim field
      if @is_interimfield()
        column_key = @get_column_key()
        interim = item[column_key]
        if interim
          return interim.result_type or default_type
      return default_type

    # check if the field is an interim
    if @is_interimfield()
      default_type = "interim"
      column_key = @get_column_key()
      interim = item[column_key]
      if interim
        return interim.result_type or default_type
      return default_type

    # the default
    return "numeric"

  ###*
   * Creates a readonly field component
   *
   * The passed in `props` allow to override required values
   *
   * @param props {object} properties passed to the component
   * @returns ReadonlyField component
  ###
  create_readonly_field: ({props}={}) ->
    props ?= {}

    column_key = props.column_key or @get_column_key()
    item = props.item or @get_item()
    name = props.name or @get_name()
    value = props.value or @get_value()
    formatted_value = props.formatted_value or @get_formatted_value()
    uid = props.uid or @get_uid()
    css_class = props.css_class or "readonly"

    return (
      <ReadonlyField
        key={name}
        uid={uid}
        name={name}
        value={value}
        formatted_value={formatted_value}
        className={css_class}
        {...props}
        />)

  ###*
   * Creates a calculated field component
   *
   * The passed in `props` allow to override required values
   *
   * @param props {object} properties passed to the component
   * @returns CalculatedField component
  ###
  create_calculated_field: ({props}={}) ->
    props ?= {}

    column_key = props.column_key or @get_column_key()
    item = props.item or @get_item()
    name = props.name or @get_name()
    value = props.value or @get_value()
    formatted_value = props.formatted_value or @get_formatted_value()
    uid = props.uid or @get_uid()
    title = props.title or @props.column.title or column_key

    column = props.column or @get_column()
    item.help ?= {}
    help = props.help or item.help[column_key] or column.help

    selected = props.selected or @is_selected()
    required = props.required or @is_required()
    size = props.size or @get_size()
    css_class = props.css_class or "form-control form-control-sm calculated"
    if required then css_class += " required"

    return (
      <CalculatedField
        key={name}
        uid={uid}
        item={item}
        name={name}
        value={value}
        column_key={column_key}
        title={title}
        help={help}
        formatted_value={formatted_value}
        placeholder={title}
        selected={selected}
        required={required}
        className={css_class}
        update_editable_field={@props.update_editable_field}
        save_editable_field={@props.save_editable_field}
        size={size}
        {...props}
        />)

  ###*
   * Creates a hidden field component
   *
   * The passed in `props` allow to override required values
   *
   * @param props {object} properties passed to the component
   * @returns HiddenField component
  ###
  create_hidden_field: ({props}={}) ->
    props ?= {}

    column_key = props.column_key or @get_column_key()
    item = props.item or @get_item()
    name = props.name or @get_name()
    value = props.value or @get_value()
    uid = props.uid or @get_uid()
    title = props.title or @props.column.title or column_key

    return (
      <HiddenField
        key={name + "_hidden"}
        uid={uid}
        name={name}
        value={value}
        column_key={column_key}
        {...props}
        />)

  ###*
   * Creates a numeric field component
   *
   * The passed in `props` allow to override required values
   *
   * @param props {object} properties passed to the component
   * @returns NumericField component
  ###
  create_numeric_field: ({props}={}) ->
    props ?= {}

    column_key = props.column_key or @get_column_key()
    item = props.item or @get_item()
    name = props.name or @get_name()
    value = props.value or @get_value()
    formatted_value = props.formatted_value or @get_formatted_value()
    uid = props.uid or @get_uid()
    title = props.title or @props.column.title or column_key

    column = props.column or @get_column()
    item.help ?= {}
    help = props.help or item.help[column_key] or column.help

    converter = @ZPUBLISHER_CONVERTER["numeric"]
    fieldname = name + converter

    selected = props.selected or @is_selected()
    disabled = props.disabled or @is_disabled()
    required = props.required or @is_required()
    size = props.size or @get_size()
    css_class = props.css_class or "form-control form-control-sm"
    if required then css_class += " required"

    return (
      <NumericField
        key={name}
        uid={uid}
        item={item}
        name={fieldname}
        defaultValue={value}
        column_key={column_key}
        title={title}
        help={help}
        formatted_value={formatted_value}
        placeholder={title}
        selected={selected}
        disabled={disabled}
        required={required}
        className={css_class}
        update_editable_field={@props.update_editable_field}
        save_editable_field={@props.save_editable_field}
        tabIndex={@props.tabIndex}
        size={size}
        {...props}
        />)

  ###*
   * Creates a string field component
   *
   * The passed in `props` allow to override required values
   *
   * @param props {object} properties passed to the component
   * @returns StringField component
  ###
  create_string_field: ({props}={}) ->
    props ?= {}

    column_key = props.column_key or @get_column_key()
    item = props.item or @get_item()
    name = props.name or @get_name()
    value = props.value or @get_value()
    formatted_value = props.formatted_value or @get_formatted_value()
    uid = props.uid or @get_uid()
    title = props.title or @props.column.title or column_key

    column = props.column or @get_column()
    item.help ?= {}
    help = props.help or item.help[column_key] or column.help

    converter = @ZPUBLISHER_CONVERTER["string"]
    fieldname = name + converter

    selected = props.selected or @is_selected()
    disabled = props.disabled or @is_disabled()
    required = props.required or @is_required()
    size = props.size or @get_size()
    css_class = props.css_class or "form-control form-control-sm"
    if required then css_class += " required"

    return (
      <StringField
        key={name}
        uid={uid}
        item={item}
        name={fieldname}
        defaultValue={value}
        column_key={column_key}
        title={title}
        help={help}
        formatted_value={formatted_value}
        placeholder={title}
        selected={selected}
        disabled={disabled}
        required={required}
        className={css_class}
        update_editable_field={@props.update_editable_field}
        save_editable_field={@props.save_editable_field}
        tabIndex={@props.tabIndex}
        size={size}
        {...props}
        />)

  ###*
   * Creates a text field component
   *
   * The passed in `props` allow to override required values
   *
   * @param props {object} properties passed to the component
   * @returns TextField component
  ###
  create_text_field: ({props}={}) ->
    props ?= {}

    column_key = props.column_key or @get_column_key()
    item = props.item or @get_item()
    name = props.name or @get_name()
    value = props.value or @get_value()
    formatted_value = props.formatted_value or @get_formatted_value()
    uid = props.uid or @get_uid()
    title = props.title or @props.column.title or column_key

    column = props.column or @get_column()
    item.help ?= {}
    help = props.help or item.help[column_key] or column.help

    converter = @ZPUBLISHER_CONVERTER["text"]
    fieldname = name + converter

    selected = props.selected or @is_selected()
    disabled = props.disabled or @is_disabled()
    required = props.required or @is_required()
    size = props.size or @get_size()
    css_class = props.css_class or "form-control form-control-sm"
    if required then css_class += " required"

    return (
      <TextField
        key={name}
        uid={uid}
        item={item}
        name={fieldname}
        defaultValue={value}
        column_key={column_key}
        title={title}
        help={help}
        formatted_value={formatted_value}
        placeholder={title}
        selected={selected}
        disabled={disabled}
        required={required}
        className={css_class}
        update_editable_field={@props.update_editable_field}
        save_editable_field={@props.save_editable_field}
        tabIndex={@props.tabIndex}
        size={size}
        {...props}
        />)

  ###*
   * Creates a fraction field component
   *
   * The passed in `props` allow to override required values
   *
   * @param props {object} properties passed to the component
   * @returns NumericField component
  ###
  create_fraction_field: ({props}={}) ->
    props ?= {}

    column_key = props.column_key or @get_column_key()
    item = props.item or @get_item()
    name = props.name or @get_name()
    value = props.value or @get_value()
    formatted_value = props.formatted_value or @get_formatted_value()
    uid = props.uid or @get_uid()
    title = props.title or @props.column.title or column_key

    column = props.column or @get_column()
    item.help ?= {}
    help = props.help or item.help[column_key] or column.help

    converter = @ZPUBLISHER_CONVERTER["fraction"]
    fieldname = name + converter

    selected = props.selected or @is_selected()
    disabled = props.disabled or @is_disabled()
    required = props.required or @is_required()
    size = props.size or @get_size()
    css_class = props.css_class or "form-control form-control-sm"
    if required then css_class += " required"

    return (
      <FractionField
        key={name}
        uid={uid}
        item={item}
        name={fieldname}
        defaultValue={value}
        column_key={column_key}
        title={title}
        help={help}
        formatted_value={formatted_value}
        placeholder={title}
        selected={selected}
        disabled={disabled}
        required={required}
        className={css_class}
        update_editable_field={@props.update_editable_field}
        save_editable_field={@props.save_editable_field}
        tabIndex={@props.tabIndex}
        size={size}
        {...props}
        />)

  ###*
   * Creates a datetime field component
   *
   * The passed in `props` allow to override required values
   *
   * @param props {object} properties passed to the component
   * @returns DateTime component
  ###
  create_datetime_field: ({props}={}) ->
    props ?= {}

    column_key = props.column_key or @get_column_key()
    item = props.item or @get_item()
    name = props.name or @get_name()
    value = props.value or @get_value()
    type = props.type or @get_type()
    formatted_value = props.formatted_value or @get_formatted_value()
    uid = props.uid or @get_uid()
    title = props.title or @props.column.title or column_key

    column = props.column or @get_column()
    item.help ?= {}
    help = props.help or item.help[column_key] or column.help

    result_type = "date"
    converter = @ZPUBLISHER_CONVERTER["string"]
    fieldname = name + converter

    selected = props.selected or @is_selected()
    disabled = props.disabled or @is_disabled()
    required = props.required or @is_required()
    size = props.size or @get_size()
    css_class = props.css_class or "form-control form-control-sm"

    if required then css_class += " required"

    # min/max dates
    min = column.min or null
    max = column.max or null

    if min
      [min_date, min_time] = min.split(" ")
    if max
      [max_date, max_time] = max.split(" ")

    return (
      <DateTime
        key={name}
        uid={uid}
        item={item}
        name={fieldname}
        defaultValue={value}
        column_key={column_key}
        title={title}
        help={help}
        formatted_value={formatted_value}
        placeholder={title}
        selected={selected}
        disabled={disabled}
        required={required}
        className={css_class}
        results_type={result_type}
        update_editable_field={@props.update_editable_field}
        save_editable_field={@props.save_editable_field}
        tabIndex={@props.tabIndex}
        size={size}
        type={type}
        min_date={min_date}
        max_date={max_date}
        min_time={min_time}
        max_time={max_time}
        {...props}
        />)

  ###*
   * Creates a select field component
   *
   * The passed in `props` allow to override required values
   *
   * @param props {object} properties passed to the component
   * @returns SelectField component
  ###
  create_select_field: ({props}={}) ->
    props ?= {}

    column_key = props.column_key or @get_column_key()
    item = props.item or @get_item()
    name = props.name or @get_name()
    value = props.value or @get_value()
    formatted_value = props.formatted_value or @get_formatted_value()
    uid = props.uid or @get_uid()
    title = props.title or @props.column.title or column_key
    options = props.options or item.choices[column_key] or []

    column = props.column or @get_column()
    item.help ?= {}
    help = props.help or item.help[column_key] or column.help

    converter = @ZPUBLISHER_CONVERTER["select"]
    fieldname = name + converter

    selected = props.selected or @is_selected()
    disabled = props.disabled or @is_disabled()
    required = props.required or @is_required()
    size = props.size or @get_size()
    css_class = props.css_class or "form-control form-control-sm"
    if required then css_class += " required"

    return (
      <Select
        key={name}
        uid={uid}
        item={item}
        name={fieldname}
        defaultValue={value}
        column_key={column_key}
        title={title}
        help={help}
        disabled={disabled}
        selected={selected}
        required={required}
        options={options}
        className={css_class}
        update_editable_field={@props.update_editable_field}
        save_editable_field={@props.save_editable_field}
        tabIndex={@props.tabIndex}
        size={size}
        {...props}
        />)

  ###*
   * Creates a multichoice field component
   *
   * The passed in `props` allow to override required values
   *
   * @param props {object} properties passed to the component
   * @returns MultiChoice component
  ###
  create_multichoice_field: ({props}={}) ->
    props ?= {}

    column_key = props.column_key or @get_column_key()
    item = props.item or @get_item()
    name = props.name or @get_name()
    value = props.value or @get_value()
    formatted_value = props.formatted_value or @get_formatted_value()
    uid = props.uid or @get_uid()
    title = props.title or @props.column.title or column_key
    options = props.options or item.choices[column_key] or []

    column = props.column or @get_column()
    item.help ?= {}
    help = props.help or item.help[column_key] or column.help

    converter = @ZPUBLISHER_CONVERTER["multichoice"]
    fieldname = name + converter

    selected = props.selected or @is_selected()
    disabled = props.disabled or @is_disabled()
    required = props.required or @is_required()
    size = props.size or @get_size()
    css_class = props.css_class or "form-control form-control-sm"
    if required then css_class += " required"

    return (
      <MultiChoice
        key={name}
        uid={uid}
        item={item}
        name={fieldname}
        defaultValue={value}
        column_key={column_key}
        title={title}
        help={help}
        disabled={disabled}
        selected={selected}
        required={required}
        options={options}
        className={css_class}
        update_editable_field={@props.update_editable_field}
        save_editable_field={@props.save_editable_field}
        tabIndex={@props.tabIndex}
        size={size}
        {...props}
        />)

  ###*
   * Creates a multiselect field component
   *
   * The passed in `props` allow to override required values
   *
   * @param props {object} properties passed to the component
   * @returns MultiSelect component
  ###
  create_multiselect_field: ({props}={}) ->
    props ?= {}

    column_key = props.column_key or @get_column_key()
    item = props.item or @get_item()
    name = props.name or @get_name()
    value = props.value or @get_value()
    formatted_value = props.formatted_value or @get_formatted_value()
    uid = props.uid or @get_uid()
    title = props.title or @props.column.title or column_key
    options = item.choices[column_key] or []
    duplicates = @get_type() == "multiselect_duplicates"

    column = props.column or @get_column()
    item.help ?= {}
    help = props.help or item.help[column_key] or column.help

    converter = @ZPUBLISHER_CONVERTER["multiselect"]
    fieldname = name + converter

    selected = props.selected or @is_selected()
    disabled = props.disabled or @is_disabled()
    required = props.required or @is_required()
    size = props.size or @get_size()
    css_class = props.css_class or "form-control form-control-sm"
    if required then css_class += " required"

    return (
      <MultiSelect
        key={name}
        uid={uid}
        item={item}
        name={fieldname}
        defaultValue={value}
        value={value}
        column_key={column_key}
        title={title}
        help={help}
        disabled={disabled}
        selected={selected}
        required={required}
        options={options}
        duplicates={duplicates}
        className={css_class}
        update_editable_field={@props.update_editable_field}
        save_editable_field={@props.save_editable_field}
        tabIndex={@props.tabIndex}
        size={size}
        {...props}
        />)

  ###*
   * Creates a multivalue field component
   *
   * The passed in `props` allow to override required values
   *
   * @param props {object} properties passed to the component
   * @returns MultiValue component
  ###
  create_multivalue_field: ({props}={}) ->
    props ?= {}

    column_key = props.column_key or @get_column_key()
    item = props.item or @get_item()
    name = props.name or @get_name()
    value = props.value or @get_value()
    formatted_value = props.formatted_value or @get_formatted_value()
    uid = props.uid or @get_uid()
    title = props.title or @props.column.title or column_key

    column = props.column or @get_column()
    item.help ?= {}
    help = props.help or item.help[column_key] or column.help

    converter = @ZPUBLISHER_CONVERTER["multivalue"]
    fieldname = name + converter

    selected = props.selected or @is_selected()
    disabled = props.disabled or @is_disabled()
    required = props.required or @is_required()
    size = props.size or @get_size()
    css_class = props.css_class or "form-control form-control-sm"
    if required then css_class += " required"

    return (
      <MultiValue
        key={name}
        uid={uid}
        item={item}
        name={fieldname}
        defaultValue={value}
        value={value}
        column_key={column_key}
        title={title}
        help={help}
        disabled={disabled}
        selected={selected}
        required={required}
        className={css_class}
        update_editable_field={@props.update_editable_field}
        save_editable_field={@props.save_editable_field}
        tabIndex={@props.tabIndex}
        size={size}
        {...props}
        />)

  ###*
   * Creates a checkbox field component
   *
   * The passed in `props` allow to override required values
   *
   * @param props {object} properties passed to the component
   * @returns Checkbox component
  ###
  create_checkbox_field: ({props}={}) ->
    props ?= {}

    column_key = props.column_key or @get_column_key()
    item = props.item or @get_item()
    name = props.name or @get_name()
    value = props.value or @get_value()
    formatted_value = props.formatted_value or @get_formatted_value()
    uid = props.uid or @get_uid()
    title = props.title or @props.column.title or column_key
    options = item.choices[column_key] or []

    column = props.column or @get_column()
    item.help ?= {}
    help = props.help or item.help[column_key] or column.help

    converter = @ZPUBLISHER_CONVERTER["boolean"]
    fieldname = name + converter

    selected = props.selected or @is_selected()
    disabled = props.disabled or @is_disabled()
    required = props.required or @is_required()
    size = props.size or @get_size()
    css_class = props.css_class or "checkbox"
    if required then css_class += " required"

    return (
      <Checkbox
        key={name}
        uid={uid}
        item={item}
        name={fieldname}
        value="on"
        column_key={column_key}
        title={title}
        help={help}
        defaultChecked={value}
        disabled={disabled}
        className={css_class}
        update_editable_field={@props.update_editable_field}
        save_editable_field={@props.save_editable_field}
        tabIndex={@props.tabIndex}
        size={size}
        {...props}
        />)

  render_content: ->
    # the current rendered column cell name
    column_key = @get_column_key()
    # single folderitem
    item = @get_item()
    # return if there is no item
    if not item
      console.warn "Skipping empty folderitem for column '#{column_key}'"
      return null
    # the UID of the folderitem
    uid = @get_uid()
    # field type to render
    type = @get_type()
    # the field to return
    field = []

    if type == "readonly"
      field = field.concat @create_readonly_field()
    else if type == "calculated"
      field = field.concat @create_calculated_field()
    else if type in ["select", "choices"]
      field = field.concat @create_select_field()
    else if type in ["multichoice"]
      field = field.concat @create_multichoice_field()
    else if type in ["multiselect", "multiselect_duplicates"]
      field = field.concat @create_multiselect_field()
    else if type in ["multivalue"]
      field = field.concat @create_multivalue_field()
    else if type == "boolean"
      field = field.concat @create_checkbox_field()
    else if type == "numeric"
      field = field.concat @create_numeric_field()
    else if type == "string"
      field = field.concat @create_string_field()
    else if type == "text"
      field = field.concat @create_text_field()
    else if type in ["date", "datetime"]
      field = field.concat @create_datetime_field()
    else if type == "fraction"
      field = field.concat @create_fraction_field()
    else
      field = field.concat @create_numeric_field()

    return field

  render: ->
    <td className={@props.className}
        colSpan={@props.colspan}
        rowSpan={@props.rowspan}>
      <div className="form-group">
        {@render_before_content()}
        {@render_content()}
        {@render_after_content()}
      </div>
    </td>


export default TableCell
