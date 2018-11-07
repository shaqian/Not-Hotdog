const path = require('path');

module.exports = {
  entry: "./src/index.js",
  output: {
    path: path.join(__dirname, '/dist'),
    publicPath: "/dist/",
    filename: 'bundle.js'
  },
  resolve: {
    modules: [
      "node_modules"
    ]
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /(node_modules)/,
        use: {
          loader: 'babel-loader'
        }
      },
      {
        test: /\.scss/,
        use: [
          'style-loader',
          {
            loader: 'css-loader',
            options: {
              url: false,
            }
          },
          {
            loader: 'sass-loader',
            options: {
              includePaths: [path.join(__dirname, 'src/styles')],
            }
          }
        ]
      },
    ]
  }
};

