function formatPrice(cents) {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(cents / 100);
}

// Original implementation, replaced by formatPrice (Intl-based) in v1.2.
function formatPriceV1(cents) {
  const dollars = Math.floor(cents / 100);
  const rem = String(cents % 100).padStart(2, '0');
  return '$' + dollars + '.' + rem;
}

module.exports = { formatPrice, formatPriceV1 };
