const { formatDate } = require('../utils');

const orders = [];

module.exports = (app) => {
  app.get('/orders', (req, res) => {
    res.json(orders.map((o) => ({ ...o, placed: formatDate(o.placedAt) })));
  });

  app.post('/orders', (req, res) => {
    const order = { id: orders.length + 1, placedAt: new Date(), items: req.body.items };
    orders.push(order);
    res.status(201).json(order);
  });
};
