import React from "react";


class SearchableSelect extends React.Component {
  /**
   * A searchable select/dropdown component that filters options as you type
   */

  constructor(props) {
    super(props);
    this.state = {
      is_open: false,
      // Seed from props so a preset / URL-restored value is visible
      // immediately instead of only after the next prop change.
      search_term: props.value || "",
      highlighted_index: -1
    };

    this.input_ref = React.createRef();
    this.dropdown_ref = React.createRef();

    this.on_input_change = this.on_input_change.bind(this);
    this.on_input_focus = this.on_input_focus.bind(this);
    this.on_input_blur = this.on_input_blur.bind(this);
    this.on_input_keydown = this.on_input_keydown.bind(this);
    this.on_option_click = this.on_option_click.bind(this);
    this.on_option_mouseenter = this.on_option_mouseenter.bind(this);
  }

  componentDidUpdate(prevProps) {
    // Update search term when value changes externally
    if (prevProps.value !== this.props.value) {
      this.setState({ search_term: this.props.value || "" });
    }
  }

  get_filtered_options() {
    /**
     * Filter options based on search term
     */
    const options = this.props.options || [];
    const search = (this.state.search_term || "").toLowerCase().trim();

    if (!search) {
      return options;
    }

    return options.filter((opt) => {
      const title = String(opt.title || opt.value || "").toLowerCase();
      const value = String(opt.value || "").toLowerCase();
      return title.indexOf(search) > -1 || value.indexOf(search) > -1;
    });
  }

  on_input_change(event) {
    const value = event.target.value;
    this.setState({
      search_term: value,
      is_open: true,
      highlighted_index: 0
    });

    // Also update parent with the typed value
    if (this.props.onChange) {
      this.props.onChange(value);
    }
  }

  on_input_focus(event) {
    this.setState({
      is_open: true,
      search_term: this.props.value || ""
    });

    if (this.props.onFocus) {
      this.props.onFocus(event);
    }
  }

  on_input_blur() {
    // Delay closing to allow click on option
    setTimeout(() => {
      this.setState({ is_open: false });
    }, 200);
  }

  on_input_keydown(event) {
    const filtered = this.get_filtered_options();
    // Limit to displayed options (max 100)
    const max_index = Math.min(filtered.length, 100) - 1;

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault();
        this.setState((state) => ({
          highlighted_index: Math.min(state.highlighted_index + 1, max_index)
        }));
        this.scroll_to_highlighted();
        break;

      case "ArrowUp":
        event.preventDefault();
        this.setState((state) => ({
          highlighted_index: Math.max(state.highlighted_index - 1, 0)
        }));
        this.scroll_to_highlighted();
        break;

      case "Enter":
        event.preventDefault();
        if (this.state.highlighted_index >= 0 &&
            this.state.highlighted_index <= max_index &&
            filtered[this.state.highlighted_index]) {
          this.select_option(filtered[this.state.highlighted_index]);
        } else if (this.props.onSubmit) {
          this.props.onSubmit();
        }
        break;

      case "Escape":
        this.setState({ is_open: false });
        if (this.input_ref.current) {
          this.input_ref.current.blur();
        }
        break;

      case "Tab":
        this.setState({ is_open: false });
        break;
    }
  }

  scroll_to_highlighted() {
    setTimeout(() => {
      if (this.dropdown_ref.current) {
        const highlighted = this.dropdown_ref.current.querySelector(".highlighted");
        if (highlighted && highlighted.scrollIntoView) {
          highlighted.scrollIntoView({ block: "nearest" });
        }
      }
    }, 0);
  }

  on_option_click(option, event) {
    event.preventDefault();
    event.stopPropagation();
    this.select_option(option);
  }

  on_option_mouseenter(index) {
    this.setState({ highlighted_index: index });
  }

  select_option(option) {
    const value = option.value;
    this.setState({
      search_term: value,
      is_open: false
    });

    if (this.props.onChange) {
      this.props.onChange(value);
    }

    if (this.props.onSelect) {
      this.props.onSelect(value);
    }
  }

  render() {
    const filtered_options = this.get_filtered_options();
    const show_dropdown = this.state.is_open && filtered_options.length > 0;

    return (
      <div className="searchable-select">
        <input
          ref={this.input_ref}
          type="text"
          className="form-control form-control-sm"
          placeholder={this.props.placeholder || _t("Type to search...")}
          value={this.state.search_term}
          onChange={this.on_input_change}
          onFocus={this.on_input_focus}
          onBlur={this.on_input_blur}
          onKeyDown={this.on_input_keydown}
          disabled={this.props.disabled}
        />

        {show_dropdown && (
          <div ref={this.dropdown_ref} className="searchable-select-dropdown">
            {filtered_options.slice(0, 100).map((option, index) => {
              const is_highlighted = index === this.state.highlighted_index;
              const is_selected = option.value === this.props.value;
              const cls = ["searchable-select-option"];
              if (is_highlighted) {
                cls.push("highlighted");
              }
              if (is_selected) {
                cls.push("selected");
              }

              return (
                <div
                  key={option.value}
                  className={cls.join(" ")}
                  onMouseDown={(e) => this.on_option_click(option, e)}
                  onMouseEnter={() => this.on_option_mouseenter(index)}
                >
                  {option.title || option.value}
                </div>
              );
            })}
            {filtered_options.length > 100 && (
              <div className="searchable-select-hint">
                {_t(`Showing 100 of ${filtered_options.length}. Type to filter.`)}
              </div>
            )}
          </div>
        )}
      </div>
    );
  }
}


export default SearchableSelect;
