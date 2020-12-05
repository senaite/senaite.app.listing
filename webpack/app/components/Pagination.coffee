import React from "react"


class Pagination extends React.Component
  ###
   * The pagination component renders table paging controls
  ###

  constructor: (props) ->
    super(props)

    @state =
      pagesize: @props.pagesize

    # bind event handler to local context
    @on_show_more_click = @on_show_more_click.bind @
    @on_pagesize_change = @on_pagesize_change.bind @
    @on_export_click = @on_export_click.bind @

    # create element references
    @pagesize_input = React.createRef()
    @show_more_button = React.createRef()
    @export_button = React.createRef()

  on_show_more_click: (event) ->
    ###
     * Event handler when the "Show more" button was clicked
    ###

    # prevent form submission
    event.preventDefault()

    # parse the value of the pagesize input field
    pagesize = parseInt @pagesize_input.current.value

    # minimum pagesize is 1
    if not pagesize or pagesize < 1
      pagesize = 1

    # call the parent event handler
    @props.onShowMore pagesize

  on_pagesize_change: (event) ->
    ###
     * Event handler when a manual pagesize was entered
    ###

    pagesize = @get_pagesize_input_value()

    # set the pagesize to the local state
    @setState pagesize: pagesize

    # handle enter keypress
    if event.which == 13
      # prevent form submission
      event.preventDefault()

      # call the parent event listener
      @props.onShowMore pagesize

  get_pagesize_input_value: ->
    ###
     * Fetch the value of the pagesize input field
    ###

    pagesize = parseInt @pagesize_input.current.value

    if not pagesize or pagesize < 1
      # minimum pagesize is 1
      pagesize = 1
      # write sanitized value back to the field
      @pagesize_input.current.value = pagesize

    return pagesize

  on_export_click: (event) ->
    ###
     * Event handler when the "Export" button was clicked
    ###

    # prevent form submission
    event.preventDefault()
    console.debug "Pagination::on_export_click"

    # call the parent event handler
    @props.onExport()

  render: ->
    if @props.count >= @props.total
      <div id={@props.id} className={@props.className}>
        {not @props.show_export and
        <div className="text-right">
          {@props.count} / {@props.total}
        </div>
        }
        {@props.show_export and
        <div className="input-group input-group-sm float-right">
          <div className="input-group-prepend">
            <span className="input-group-text">{@props.count} / {@props.total}</span>
          </div>
          <span className="input-group-append">
            <button className="btn btn-outline-secondary"
                    ref={@export_button}
                    disabled={@props.count == 0}
                    onClick={@on_export_click}>
              <span>{@props.export_button_title or "Export"}</span>
            </button>
          </span>
        </div>
        }
      </div>
    else
      <div id={@props.id} className={@props.className}>
        <div className="input-group input-group-sm float-right">
          <div className="input-group-prepend">
            <span className="input-group-text">{@props.count} / {@props.total}</span>
          </div>
          <input type="text"
                 size="3"
                 defaultValue={@state.pagesize}
                 onChange={@on_pagesize_change}
                 onKeyPress={@on_pagesize_change}
                 ref={@pagesize_input}
                 disabled={@props.count >= @props.total}
                 className="form-control"/>
          <span className="input-group-append">
            <button className="btn btn-outline-secondary"
                    disabled={@props.count >= @props.total}
                    ref={@show_more_button}
                    onClick={@on_show_more_click}>
              <span>{@props.show_more_button_title or "Show more"}</span>
            </button>
            {@props.show_export and
            <button className="btn btn-outline-secondary"
                    ref={@export_button}
                    disabled={@props.count == 0}
                    onClick={@on_export_click}>
              <span>{@props.export_button_title or "Export"}</span>
            </button>
            }
          </span>
        </div>
      </div>


export default Pagination
