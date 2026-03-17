function HiddenField({ field_css, before, before_css, after, after_css,
                        uid, name, value, column_key, className, attrs }) {
  return (
    <span className={field_css || "form-group"}>
      {before && (
        <span
          className={before_css || "before_field"}
          dangerouslySetInnerHTML={{__html: before}}
        />
      )}
      <input
        type="hidden"
        uid={uid}
        name={name}
        value={value}
        column_key={column_key}
        className={className}
        {...attrs}
      />
      {after && (
        <span
          className={after_css || "after_field"}
          dangerouslySetInnerHTML={{__html: after}}
        />
      )}
    </span>
  )
}

export default HiddenField
