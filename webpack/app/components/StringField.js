import { useState, useEffect, useCallback } from "react"


function StringField(props) {
  const { defaultValue, update_editable_field, item } = props
  const [value, setValue] = useState(defaultValue)

  useEffect(() => {
    setValue(defaultValue)
  }, [defaultValue])

  const on_change = useCallback((event) => {
    const el = event.currentTarget
    const el_uid = el.getAttribute("uid")
    const el_name = el.getAttribute("column_key") || el.name
    const el_value = el.value

    setValue(el_value)
    console.debug("StringField::on_change: value=" + el_value)

    if (update_editable_field) {
      update_editable_field(el_uid, el_name, el_value, item)
    }
  }, [update_editable_field, item])

  return (
    <span className={props.field_css || "form-group"}>
      {props.before && (
        <span
          className={props.before_css || "before_field"}
          dangerouslySetInnerHTML={{__html: props.before}}
        />
      )}
      <input
        type="text"
        size={props.size || 20}
        uid={props.uid}
        name={props.name}
        value={value}
        column_key={props.column_key}
        title={props.help || props.title}
        disabled={props.disabled}
        required={props.required}
        className={props.className}
        placeholder={props.placeholder}
        onChange={props.onChange || on_change}
        tabIndex={props.tabIndex}
        {...props.attrs}
      />
      {props.after && (
        <span
          className={props.after_css || "after_field"}
          dangerouslySetInnerHTML={{__html: props.after}}
        />
      )}
    </span>
  )
}

export default StringField
