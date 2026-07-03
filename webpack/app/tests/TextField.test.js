import { render, fireEvent } from "@testing-library/react"
import TextField from "../components/TextField"


describe("TextField", () => {
  it("renders a textarea with the given value", () => {
    const { container } = render(
      <TextField defaultValue="foo" uid="abc" name="Result" />
    )
    const textarea = container.querySelector("textarea")
    expect(textarea).not.toBeNull()
    expect(textarea.value).toBe("foo")
  })

  it("uses default field_css when not provided", () => {
    const { container } = render(<TextField />)
    expect(container.querySelector("span.form-group")).not.toBeNull()
  })

  it("uses provided field_css", () => {
    const { container } = render(<TextField field_css="custom" />)
    expect(container.querySelector("span.custom")).not.toBeNull()
  })

  it("defaults rows to 3 and cols to 20", () => {
    const { container } = render(<TextField />)
    const textarea = container.querySelector("textarea")
    expect(textarea.rows).toBe(3)
    expect(textarea.cols).toBe(20)
  })

  it("uses provided rows and size (cols)", () => {
    const { container } = render(<TextField rows={5} size={40} />)
    const textarea = container.querySelector("textarea")
    expect(textarea.rows).toBe(5)
    expect(textarea.cols).toBe(40)
  })

  it("calls update_editable_field on change", () => {
    const update = jest.fn()
    const item = {uid: "abc"}
    const { container } = render(
      <TextField
        defaultValue=""
        uid="abc"
        column_key="Result"
        update_editable_field={update}
        item={item}
      />
    )
    const textarea = container.querySelector("textarea")
    fireEvent.change(textarea, {target: {value: "42"}})
    expect(update).toHaveBeenCalledWith("abc", "Result", "42", item)
  })

  it("uses props.onChange override when provided", () => {
    const override = jest.fn()
    const { container } = render(
      <TextField defaultValue="" onChange={override} />
    )
    fireEvent.change(container.querySelector("textarea"), {
      target: {value: "x"}
    })
    expect(override).toHaveBeenCalledTimes(1)
  })

  it("syncs value when defaultValue prop changes", () => {
    const { container, rerender } = render(
      <TextField defaultValue="initial" />
    )
    rerender(<TextField defaultValue="updated" />)
    expect(container.querySelector("textarea").value).toBe("updated")
  })

  it("renders before and after content", () => {
    const { container } = render(
      <TextField before="<b>pre</b>" after="<i>post</i>" />
    )
    expect(container.querySelector("span.before_field").innerHTML)
      .toBe("<b>pre</b>")
    expect(container.querySelector("span.after_field").innerHTML)
      .toBe("<i>post</i>")
  })

  it("does not render before/after spans when not provided", () => {
    const { container } = render(<TextField />)
    expect(container.querySelector("span.before_field")).toBeNull()
    expect(container.querySelector("span.after_field")).toBeNull()
  })

  it("spreads attrs onto the textarea", () => {
    const { container } = render(
      <TextField attrs={{"data-foo": "bar"}} />
    )
    expect(container.querySelector("textarea").getAttribute("data-foo"))
      .toBe("bar")
  })
})
