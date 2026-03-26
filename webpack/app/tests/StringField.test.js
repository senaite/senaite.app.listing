import { render, fireEvent } from "@testing-library/react"
import StringField from "../components/StringField"


describe("StringField", () => {
  it("renders a text input with the given value", () => {
    const { container } = render(
      <StringField defaultValue="foo" uid="abc" name="Result" />
    )
    const input = container.querySelector("input[type='text']")
    expect(input).not.toBeNull()
    expect(input.value).toBe("foo")
  })

  it("uses default field_css when not provided", () => {
    const { container } = render(<StringField />)
    expect(container.querySelector("span.form-group")).not.toBeNull()
  })

  it("uses provided field_css", () => {
    const { container } = render(<StringField field_css="custom" />)
    expect(container.querySelector("span.custom")).not.toBeNull()
  })

  it("defaults size to 20", () => {
    const { container } = render(<StringField />)
    expect(container.querySelector("input").size).toBe(20)
  })

  it("uses provided size", () => {
    const { container } = render(<StringField size={40} />)
    expect(container.querySelector("input").size).toBe(40)
  })

  it("calls update_editable_field on change", () => {
    const update = jest.fn()
    const item = {uid: "abc"}
    const { container } = render(
      <StringField
        defaultValue=""
        uid="abc"
        column_key="Result"
        update_editable_field={update}
        item={item}
      />
    )
    const input = container.querySelector("input")
    fireEvent.change(input, {target: {value: "42"}})
    expect(update).toHaveBeenCalledWith("abc", "Result", "42", item)
  })

  it("uses props.onChange override when provided", () => {
    const override = jest.fn()
    const { container } = render(
      <StringField defaultValue="" onChange={override} />
    )
    fireEvent.change(container.querySelector("input"), {
      target: {value: "x"}
    })
    expect(override).toHaveBeenCalledTimes(1)
  })

  it("syncs value when defaultValue prop changes", () => {
    const { container, rerender } = render(
      <StringField defaultValue="initial" />
    )
    rerender(<StringField defaultValue="updated" />)
    expect(container.querySelector("input").value).toBe("updated")
  })

  it("renders before and after content", () => {
    const { container } = render(
      <StringField before="<b>pre</b>" after="<i>post</i>" />
    )
    expect(container.querySelector("span.before_field").innerHTML)
      .toBe("<b>pre</b>")
    expect(container.querySelector("span.after_field").innerHTML)
      .toBe("<i>post</i>")
  })

  it("does not render before/after spans when not provided", () => {
    const { container } = render(<StringField />)
    expect(container.querySelector("span.before_field")).toBeNull()
    expect(container.querySelector("span.after_field")).toBeNull()
  })

  it("spreads attrs onto the input", () => {
    const { container } = render(
      <StringField attrs={{"data-foo": "bar"}} />
    )
    expect(container.querySelector("input").getAttribute("data-foo"))
      .toBe("bar")
  })
})
