const config = require('./config');
const { formatPrice } = require('./pricing');

function newCheckout(cart) {
  const total = cart.reduce((sum, item) => sum + item.cents * item.qty, 0);
  return { total: formatPrice(total), version: 2 };
}

function legacyCheckout(cart) {
  let total = 0;
  for (const item of cart) {
    total += item.cents * item.qty;
  }
  return { total: formatPrice(total), version: 1 };
}

function checkout(cart) {
  if (config.ENABLE_NEW_CHECKOUT) {
    return newCheckout(cart);
  }
  return legacyCheckout(cart);
}

module.exports = { checkout };
