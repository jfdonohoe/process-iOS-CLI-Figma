import { useRouter } from 'next/router';
import { PRODUCTS } from '../../lib/catalog';
import { formatMoney } from '../../lib/format';

export default function Product() {
  const { query } = useRouter();
  const product = PRODUCTS.find((p) => String(p.id) === query.id);
  if (!product) {
    return <p>Not found</p>;
  }
  return (
    <article>
      <h1>{product.name}</h1>
      <p>{formatMoney(product.cents)}</p>
    </article>
  );
}
