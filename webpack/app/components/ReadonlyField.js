function ReadonlyField({ value, field_css, before, before_css, after,
                         after_css, formatted_value, attrs }) {
  if (typeof value === "boolean") {
    return <span>{value ? _t("Yes") : _t("No")}</span>
  }

  return (
    <span className={field_css || "form-group"}>
      {before && (
        <span
          className={before_css || "before_field"}
          dangerouslySetInnerHTML={{__html: before}}
        />
      )}
      <span dangerouslySetInnerHTML={{__html: formatted_value}} {...attrs} />
      {after && (
        <span
          className={after_css || "after_field"}
          dangerouslySetInnerHTML={{__html: after}}
        />
      )}
    </span>
  )
}

export default ReadonlyField
