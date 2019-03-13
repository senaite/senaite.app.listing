const path = require("path");
const webpack = require("webpack");

module.exports = {
  entry: {
    listing: path.resolve(__dirname, "./src/senaite/core/listing/react/listing.coffee")
  },
  output: {
    filename: "senaite.core.[name].js",
    path: path.resolve(__dirname, "./src/senaite/core/listing/static/js")
  },
  module: {
    rules: [
      {
        test: /\.coffee$/,
        exclude: [/node_modules/],
        use: ["babel-loader", "coffee-loader"]
      }, {
        test: /\.(js|jsx)$/,
        exclude: [/node_modules/],
        use: ["babel-loader"]
      }, {
        test: /\.css$/,
        use: ["style-loader", "css-loader"]
      }
    ]
  },
  plugins: [
    // e.g. https://webpack.js.org/plugins/provide-plugin/
  ],
  externals: {
    // https://webpack.js.org/configuration/externals
    // use jQuery from the outer scope
    jquery: "jQuery",
    bootstrap: "bootstrap",
    jsi18n: {
      root: "_"
    }
  }
};
