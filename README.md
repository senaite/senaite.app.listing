<div align="center">

  <a href="https://github.com/senaite/senaite.app.listing">
    <img src="static/logo.png" alt="senaite.app.listing" height="128" />
  </a>

  <p>ReactJS powered listing tables for SENAITE LIMS</p>

  <div>
    <a href="https://pypi.python.org/pypi/senaite.app.listing">
      <img src="https://img.shields.io/pypi/v/senaite.app.listing.svg?style=flat-square" alt="pypi-version" />
    </a>
    <a href="https://travis-ci.org/senaite/senaite.app.listing">
      <img src="https://img.shields.io/travis/senaite/senaite.app.listing.svg?style=flat-square" alt="travis-ci" />
    </a>
    <a href="https://github.com/senaite/senaite.app.listing/pulls">
      <img src="https://img.shields.io/github/issues-pr/senaite/senaite.app.listing.svg?style=flat-square" alt="open PRs" />
    </a>
    <a href="https://github.com/senaite/senaite.app.listing/issues">
      <img src="https://img.shields.io/github/issues/senaite/senaite.app.listing.svg?style=flat-square" alt="open Issues" />
    </a>
    <a href="#">
      <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square" alt="pr" />
    </a>
    <a href="https://www.senaite.com">
      <img src="https://img.shields.io/badge/Made%20for%20SENAITE-%E2%AC%A1-lightgrey.svg" alt="Made for SENAITE" />
    </a>
  </div>
</div>


## About

This package provides a [ReactJS](https://reactjs.org) based
listing tables for [SENAITE LIMS](https://www.senaite.com).

[ReactJS](https://reactjs.org/) is a declarative, efficient, and flexible
JavaScript library for building user interfaces built by
[Facebook](https://github.com/facebook/react) and is licensed under the [MIT
License](https://github.com/facebook/react/blob/master/LICENSE)


## Screenshots

This section shows some screenshots how `senaite.app.listing` looks like.


### Samples Listing

<img src="static/1_samples_listing.png" alt="Samples Listing" />


### Worksheet Classic Listing

<img src="static/2_worksheet_classic_listing.png" alt="Worksheet Classic Listing" />


### Worksheet Transposed Listing

<img src="static/3_worksheet_transposed_listing.png" alt="Worksheet Transposed Listing" />


### Clients Listing

<img src="static/4_clients_listing.png" alt="Clients Listing" />


## Adapting Listings

In most cases, adding a subscriber adapter for `IListingView` is enough to
extend a given listing with additional columns, status or even behavior. With
the subscriber approach, a given listing can be modified multiple times by same
or different add-ons, without the need of inheritance and dependency bindings
amongst them. More information here: https://docs.zope.org/zope.interface/adapter.html#subscriptions

For instance, imagine you have two independent add-ons (A and B),
with the following use-case:

- A adds a column "DateStored" in Samples listing, along with filter "Stored"
- B adds a column "Participant" in Samples listing, along with filter "Ordered"
- Both changes are displayed in the result listing when A and B are installed

Making B dependent on A or the other way round is not a solution. With
subscriber adapters, we can address this problem easily as follows:

### 1. Create a subscriber adapter for each add-on

The skeleton of the subscriber adapter may look like follows:

```python
from bika.lims import api
from senaite.app.listing.interfaces import IListingView
from senaite.app.listing.interfaces import IListingViewAdapter
from senaite.app.listing.utils import add_column
from senaite.app.listing.utils import add_review_state
from zope.component import adapts
from zope.component import implements


class SamplesListingViewAdapter(object):
    adapts(IListingView)
    implements(IListingViewAdapter)

    def __init__(self, listing, context):
        self.listing = listing
        self.context = context

    def before_render(self):
        # Add new column for all available states
        states = map(lambda r: r["id"], self.listing.review_states)
        add_column(
            listing=self.listing,
            column_id="MyColumn",
            column_values={
                "title": "My new column",
                "sortable": False,
            },
            review_states=states)

    def folder_item(self, obj, item, index):
        item["MyColumn"] = api.get_object(obj).getMyColumnValue()
        return item
```

### 2. Register the subscriber adapter in configure.zcml

The next thing is to tell the system to use this adapter when the context is an
`AnalysisRequestFolder` object and the listing view is `AnalysisRequestsView`.
We assume here you created the subscriber adapter inside a `samples.py` file and
the configure.zcml is in that same directory:

```
  <!-- Samples view with additional filters and columns -->
  <subscriber
    for="bika.lims.browser.analysisrequest.AnalysisRequestsView
         bika.lims.interfaces.IAnalysisRequestsFolder"
    provides="senaite.app.listing.interfaces.IListingViewAdapter"
    factory=".samples.SamplesListingViewAdapter"
  />
```

Note that `AnalysisRequestsView` (from `senaite.core`) inherits from
`senaite.app.listing`'s `ListingView`, that in turn implements `IListingView`.


## Development

This package uses [webpack](https://webpack.js.org) to bundle all assets for the
final JavaScript file.

Used libraries:

    - ReactJS https://reactjs.org/


### Prerequisites

You need `node` and `npm` and `yarn` installed:

    » node --version
    v18.10.0

    » node --version
    8.19.2

    » yarn --version
    1.21.1


### Installation of JS Dependencies

Use `yarn` (or `npm`) to install the develoment dependencies:

    » cd webpack
    » yarn install

This creates a local node_modules directory where all the dependencies are stored.


You can now run `webpack` locally:

    » node_modules/.bin/webpack

Print usage (output below is cutted):

    » node_modules/.bin/webpack --help

    webpack: 5.69.1
    webpack-cli 4.9.2
    Usage: https://webpack.js.org/api/cli/
    Usage without config file: webpack <entry> [<entry>] --output [-o] <output>

    Initialization:
    --init             Initializes a new webpack configuration or loads a
                        addon if specified                                [boolean]

    Basic options:
    --watch, -w  Watch the filesystem for changes                        [boolean]
    -d           shortcut for --debug --devtool eval-cheap-module-source-map
                --output-pathinfo                                       [boolean]
    -p           shortcut for --optimize-minimize --define


### Building the Project for Production/Development

The following script commands which can be executed by the `npm run` command are
located in `package.json`.

The configuration for the used `webpack` command is located in `webpack.config.js`.


Run this command to watch/rebuild the JavaScript for Development:

    » yarn watch

Run this command to build the final JavaScript for Production:

    » yarn build


## License

**SENAITE.APP.LISTING** Copyright (C) RIDING BYTES & NARALABS

This program is free software; you can redistribute it and/or modify it under
the terms of the [GNU General Public License version
2](https://github.com/senaite/senaite.app.listing/blob/master/LICENSE)
as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.
