<div align="center">

  <a href="https://github.com/senaite/senaite.core.listing">
    <img src="static/logo.png" alt="senaite.core.listing" height="128" />
  </a>

  <p>ReactJS powered listings for SENAITE</p>

  <div>
    <a href="https://pypi.python.org/pypi/senaite.core.listing">
      <img src="https://img.shields.io/pypi/v/senaite.core.listing.svg?style=flat-square" alt="pypi-version" />
    </a>
    <a href="https://travis-ci.org/senaite/senaite.core.listing">
      <img src="https://img.shields.io/travis/senaite/senaite.core.listing.svg?style=flat-square" alt="travis-ci" />
    </a>
    <a href="https://github.com/senaite/senaite.core.listing/pulls">
      <img src="https://img.shields.io/github/issues-pr/senaite/senaite.core.listing.svg?style=flat-square" alt="open PRs" />
    </a>
    <a href="https://github.com/senaite/senaite.core.listing/issues">
      <img src="https://img.shields.io/github/issues/senaite/senaite.core.listing.svg?style=flat-square" alt="open Issues" />
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

This package provides a ReactJS based listing component for SENAITE.


## Screenshots

This section shows some screenshots how `senaite.core.listing` looks like.


### Samples Listing

<img src="static/1_samples_listing.png" alt="Samples Listing" />


### Worksheet Classic Listing

<img src="static/2_worksheet_classic_listing.png" alt="Worksheet Classic Listing" />


### Worksheet Transposed Listing

<img src="static/3_worksheet_transposed_listing.png" alt="Worksheet Transposed Listing" />


### Clients Listing

<img src="static/4_clients_listing.png" alt="Clients Listing" />


## Development

This package uses [webpack](https://webpack.js.org) to bundle all assets for the
final JavaScript file.

Used libraries:

    - ReactJS https://reactjs.org/


### Prerequisites

You need `node` and `npm` installed:

    » npm --version
    6.5.0

    » node --version
    v11.9.0

### Installation of JS Dependencies

Use `npm` (or `yarn`) to install the develoment dependencies:

    » yarn install

This creates a local node_modules directory where all the dependencies are stored.


You can now run `webpack` locally:

    » node_modules/.bin/webpack

Print usage (output below is cutted):

    » node_modules/.bin/webpack --help

    webpack-cli 3.2.1
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

    » npm run watch

Run this command to build the final JavaScript for Production:

    » npm run build
