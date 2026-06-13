const PALETTE = [
  'oklch(0.70 0.16 145)',
  'oklch(0.78 0.13 70)',
  'oklch(0.66 0.15 300)',
  'oklch(0.70 0.16 30)',
  'oklch(0.72 0.12 180)',
];

export function getAccentColor(id: number): string {
  return PALETTE[id % PALETTE.length];
}

