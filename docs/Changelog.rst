2.2.0 (2022-06-10)
------------------

- #74 Multivalue support
- #73 Alternative text support for column headers
- #72 Multiselect/Multichoice support for interim fields
- #71 Allow URL redirect after Modal form submit
- #70 Allow custom transition sorting weights
- #69 Inject the form id into workflow action's POST
- #68 Added support for `on_change` hooks for changed folderitems
- #67 Allow to hook listings with Ajax edit form adapters
- #66 Change datetime component to separate date and time fields
- #65 Use searchable text index converter from catalog API
- #64 Improved listing search for queries containing non alphanumeric characters


2.1.0 (2022-01-05)
------------------

- #62 Compatibility with Senaite catalog migration
- #60 Fix alphanumeric result entries in WS transposed view
- #59 Fix column not added when neither after nor before params are set
- #59 Fix review state not added when neither after nor before params are set


2.0.0 (2021-07-26)
------------------

- #56 Added component DateTime field
- #58 Allow modal popups from workflow buttons
- #57 Set CSS selector only on select column
- #54 Improve fetch performance by marking readonly transactions explicitly
- #53 Integrate data managers to set field values
- #52 Fix double fetch of folderitems when the location hash changes
- #51 Browser history aware listings
- #50 Support child folder items to any depth
- #49 Set ajax folderitems to a readonly transaction


2.0.0rc3 (2021-01-04)
---------------------

- #47 Updated build system to Webpack 5
- #45 Add "Export" button next to Pagination
- #43 Allow "disabled" to be cell-specific
- #42 Allow to set the input size through item
- #41 Fix bad tabbing across elements from the listing
- #40 Fix url auto-resolution when object's path starts with portal id
- #39 Less intrusive table-overlay on loading


2.0.0rc2 (2020-10-13)
---------------------

- #38 Added event subscriber to reload the listing table
- #34 Set autofocus on search field
- #33 Added MultiSelect react component
- #32 MultiSelect component renamed to MultiChoice


2.0.0rc1 (2020-08-05)
---------------------

- Compatibility with `senaite.core` 2.x


1.5.3 (unreleased)
------------------

- #31 Dismiss items if cleared by subscribers


1.5.2 (2020-08-05)
------------------

- Missing files added over MANIFEST.in


1.5.1 (2020-08-05)
------------------

- Fixed release package


1.5.0 (2020-08-04)
------------------

- #28 Remove classic listing mode and improve folderitems


1.4.0 (2020-03-01)
------------------

- #25 Added tab index to result input fields
- #24 Improved column sorting and index lookup
- #23 Fix column config error


1.3.0 (2019-10-26)
------------------

- #21 Custom Column Configuration
- #20 Updated build system and JS package versions


1.2.0 (2019-07-01)
------------------

- #19 Omit disabled items when "select all" checkbox is selected
- #18 Support for string fields (added StringField react component)
- #17 Send the original query string with API calls
- #15 Allow custom button CSS definition in transition object
- #14 Convert URLs/Paths to absolute URLs
- #11 Notify edited event on set fields


1.1.0 (2019-03-30)
------------------

- #9 Show status messages on API errors
- #9 Only fetch affected folderitems by UID after a field was updated
- #7 Hide comment toggle in transposed cell when remarks are disabled
- #6 Allow to sort columns on catalog metadata columns
- #5 Detection Limit handling in the Frontend/Backend


1.0.0 (2019-02-04)
------------------

- Initial Release
