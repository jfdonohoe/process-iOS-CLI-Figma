const budget = { 'first-contentful-paint': 1800, 'total-byte-weight': 350000 };

console.log(JSON.stringify([{ path: '/*', timings: budget }], null, 2));
