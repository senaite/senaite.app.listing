const path = require("path");
const webpack = require("webpack");
const childProcess = require("child_process");

const HtmlWebpackPlugin = require("html-webpack-plugin");
const { CleanWebpackPlugin } = require("clean-webpack-plugin");

const gitCmd = "git rev-list -1 HEAD -- `pwd`";
let gitHash = childProcess.execSync(gitCmd).toString().substring(0, 7);

const staticPath = path.resolve(__dirname, "../src/senaite/app/listing/static");

const devMode = process.env.NODE_ENV !== 'production';


module.exports = {
  context: path.resolve(__dirname, "app"),
  entry: {
    listing: "./listing.coffee"
  },
  output: {
    filename: gitHash ? `senaite.app.listing-${gitHash}.js` : "senaite.core.[name].js",
    path: path.resolve(__dirname, "../src/senaite/app/listing/static/bundles"),
    publicPath: "++plone++senaite.app.listing.static/bundles"
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
    // https://github.com/johnagan/clean-webpack-plugin
    new CleanWebpackPlugin(),
    // https://webpack.js.org/plugins/html-webpack-plugin/
    new HtmlWebpackPlugin({
      inject: false,
      filename:  path.resolve(staticPath, "resources.pt"),
      template: "resources.pt",
    }),
    // https://webpack.js.org/plugins/provide-plugin/
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery",
    }),
  ],
  externals: {
    // https://webpack.js.org/configuration/externals
    react: "React",
    "react-dom": "ReactDOM",
    $: "jQuery",
    jquery: "jQuery",
    jsi18n: {
      root: "_t"
    }
  }
};
