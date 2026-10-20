const test = require('node:test');
const assert = require('node:assert');
const { formatPrice } = require('./pricing');

test('formatPrice formats cents as USD', () => {
  assert.strictEqual(formatPrice(1999), '$19.99');
});
