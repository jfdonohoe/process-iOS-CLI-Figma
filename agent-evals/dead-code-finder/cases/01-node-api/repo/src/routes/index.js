const ROUTES = ['orders', 'products'];

function loadRoutes(app) {
  for (const name of ROUTES) {
    require(`./${name}`)(app);
  }
}

module.exports = { loadRoutes };
