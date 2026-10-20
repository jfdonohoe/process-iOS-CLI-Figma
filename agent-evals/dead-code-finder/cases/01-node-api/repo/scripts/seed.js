const fs = require('fs');

const products = [
  { id: 1, name: 'Mug', cents: 1200 },
  { id: 2, name: 'Poster', cents: 2500 },
];

fs.writeFileSync('seed.json', JSON.stringify({ products }, null, 2));
console.log('seeded', products.length, 'products');
