const CURRENCY_SYMBOLS = {
  USD: '$',
  EUR: '€',
  GBP: '£',
};

export function formatMoney(cents) {
  const rounded = Math.round(cents);
  const remainder = rounded % 100;
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(rounded / 100);
}
