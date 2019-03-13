import React from "react";
import Button from "../components/Button.coffee";
import { shallow, mount } from "enzyme";


describe("Button component", () => {
  it("renders the title in the button", () => {
    const wrapper = mount(<Button title="Click me"/>);
    const title = wrapper.find("span").text();
    expect(title).toEqual("Click me");
  });
});
