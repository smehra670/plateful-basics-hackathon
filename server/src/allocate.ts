export type StockItem = {
  name: string;
  quantity?: number;
  unit?: string;
  expiryDate?: string | null;
};

export type RecipeNeed = {
  name: string;
  quantity: number;
  unit: string;
};

export type AllocationLine = {
  name: string;
  unit: string;
  needed: number;
  fromPantry: number;
  missing: number;
  unconfirmed: boolean;
};

const STAPLE =
  /^(salt|pepper|black pepper|oil|olive oil|vegetable oil|water|sugar|flour)$/i;

export function normalizeIngredientName(name: string): string {
  return name
    .trim()
    .toLowerCase()
    .replace(/s\b/, '')
    .replace(/[^a-z0-9\s]/g, '')
    .replace(/\s+/g, ' ');
}

type Canonical = { qty: number; unit: 'g' | 'ml' | 'pcs' | 'other'; raw: string };

function toCanonical(quantity: number, unit: string): Canonical {
  const u = (unit || 'pcs').trim().toLowerCase();
  if (['kg', 'kilogram', 'kilograms'].includes(u)) {
    return { qty: quantity * 1000, unit: 'g', raw: 'g' };
  }
  if (['g', 'gram', 'grams'].includes(u)) {
    return { qty: quantity, unit: 'g', raw: 'g' };
  }
  if (['l', 'liter', 'litre', 'liters', 'litres'].includes(u)) {
    return { qty: quantity * 1000, unit: 'ml', raw: 'ml' };
  }
  if (['ml', 'millilitre', 'milliliter'].includes(u)) {
    return { qty: quantity, unit: 'ml', raw: 'ml' };
  }
  if (['tbsp', 'tablespoon', 'tablespoons'].includes(u)) {
    return { qty: quantity * 15, unit: 'ml', raw: 'ml' };
  }
  if (['tsp', 'teaspoon', 'teaspoons'].includes(u)) {
    return { qty: quantity * 5, unit: 'ml', raw: 'ml' };
  }
  if (['pcs', 'pc', 'piece', 'pieces', 'item', 'items'].includes(u)) {
    return { qty: quantity, unit: 'pcs', raw: 'pcs' };
  }
  return { qty: quantity, unit: 'other', raw: u };
}

function namesMatch(a: string, b: string): boolean {
  const na = normalizeIngredientName(a);
  const nb = normalizeIngredientName(b);
  if (!na || !nb) return false;
  return na === nb || na.includes(nb) || nb.includes(na);
}

export function allocatePlan(options: {
  pantry: StockItem[];
  meals: Array<{ ingredients: RecipeNeed[]; servings: number }>;
}): {
  lines: AllocationLine[];
  pantryUsage: AllocationLine[];
  shopping: AllocationLine[];
} {
  const remaining = options.pantry.map((p) => ({
    name: p.name,
    ...toCanonical(p.quantity ?? 0, p.unit || 'pcs'),
    known: typeof p.quantity === 'number' && p.quantity > 0,
  }));

  const totals = new Map<
    string,
    { name: string; unit: Canonical['unit']; raw: string; needed: number }
  >();

  for (const meal of options.meals) {
    for (const ing of meal.ingredients) {
      if (STAPLE.test(ing.name)) continue;
      const c = toCanonical(ing.quantity, ing.unit);
      const key = `${normalizeIngredientName(ing.name)}|${c.unit}`;
      const prev = totals.get(key);
      if (prev) prev.needed += c.qty;
      else {
        totals.set(key, {
          name: ing.name,
          unit: c.unit,
          raw: c.raw,
          needed: c.qty,
        });
      }
    }
  }

  const lines: AllocationLine[] = [];
  for (const item of totals.values()) {
    let fromPantry = 0;
    let unconfirmed = false;
    for (const stock of remaining) {
      if (stock.unit !== item.unit && stock.unit !== 'other' && item.unit !== 'other') {
        continue;
      }
      if (!namesMatch(stock.name, item.name)) continue;
      if (!stock.known) {
        unconfirmed = true;
        continue;
      }
      const take = Math.min(stock.qty, item.needed - fromPantry);
      stock.qty -= take;
      fromPantry += take;
      if (fromPantry >= item.needed) break;
    }
    const missing = Math.max(0, item.needed - fromPantry);
    lines.push({
      name: item.name,
      unit: item.raw,
      needed: Number(item.needed.toFixed(1)),
      fromPantry: Number(fromPantry.toFixed(1)),
      missing: Number(missing.toFixed(1)),
      unconfirmed,
    });
  }

  return {
    lines,
    pantryUsage: lines.filter((l) => l.fromPantry > 0),
    shopping: lines.filter((l) => l.missing > 0 || l.unconfirmed),
  };
}

export const ALLERGEN_HINTS: Record<string, string[]> = {
  peanuts: ['peanut', 'groundnut'],
  'tree nuts': ['almond', 'walnut', 'cashew', 'pecan', 'hazelnut', 'pistachio', 'brazil'],
  dairy: ['milk', 'cheese', 'butter', 'yoghurt', 'yogurt', 'cream', 'whey'],
  eggs: ['egg'],
  gluten: ['wheat', 'barley', 'rye', 'seitan'],
  soy: ['soy', 'soya', 'tofu', 'edamame'],
  shellfish: ['shrimp', 'prawn', 'crab', 'lobster', 'mussel', 'clam'],
  fish: ['salmon', 'tuna', 'cod', 'haddock', 'fish'],
  sesame: ['sesame', 'tahini'],
};

/** Phrases that contain an allergen hint but are not that allergen. */
const ALLERGEN_EXCEPTIONS: Record<string, string[]> = {
  egg: ['eggplant', 'egg plant'],
  butter: [
    'peanut butter',
    'almond butter',
    'cashew butter',
    'cocoa butter',
    'apple butter',
    'shea butter',
    'butter bean',
    'butter beans',
    'butternut',
    'butter lettuce',
  ],
  milk: [
    'coconut milk',
    'almond milk',
    'oat milk',
    'soy milk',
    'soya milk',
    'rice milk',
    'hemp milk',
  ],
  cream: ['coconut cream', 'cream of tartar'],
  cheese: ['soy cheese', 'vegan cheese'],
  fish: [],
};

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/** True when [hint] is a whole word in [name], and not only inside an exception phrase. */
export function ingredientHitsHint(name: string, hint: string): boolean {
  const lower = name.toLowerCase();
  const word = new RegExp(`(^|[^a-z])${escapeRegExp(hint)}([^a-z]|$)`, 'i');
  if (!word.test(lower)) return false;
  const exceptions = ALLERGEN_EXCEPTIONS[hint] ?? [];
  if (exceptions.length === 0) return true;
  const stripped = exceptions.reduce(
    (text, phrase) => text.replace(new RegExp(escapeRegExp(phrase), 'gi'), ' '),
    lower,
  );
  return word.test(stripped);
}

export function recipeHitsAllergen(
  ingredientNames: string[],
  allergies: string[],
): string | null {
  for (const name of ingredientNames) {
    for (const allergy of allergies) {
      const key = allergy.toLowerCase();
      const hints = ALLERGEN_HINTS[key] || [key];
      for (const hint of hints) {
        if (ingredientHitsHint(name, hint)) return allergy;
      }
    }
  }
  return null;
}
