const reviews = [];

module.exports = (app) => {
  app.get('/reviews', (req, res) => {
    res.json(reviews);
  });

  app.post('/reviews', (req, res) => {
    reviews.push(req.body);
    res.status(201).end();
  });
};
