const path = require('path');
const webpack = require('webpack');

module.exports = {
  mode: process.env.NODE_ENV || 'development',
  entry: './src/main.bs.js',
  output: {
      path: path.join(__dirname, './dist'),
      filename: 'bundle.js',
  },
  "plugins": [
    new webpack.BannerPlugin({ banner: "#!/usr/bin/env node", raw: true }),
  ]
};
