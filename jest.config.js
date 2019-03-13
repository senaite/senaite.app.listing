module.exports = {
  setupFiles: ["<rootDir>/src/senaite/core/listing/react/tests/setup.js"],
  moduleFileExtensions: ["coffee", "js", "json", "jsx", "ts", "tsx", "node"],
  transform: {
    ".*": "<rootDir>/src/senaite/core/listing/react/tests/preprocess.js"
  }
};
