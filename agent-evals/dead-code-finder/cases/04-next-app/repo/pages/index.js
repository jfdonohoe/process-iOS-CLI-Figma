import Link from 'next/link';
import { PRODUCTS } from '../lib/catalog';
import { formatMoney } from '../lib/format';

export default function Home() {
  return (
    <main>
      <h1>Storefront</h1>
      <ul>
        {PRODUCTS.map((p) => (
          <li key={p.id}>
            <Link href={`/products/${p.id}`}>{p.name}</Link> {formatMoney(p.cents)}
          </li>
        ))}
      </ul>
    </main>
  );
}
