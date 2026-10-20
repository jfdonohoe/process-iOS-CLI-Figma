function rateLimit({ perMinute }) {
  const hits = new Map();
  return (req, res, next) => {
    const minute = Math.floor(Date.now() / 60000);
    const key = `${req.ip}:${minute}`;
    const count = (hits.get(key) || 0) + 1;
    hits.set(key, count);
    if (count > perMinute) {
      return res.status(429).json({ error: 'rate limited' });
    }
    next();
  };
}

module.exports = rateLimit;
