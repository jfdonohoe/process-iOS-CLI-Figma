const fs = require('fs');

const urls = ['/', '/products/1', '/products/2', '/products/3'];
const body = urls.map((u) => `  <url><loc>https://shop.example.com${u}</loc></url>`).join('\n');
fs.writeFileSync('public/sitemap.xml', `<urlset>\n${body}\n</urlset>\n`);
