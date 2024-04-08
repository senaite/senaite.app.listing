2.6.0 (unreleased)
------------------

- #143 Allow date only fields in listings
- #141 Fix non-latin string used as filter parameter sends as encoded string
- #140 Fix missing category for updated items
- #139 Fix column sorting indicator is not initially displayed


2.5.0 (2024-01-03)
------------------

- #138 Fix object reindexing in workflow transition adapter
- #137 Support default values for multi-choices type
- #136 Fix server-side selected UIDs are not selected for new items after show more
- #135 Fix non-UID keyed folder items can not be pre-selected by the server
- #134 Fix APIError for non-UID listings
- #133 Multiselect with duplicates support for interim fields
- #132 Improve transposed interims formatting
- #131 Added FractionField for fraction-like results support
- #130 Fix missing custom transition buttons
- #127 Add Progress bar for sequential transitions
- #123 Move logic to calculate possible listing transitions for selected UIDs into an own adapter
- #126 Fix the size of string-type inputs is too small
- #125 Fix size attribute for interim fields is not taken into account
- #122 Add context menu for item transitions
- #121 Trigger event after sequential transitions
- #120 Auto-add dependents after listing transition
- #118 Fix listing's default review state does not have any effect
- #117 Compatibility with senaite.core i18n
- #116 Fix datetime value is not updated onchange
- #115 Support redirects after Ajax transitions
- #114 Fix Ajax Transitions for Transposed Worksheet Layout
- #113 Enable ajax transitions per default
- #112 Handle transition fails without UI notification
- #110 Sequential save action
- #109 Allow to set the size of input fields from inside cells
- #108 Sequential Ajax Transitions
- #107 Do not sort options for Select, MultiSelect and MultiChoice
- #106 Fix child items can not be selected in listings


2.4.0 (2023-03-10)
------------------

- #104 Allow to select all items in worksheet transposed view and layout design improvements
- #102 Support range selections for listing checkboxes
- #101 Allow to select all items of a category
- #100 Allow manual row reordering
-  #99 Fix TypeError for MultiValue fields when no Choices are set
-  #98 Fix left border gap for category rows
-  #97 Add own resource viewlet class
-  #95 Fix cannot sort when the query of the listing contains UID
-  #94 Fix action buttons are displayed for items without allowed transitions


2.3.0 (2022-10-03)
------------------

- #92 Add workflow state of view context to listing config
- #87 Add support to submit transitions via Ajax
- #86 Do not inject unit implicitly for fields
- #85 Support to refetch all folderitems on save
- #84 Support capital "E" for scientific notation
- #82 Allow custom confirmation messages for transitions
- #81 Allow scientific notation for numeric results
- #80 Allow additional hidden fields in listing form
- #79 Avoid duplicate listing form names
- #77 Fix items count in pagination when items are filtered programmatically
- #76 Fix multiselect allows duplicates when ResultValue is not a string
- #75 Reduce logging


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
