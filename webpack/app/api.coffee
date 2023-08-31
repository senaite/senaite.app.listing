###
 * Listing API Module
###

class ListingAPI

  constructor: (props) ->
    console.debug "ListingAPI::constructor"
    @api_url = props.api_url
    @form_id = props.form_id or "list"
    @on_api_error = props.on_api_error or (response) ->
      return
    return @

  get_base_url: () ->
    ###
     * Get the current base URL
     * @returns {string}
    ###
    base_url = document.body.dataset.baseUrl
    if base_url is undefined
      base_url = location.href.split("#")[0].split("?")[0]
    return base_url

  get_api_url: (endpoint) ->
    ###
     * Build API URL for the given endpoint
     * @param {string} endpoint
     * @returns {string}
    ###
    return "#{@api_url}/#{endpoint}#{location.search}"

  ###*
   * Prefix the name with the form_id
   *
   * @param name {string} The name to be prefixed
   * @returns {string}
  ###
  to_form_name: (name) ->
    if name.startsWith(@form_id)
      return name
    return "#{@form_id}_#{name}"

  ###*
   * Get the name parameter either from the search or hash location
   *
   * @param name {string} The parameter name
   * @returns {string}
  ###
  get_url_parameter: (name) ->
    ###
     * Parse a request parameter by name
    ###
    name = @to_form_name name
    name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]')
    regex = new RegExp('[\\?&]' + name + '=([^&#]*)')
    results = regex.exec(location.search) or regex.exec(location.hash)
    if results == null
      return ""
    return decodeURIComponent(results[1].replace(/\+/g, ' '))

  ###*
   * parse the hash location from a given string
   *
   * @param s {string} string
  ###
  parse_hash: (loc) ->
    index = loc.indexOf("#")
    if index == -1
      return []
    pairs = []
    hash = loc.substring(index).replace("#", "").replace("?", "")
    return hash.split("&")

  get_json: (endpoint, options) ->
    ###
     * Fetch Ajax API resource from the server
     * @param {string} endpoint
     * @param {object} options
     * @returns {Promise}
    ###
    options ?= {}

    method = options.method or "POST"
    data = JSON.stringify(options.data) or "{}"
    on_api_error = @on_api_error

    url = @get_api_url endpoint
    init =
      method: method
      headers:
        "Content-Type": "application/json"
        "X-CSRF-TOKEN": @get_csrf_token()
      body: if method is "POST" then data else null
      credentials: "include"
    console.info "ListingAPI::fetch:endpoint=#{endpoint} init=",init
    request = new Request(url, init)
    fetch(request)
    .then (response) ->
      if not response.ok
        return Promise.reject response
      return response
    .then (response) ->
      return response.json()
    .catch (response) ->
      on_api_error response
      return response

  set_fields: (data) ->
    ###
     * Set values of multiple fields
     * @returns {Promise}
    ###
    options =
      data: data or {}
      method: "POST"
    return @get_json "set_fields", options

  do_action_for: (data) ->
    ###
     * Transition multiple objects
     * @returns {Promise}
    ###
    options =
      data: data or {}
      method: "POST"
    return @get_json "do_action_for", options

  on_change: (data) ->
    ###
     * Call the on_change handler to refresh the data
     * @returns {Promise}
    ###
    options =
      data: data or {}
      method: "POST"
    return @get_json "on_change", options

  query_folderitems: (data) ->
    ###
     * Query folderitems
     * @returns {Promise}
    ###
    options =
      data: data or {}
      method: "POST"
    return @get_json "query_folderitems", options

  fetch_children: (data) ->
    ###
     * Query children
     * @returns {Promise}
    ###
    options =
      data: data or {}
      method: "POST"
    return @get_json "get_children", options

  fetch_folderitems: (data) ->
    ###
     * Fetch folder items
     * @returns {Promise}
    ###
    options =
      data: data or {}
      method: "POST"
    return @get_json "folderitems", options

  fetch_transitions: (data) ->
    ###
     * Fetch possible transitions
     * @returns {Promise}
    ###
    options =
      data: data or {}
      method: "POST"
    return @get_json "transitions", options

  fetch_listing_config: (data) ->
    ###
     * Fetch the  current listing  configuration
     * @returns {Promise}
    ###
    options =
      data: data or {}
      method: "POST"
    return @get_json "listing_config", options

  get_csrf_token: () ->
    ###
     * Get the plone.protect CSRF token
     * Note: The fields won't save w/o that token set
    ###
    return document.querySelector("#protect-script").dataset.token


export default ListingAPI
