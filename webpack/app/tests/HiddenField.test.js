import { render } from "@testing-library/react"
import HiddenField from "../components/HiddenField"


describe("HiddenField", () => {
  it("renders a hidden input with uid, name and value", () => {
    const { container } = render(
      <HiddenField uid="abc" name="Result" value="42" />
    )
    const input = container.querySelector("input[type='hidden']")
    expect(input).not.toBeNull()
    expect(input.getAttribute("uid")).toBe("abc")
    expect(input.getAttribute("name")).toBe("Result")
    expect(input.value).toBe("42")
  })

  it("uses default field_css when not provided", () => {
    const { container } = render(<HiddenField />)
    expect(container.querySelector("span.form-group")).not.toBeNull()
  })

  it("uses provided field_css", () => {
    const { container } = render(<HiddenField field_css="custom-group" />)
    expect(container.querySelector("span.custom-group")).not.toBeNull()
  })

  it("renders before content when provided", () => {
    const { container } = render(
      <HiddenField before="<b>label</b>" />
    )
    const before = container.querySelector("span.before_field")
    expect(before).not.toBeNull()
    expect(before.innerHTML).toBe("<b>label</b>")
  })

  it("renders after content when provided", () => {
    const { container } = render(
      <HiddenField after="<i>unit</i>" after_css="unit-field" />
    )
    const after = container.querySelector("span.unit-field")
    expect(after).not.toBeNull()
    expect(after.innerHTML).toBe("<i>unit</i>")
  })

  it("does not render before/after spans when not provided", () => {
    const { container } = render(<HiddenField />)
    expect(container.querySelector("span.before_field")).toBeNull()
    expect(container.querySelector("span.after_field")).toBeNull()
  })

  it("spreads additional attrs onto the input", () => {
    const { container } = render(
      <HiddenField attrs={{"data-foo": "bar"}} />
    )
    const input = container.querySelector("input[type='hidden']")
    expect(input.getAttribute("data-foo")).toBe("bar")
  })
})
