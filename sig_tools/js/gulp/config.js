var dest = "./dist";
var src = './js';

module.exports = {
  browserify: {
    // Enable source maps
    debug: true,
    // Additional file extensions to make optional
    extensions: ['.coffee', '.hbs'],
    // A separate bundle will be generated for each
    // bundle config in the list below
    bundleConfigs: [{
      entries: './js/digest.js',
      dest: dest,
      outputName: 'digest.js'
    }, {
      entries: './js/mortar.js',
      dest: dest,
      outputName: 'mortar.js'
    }]
  }
};
