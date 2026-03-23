import { render } from "@testing-library/react"
import ReadonlyField from "../components/ReadonlyField"

// _t is a global injected by webpack in production; stub it for tests
global._t = (s) => s


describe("ReadonlyField", () => {
  it("renders formatted_value as HTML", () => {
    const { container } = render(
      <ReadonlyField formatted_value="<b>42</b>" />
    )
    expect(container.querySelector("b").textContent).toBe("42")
  })

  it("uses default field_css when not provided", () => {
    const { container } = render(<ReadonlyField />)
    expect(container.querySelector("span.form-group")).not.toBeNull()
  })

  it("uses provided field_css", () => {
    const { container } = render(
      <ReadonlyField field_css="custom-group" formatted_value="" />
    )
    expect(container.querySelector("span.custom-group")).not.toBeNull()
  })

  it("renders 'Yes' for boolean true", () => {
    const { container } = render(<ReadonlyField value={true} />)
    expect(container.textContent).toBe("Yes")
  })

  it("renders 'No' for boolean false", () => {
    const { container } = render(<ReadonlyField value={false} />)
    expect(container.textContent).toBe("No")
  })

  it("does not render the boolean wrapper for non-boolean values", () => {
    const { container } = render(
      <ReadonlyField value="some string" formatted_value="some string" />
    )
    expect(container.querySelector("span.form-group")).not.toBeNull()
  })

  it("renders before content with default css", () => {
    const { container } = render(
      <ReadonlyField before="<i>pre</i>" />
    )
    const before = container.querySelector("span.before_field")
    expect(before).not.toBeNull()
    expect(before.innerHTML).toBe("<i>pre</i>")
  })

  it("renders after content with custom css", () => {
    const { container } = render(
      <ReadonlyField after="<i>post</i>" after_css="unit" />
    )
    expect(container.querySelector("span.unit").innerHTML).toBe("<i>post</i>")
  })

  it("does not render before/after spans when not provided", () => {
    const { container } = render(<ReadonlyField />)
    expect(container.querySelector("span.before_field")).toBeNull()
    expect(container.querySelector("span.after_field")).toBeNull()
  })

  it("spreads attrs onto the value span", () => {
    const { container } = render(
      <ReadonlyField formatted_value="" attrs={{"data-uid": "abc"}} />
    )
    const spans = container.querySelectorAll("span.form-group > span")
    expect(spans[0].getAttribute("data-uid")).toBe("abc")
  })
})
