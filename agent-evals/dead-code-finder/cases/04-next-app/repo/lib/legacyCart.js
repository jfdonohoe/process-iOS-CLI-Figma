// Client-side cart from before checkout moved to the hosted payment page.

export function addToCart(cart, product) {
  const existing = cart.find((line) => line.id === product.id);
  if (existing) {
    return cart.map((line) => (line.id === product.id ? { ...line, qty: line.qty + 1 } : line));
  }
  return [...cart, { id: product.id, qty: 1 }];
}

export function cartTotal(cart, products) {
  return cart.reduce((sum, line) => {
    const product = products.find((p) => p.id === line.id);
    return sum + (product ? product.cents * line.qty : 0);
  }, 0);
}
