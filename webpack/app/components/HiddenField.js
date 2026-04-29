function HiddenField(props) {
  return (
    <span className={props.field_css || "form-group"}>
      {props.before && (
        <span
          className={props.before_css || "before_field"}
          dangerouslySetInnerHTML={{__html: props.before}}
        />
      )}
      <input
        type="hidden"
        uid={props.uid}
        name={props.name}
        value={props.value}
        column_key={props.column_key}
        className={props.className}
        {...props.attrs}
      />
      {props.formatted_value && (
        <span className="readonly"
              dangerouslySetInnerHTML={{__html: props.formatted_value}} />
      )}
      {props.after && (
        <span
          className={props.after_css || "after_field"}
          dangerouslySetInnerHTML={{__html: props.after}}
        />
      )}
    </span>
  )
}

export default HiddenField
