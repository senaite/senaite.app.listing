function ReadonlyField(props) {
  if (typeof props.value === "boolean") {
    return <span>{props.value ? _t("Yes") : _t("No")}</span>
  }

  return (
    <span className={props.field_css || "form-group"}>
      {props.before && (
        <span
          className={props.before_css || "before_field"}
          dangerouslySetInnerHTML={{__html: props.before}}
        />
      )}
      <span dangerouslySetInnerHTML={{__html: props.formatted_value}}
            {...props.attrs} />
      {props.after && (
        <span
          className={props.after_css || "after_field"}
          dangerouslySetInnerHTML={{__html: props.after}}
        />
      )}
    </span>
  )
}

export default ReadonlyField
