export function applyGiftCard(totalCents, card) {
  if (!card || card.balanceCents <= 0) {
    return { totalCents, remainingBalanceCents: card ? card.balanceCents : 0 };
  }
  const applied = Math.min(totalCents, card.balanceCents);
  return { totalCents: totalCents - applied, remainingBalanceCents: card.balanceCents - applied };
}
