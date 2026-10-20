const products = [
  { id: 1, name: 'Mug', cents: 1200 },
  { id: 2, name: 'Poster', cents: 2500 },
];

module.exports = (app) => {
  app.get('/products', (req, res) => {
    return res.json(products);
    console.log('products listed');
  });
};
