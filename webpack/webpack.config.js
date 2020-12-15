const path = require("path");
const webpack = require("webpack");
const childProcess = require("child_process");

const CssMinimizerPlugin = require("css-minimizer-webpack-plugin");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const TerserPlugin = require('terser-webpack-plugin');
const { CleanWebpackPlugin } = require("clean-webpack-plugin");

const gitCmd = "git rev-list -1 HEAD -- `pwd`";
let gitHash = childProcess.execSync(gitCmd).toString().substring(0, 7);

const staticPath = path.resolve(__dirname, "../src/senaite/app/listing/static");

const devMode = process.env.NODE_ENV == "development";
const mode = devMode ? "development" : "production";


module.exports = {
  // https://webpack.js.org/configuration/devtool
  devtool: devMode ? "eval" : "source-map",
  // https://webpack.js.org/configuration/mode/#usage
  mode: mode,
  context: path.resolve(__dirname, "app"),
  entry: {
    listing: "./listing.coffee"
  },
  output: {
    filename: devMode ? "senaite.app.[name].js" : `senaite.app.listing-${gitHash}.js`,
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
      {
        // SCSS
        test: /\.s[ac]ss$/i,
        use: [
          {
            // https://webpack.js.org/plugins/mini-css-extract-plugin/
            loader: MiniCssExtractPlugin.loader,
            options: {
              hmr: process.env.NODE_ENV === "development"
            },
          },
          {
            // https://webpack.js.org/loaders/css-loader/
            loader: "css-loader"
          },
          {
            // https://webpack.js.org/loaders/sass-loader/
            loader: "sass-loader"
          }
        ]
      },
    ]
  },
  optimization: {
    minimize: true,
    minimizer: [
      // https://webpack.js.org/plugins/terser-webpack-plugin/
      new TerserPlugin({
        extractComments: true,
        terserOptions: {
          compress: {
            drop_console: true,
          },
	      }
      }),
      // https://webpack.js.org/plugins/css-minimizer-webpack-plugin/
      new CssMinimizerPlugin({
        minimizerOptions: {
          preset: [
            "default",
            {
              discardComments: { removeAll: true },
            },
          ],
        },
      }),
    ],
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
