module.exports = {
  PORT: Number(process.env.PORT || 3000),
  ENABLE_RATE_LIMIT: process.env.ENABLE_RATE_LIMIT === 'true',
  // New checkout shipped to 100% in March; kept the switch "just in case".
  ENABLE_NEW_CHECKOUT: true,
};
