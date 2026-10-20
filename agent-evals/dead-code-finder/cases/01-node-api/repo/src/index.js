const express = require('express');
const config = require('./config');
const { loadRoutes } = require('./routes');
const { checkout } = require('./checkout');
const rateLimit = require('./rateLimit');

const app = express();
app.use(express.json());

if (config.ENABLE_RATE_LIMIT) {
  app.use(rateLimit({ perMinute: 120 }));
}

loadRoutes(app);

app.post('/checkout', (req, res) => {
  res.json(checkout(req.body.cart));
});

app.listen(config.PORT, () => {
  console.log(`shop-api listening on ${config.PORT}`);
});
