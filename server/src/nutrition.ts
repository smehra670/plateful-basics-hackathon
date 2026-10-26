/** Per-100g values from common food-composition figures (kcal, protein, carbs, fat, sugar). */

type Food = {
  keys: string[];
  kcal: number;
  p: number;
  c: number;
  f: number;
  sugar: number;
  piece?: number;
};

const FOODS: Food[] = [
  { keys: ['olive oil', 'sesame oil', 'vegetable oil', 'sunflower oil', 'rapeseed oil', 'cooking oil', 'oil'], kcal: 884, p: 0, c: 0, f: 100, sugar: 0 },
  { keys: ['coconut oil'], kcal: 892, p: 0, c: 0, f: 100, sugar: 0 },
  { keys: ['butter'], kcal: 717, p: 0.9, c: 0.1, f: 81, sugar: 0.1 },
  { keys: ['double cream', 'heavy cream', 'whipping cream'], kcal: 340, p: 2, c: 3, f: 36, sugar: 3 },
  { keys: ['single cream', 'cream'], kcal: 195, p: 2.8, c: 3.6, f: 19, sugar: 3.6 },
  { keys: ['greek yogurt', 'greek yoghurt'], kcal: 97, p: 9, c: 3.6, f: 5, sugar: 3.6 },
  { keys: ['yogurt', 'yoghurt'], kcal: 63, p: 5.3, c: 7, f: 1.6, sugar: 7 },
  { keys: ['cheddar', 'cheese'], kcal: 403, p: 25, c: 1.3, f: 33, sugar: 0.5 },
  { keys: ['parmesan', 'parmigiano'], kcal: 431, p: 38, c: 4, f: 29, sugar: 0.9 },
  { keys: ['mozzarella'], kcal: 280, p: 28, c: 3, f: 17, sugar: 1 },
  { keys: ['feta'], kcal: 264, p: 14, c: 4, f: 21, sugar: 4 },
  { keys: ['halloumi'], kcal: 321, p: 22, c: 2, f: 25, sugar: 1 },
  { keys: ['cream cheese'], kcal: 342, p: 6, c: 4, f: 34, sugar: 3 },
  { keys: ['cottage cheese'], kcal: 98, p: 11, c: 3.4, f: 4.3, sugar: 2.7 },
  { keys: ['milk chocolate', 'chocolate spread'], kcal: 535, p: 8, c: 59, f: 30, sugar: 52 },
  { keys: ['dark chocolate', 'chocolate'], kcal: 598, p: 7.8, c: 46, f: 43, sugar: 24 },
  { keys: ['cocoa powder', 'cocoa'], kcal: 228, p: 20, c: 58, f: 14, sugar: 1.8 },
  { keys: ['coconut milk'], kcal: 197, p: 2, c: 3, f: 21, sugar: 3 },
  { keys: ['almond milk'], kcal: 15, p: 0.6, c: 0.3, f: 1.1, sugar: 0 },
  { keys: ['soy milk', 'oat milk'], kcal: 43, p: 3, c: 5, f: 1.5, sugar: 3 },
  { keys: ['whole milk', 'semi-skimmed', 'semi skimmed', 'skimmed milk', 'milk'], kcal: 47, p: 3.4, c: 4.8, f: 1.8, sugar: 4.8 },
  { keys: ['peanut butter'], kcal: 588, p: 25, c: 20, f: 50, sugar: 9 },
  { keys: ['almonds', 'almond'], kcal: 579, p: 21, c: 22, f: 50, sugar: 4 },
  { keys: ['peanuts', 'peanut'], kcal: 567, p: 26, c: 16, f: 49, sugar: 4 },
  { keys: ['cashews', 'cashew'], kcal: 553, p: 18, c: 30, f: 44, sugar: 6 },
  { keys: ['walnuts', 'walnut'], kcal: 654, p: 15, c: 14, f: 65, sugar: 2.6 },
  { keys: ['chia'], kcal: 486, p: 17, c: 42, f: 31, sugar: 0 },
  { keys: ['pumpkin seed'], kcal: 559, p: 30, c: 11, f: 49, sugar: 1.4 },
  { keys: ['mayonnaise', 'mayo'], kcal: 680, p: 1, c: 0.6, f: 75, sugar: 0.6 },
  { keys: ['hummus'], kcal: 166, p: 8, c: 14, f: 10, sugar: 0.3 },
  { keys: ['honey'], kcal: 304, p: 0.3, c: 82, f: 0, sugar: 82 },
  { keys: ['maple'], kcal: 260, p: 0, c: 67, f: 0, sugar: 60 },
  { keys: ['jam', 'marmalade'], kcal: 250, p: 0.4, c: 65, f: 0.1, sugar: 49 },
  { keys: ['sugar', 'caster', 'icing sugar'], kcal: 387, p: 0, c: 100, f: 0, sugar: 100 },
  { keys: ['plain flour', 'self-raising', 'self raising', 'all-purpose', 'flour'], kcal: 364, p: 10, c: 76, f: 1, sugar: 0.3 },
  { keys: ['wholemeal flour', 'whole wheat flour'], kcal: 340, p: 13, c: 72, f: 2.5, sugar: 0.4 },
  { keys: ['cornflour', 'cornstarch'], kcal: 381, p: 0.3, c: 91, f: 0.1, sugar: 0 },
  { keys: ['oats', 'porridge', 'oatmeal'], kcal: 389, p: 17, c: 66, f: 7, sugar: 1 },
  { keys: ['breadcrumbs', 'breadcrumb'], kcal: 395, p: 13, c: 72, f: 5, sugar: 6 },
  { keys: ['sourdough', 'bread'], kcal: 265, p: 9, c: 49, f: 3.2, sugar: 5, piece: 30 },
  { keys: ['pitta', 'pita'], kcal: 275, p: 9, c: 56, f: 1.2, sugar: 1.5, piece: 60 },
  { keys: ['tortilla', 'wrap'], kcal: 312, p: 8, c: 52, f: 8, sugar: 2, piece: 45 },
  { keys: ['bagel'], kcal: 257, p: 10, c: 50, f: 1.6, sugar: 6, piece: 90 },
  { keys: ['croissant'], kcal: 406, p: 8, c: 46, f: 21, sugar: 11, piece: 60 },
  { keys: ['pasta', 'spaghetti', 'penne', 'macaroni', 'noodle', 'noodles'], kcal: 371, p: 13, c: 75, f: 1.5, sugar: 2.7 },
  { keys: ['rice noodle'], kcal: 364, p: 6, c: 80, f: 0.6, sugar: 0 },
  { keys: ['cooked rice', 'rice'], kcal: 365, p: 7, c: 80, f: 0.7, sugar: 0.1 },
  { keys: ['quinoa'], kcal: 368, p: 14, c: 64, f: 6, sugar: 0 },
  { keys: ['couscous'], kcal: 376, p: 13, c: 77, f: 0.6, sugar: 0 },
  { keys: ['chickpea', 'chickpeas'], kcal: 164, p: 8.9, c: 27, f: 2.6, sugar: 4.8 },
  { keys: ['lentil', 'lentils'], kcal: 116, p: 9, c: 20, f: 0.4, sugar: 1.8 },
  { keys: ['kidney bean', 'black bean', 'cannellini', 'butter bean', 'beans'], kcal: 127, p: 8.7, c: 23, f: 0.5, sugar: 0.3 },
  { keys: ['edamame'], kcal: 121, p: 12, c: 9, f: 5, sugar: 2 },
  { keys: ['firm tofu', 'tofu'], kcal: 144, p: 17, c: 3, f: 9, sugar: 0 },
  { keys: ['tempeh'], kcal: 192, p: 20, c: 8, f: 11, sugar: 0 },
  { keys: ['chicken breast', 'chicken'], kcal: 120, p: 22.5, c: 0, f: 2.6, sugar: 0, piece: 170 },
  { keys: ['chicken thigh'], kcal: 177, p: 24, c: 0, f: 8, sugar: 0, piece: 110 },
  { keys: ['turkey'], kcal: 135, p: 30, c: 0, f: 1, sugar: 0, piece: 120 },
  { keys: ['beef mince', 'mince', 'ground beef', 'beef'], kcal: 215, p: 19, c: 0, f: 15, sugar: 0 },
  { keys: ['steak'], kcal: 271, p: 26, c: 0, f: 18, sugar: 0, piece: 200 },
  { keys: ['lamb'], kcal: 294, p: 25, c: 0, f: 21, sugar: 0 },
  { keys: ['pork'], kcal: 242, p: 27, c: 0, f: 14, sugar: 0 },
  { keys: ['bacon'], kcal: 541, p: 37, c: 1.4, f: 42, sugar: 0, piece: 20 },
  { keys: ['sausage'], kcal: 301, p: 13, c: 2, f: 27, sugar: 1, piece: 60 },
  { keys: ['ham'], kcal: 145, p: 21, c: 1.5, f: 6, sugar: 1, piece: 20 },
  { keys: ['salami', 'chorizo', 'pepperoni'], kcal: 336, p: 22, c: 1, f: 27, sugar: 0, piece: 15 },
  { keys: ['salmon'], kcal: 208, p: 20, c: 0, f: 13, sugar: 0, piece: 150 },
  { keys: ['tuna'], kcal: 116, p: 26, c: 0, f: 1, sugar: 0 },
  { keys: ['cod', 'haddock', 'white fish', 'fish fillet', 'fish'], kcal: 82, p: 18, c: 0, f: 0.7, sugar: 0, piece: 150 },
  { keys: ['prawn', 'shrimp'], kcal: 99, p: 24, c: 0.2, f: 0.3, sugar: 0 },
  { keys: ['mackerel', 'sardine'], kcal: 205, p: 19, c: 0, f: 14, sugar: 0, piece: 80 },
  { keys: ['egg', 'eggs'], kcal: 143, p: 13, c: 1.1, f: 9.5, sugar: 1.1, piece: 50 },
  { keys: ['banana'], kcal: 89, p: 1.1, c: 23, f: 0.3, sugar: 12, piece: 118 },
  { keys: ['apple'], kcal: 52, p: 0.3, c: 14, f: 0.2, sugar: 10, piece: 180 },
  { keys: ['orange'], kcal: 47, p: 0.9, c: 12, f: 0.1, sugar: 9, piece: 130 },
  { keys: ['lemon'], kcal: 29, p: 1.1, c: 9, f: 0.3, sugar: 2.5, piece: 60 },
  { keys: ['lime'], kcal: 30, p: 0.7, c: 11, f: 0.2, sugar: 1.7, piece: 67 },
  { keys: ['strawberry', 'strawberries'], kcal: 32, p: 0.7, c: 7.7, f: 0.3, sugar: 4.9 },
  { keys: ['blueberry', 'blueberries'], kcal: 57, p: 0.7, c: 14, f: 0.3, sugar: 10 },
  { keys: ['grape', 'grapes'], kcal: 69, p: 0.7, c: 18, f: 0.2, sugar: 15 },
  { keys: ['mango'], kcal: 60, p: 0.8, c: 15, f: 0.4, sugar: 14, piece: 200 },
  { keys: ['pineapple'], kcal: 50, p: 0.5, c: 13, f: 0.1, sugar: 10 },
  { keys: ['avocado'], kcal: 160, p: 2, c: 8.5, f: 15, sugar: 0.7, piece: 150 },
  { keys: ['tomato', 'tomatoes', 'passata', 'tinned tomato'], kcal: 18, p: 0.9, c: 3.9, f: 0.2, sugar: 2.6, piece: 120 },
  { keys: ['spinach'], kcal: 23, p: 2.9, c: 3.6, f: 0.4, sugar: 0.4 },
  { keys: ['kale'], kcal: 49, p: 4.3, c: 9, f: 0.9, sugar: 2.3 },
  { keys: ['lettuce', 'salad leaf', 'rocket', 'arugula'], kcal: 15, p: 1.4, c: 2.9, f: 0.2, sugar: 0.8 },
  { keys: ['onion'], kcal: 40, p: 1.1, c: 9.3, f: 0.1, sugar: 4.2, piece: 150 },
  { keys: ['spring onion', 'scallion'], kcal: 32, p: 1.8, c: 7, f: 0.2, sugar: 2.3, piece: 15 },
  { keys: ['garlic'], kcal: 149, p: 6.4, c: 33, f: 0.5, sugar: 1, piece: 3 },
  { keys: ['potato'], kcal: 77, p: 2, c: 17, f: 0.1, sugar: 0.8, piece: 170 },
  { keys: ['sweet potato'], kcal: 86, p: 1.6, c: 20, f: 0.1, sugar: 4.2, piece: 130 },
  { keys: ['carrot'], kcal: 41, p: 0.9, c: 10, f: 0.2, sugar: 4.7, piece: 60 },
  { keys: ['broccoli'], kcal: 34, p: 2.8, c: 7, f: 0.4, sugar: 1.7 },
  { keys: ['cauliflower'], kcal: 25, p: 1.9, c: 5, f: 0.3, sugar: 1.9 },
  { keys: ['cabbage'], kcal: 25, p: 1.3, c: 6, f: 0.1, sugar: 3.2 },
  { keys: ['courgette', 'zucchini'], kcal: 17, p: 1.2, c: 3.1, f: 0.3, sugar: 2.5 },
  { keys: ['aubergine', 'eggplant'], kcal: 25, p: 1, c: 6, f: 0.2, sugar: 3.5 },
  { keys: ['bell pepper', 'red pepper', 'green pepper', 'yellow pepper'], kcal: 31, p: 1, c: 6, f: 0.3, sugar: 4.2, piece: 120 },
  { keys: ['chilli', 'chili'], kcal: 40, p: 1.9, c: 9, f: 0.4, sugar: 5, piece: 15 },
  { keys: ['cucumber'], kcal: 15, p: 0.7, c: 3.6, f: 0.1, sugar: 1.7 },
  { keys: ['mushroom', 'mushrooms'], kcal: 22, p: 3.1, c: 3.3, f: 0.3, sugar: 2 },
  { keys: ['peas', 'pea'], kcal: 81, p: 5.4, c: 14, f: 0.4, sugar: 5.7 },
  { keys: ['sweetcorn', 'corn'], kcal: 86, p: 3.3, c: 19, f: 1.2, sugar: 6.3 },
  { keys: ['green bean'], kcal: 31, p: 1.8, c: 7, f: 0.2, sugar: 3.3 },
  { keys: ['asparagus'], kcal: 20, p: 2.2, c: 3.9, f: 0.1, sugar: 1.9 },
  { keys: ['leek'], kcal: 61, p: 1.5, c: 14, f: 0.3, sugar: 3.9, piece: 90 },
  { keys: ['celery'], kcal: 14, p: 0.7, c: 3, f: 0.2, sugar: 1.3 },
  { keys: ['ginger'], kcal: 80, p: 1.8, c: 18, f: 0.8, sugar: 1.7 },
  { keys: ['raisin', 'sultana'], kcal: 299, p: 3.1, c: 79, f: 0.5, sugar: 59 },
  { keys: ['date', 'dates'], kcal: 277, p: 1.8, c: 75, f: 0.2, sugar: 63, piece: 7 },
  { keys: ['ice cream'], kcal: 207, p: 3.5, c: 24, f: 11, sugar: 21 },
  { keys: ['soy sauce'], kcal: 53, p: 8, c: 5, f: 0.1, sugar: 0.4 },
  { keys: ['stock', 'broth'], kcal: 7, p: 0.5, c: 0.5, f: 0.2, sugar: 0.2 },
  { keys: ['wine'], kcal: 83, p: 0.1, c: 2.6, f: 0, sugar: 0.6 },
  { keys: ['vinegar'], kcal: 21, p: 0, c: 0.9, f: 0, sugar: 0.4 },
  { keys: ['parsley', 'coriander', 'cilantro', 'basil', 'herb', 'mint'], kcal: 36, p: 3, c: 6, f: 0.8, sugar: 0.9 },
  { keys: ['salt', 'pepper', 'black pepper', 'water', 'ice'], kcal: 0, p: 0, c: 0, f: 0, sugar: 0 },
];

const KEYS = FOODS.flatMap((food) => food.keys.map((key) => ({ key, food }))).sort(
  (a, b) => b.key.length - a.key.length,
);

const FIBRE_PER_100G: Array<[string, number]> = [
  ['chia', 34],
  ['almond', 12],
  ['lentil', 8],
  ['chickpea', 8],
  ['oat', 10],
  ['porridge', 10],
  ['quinoa', 7],
  ['bean', 7],
  ['wholemeal', 7],
  ['avocado', 6.7],
  ['hummus', 6],
  ['pea', 5],
  ['pear', 3.1],
  ['apple', 2.4],
  ['banana', 2.6],
  ['orange', 2.4],
  ['broccoli', 2.6],
  ['carrot', 2.8],
  ['sweet potato', 3],
  ['potato', 2.2],
  ['spinach', 2.2],
  ['bread', 2.7],
  ['pasta', 3.5],
  ['noodle', 1.8],
  ['rice', 1.4],
  ['flour', 3],
  ['tomato', 1.2],
  ['onion', 1.7],
  ['cabbage', 2.5],
  ['berry', 2.4],
  ['strawberry', 2],
  ['mango', 1.6],
];

function fibrePer100g(name: string): number {
  const n = name.toLowerCase();
  const hit = [...FIBRE_PER_100G]
    .sort((a, b) => b[0].length - a[0].length)
    .find(([key]) => n.includes(key));
  return hit?.[1] ?? 0;
}

export type RecipeMacros = {
  calories: number;
  protein: number;
  carbohydrates: number;
  fat: number;
  sugar: number;
  fibre: number;
};

function lookup(name: string): Food | undefined {
  const n = name.toLowerCase();
  return KEYS.find((entry) => n.includes(entry.key))?.food;
}

function toGrams(quantity: number, unit: string, food?: Food): number {
  const u = unit.toLowerCase().replace(/\./g, '').trim();
  if (['g', 'gram', 'grams'].includes(u)) return quantity;
  if (['kg', 'kilogram', 'kilograms'].includes(u)) return quantity * 1000;
  if (['ml', 'millilitre', 'milliliter', 'millilitres'].includes(u)) return quantity;
  if (['l', 'litre', 'liter', 'litres'].includes(u)) return quantity * 1000;
  if (['tbsp', 'tablespoon', 'tablespoons'].includes(u)) return quantity * 15;
  if (['tsp', 'teaspoon', 'teaspoons'].includes(u)) return quantity * 5;
  if (['cup', 'cups'].includes(u)) return quantity * 240;
  if (['oz', 'ounce', 'ounces'].includes(u)) return quantity * 28.35;
  if (['lb', 'lbs', 'pound', 'pounds'].includes(u)) return quantity * 453.6;
  if (['clove', 'cloves'].includes(u)) return quantity * (food?.piece ?? 3);
  if (['slice', 'slices'].includes(u)) return quantity * (food?.piece ?? 30);
  if (['pinch', 'pinches'].includes(u)) return quantity * 0.4;
  return quantity * (food?.piece ?? 80);
}

function round1(n: number): number {
  return Math.round(n * 10) / 10;
}

function atwater(p: number, c: number, f: number): number {
  return Math.round(4 * p + 4 * c + 9 * f);
}

function clampPerServing(macros: RecipeMacros): RecipeMacros {
  // Keep one plate in a believable home-cooking band.
  const protein = Math.min(80, Math.max(0, macros.protein));
  const carbohydrates = Math.min(180, Math.max(0, macros.carbohydrates));
  const fat = Math.min(90, Math.max(0, macros.fat));
  const sugar = Math.min(Math.max(0, macros.sugar), carbohydrates);
  const fibre = Math.min(40, Math.max(0, macros.fibre));
  let calories = Math.max(0, macros.calories);
  const fromMacros = atwater(protein, carbohydrates, fat);
  if (calories <= 0 || Math.abs(calories - fromMacros) / Math.max(fromMacros, 1) > 0.2) {
    calories = fromMacros;
  }
  calories = Math.min(1200, Math.max(calories > 0 ? calories : 0, fromMacros > 0 ? Math.min(fromMacros, 1200) : 0));
  return {
    calories: Math.round(calories),
    protein: round1(protein),
    carbohydrates: round1(carbohydrates),
    fat: round1(fat),
    sugar: round1(sugar),
    fibre: round1(fibre),
  };
}

function reconcile(fallback: RecipeMacros): RecipeMacros {
  const protein = Math.max(0, fallback.protein);
  const carbohydrates = Math.max(0, fallback.carbohydrates);
  const fat = Math.max(0, fallback.fat);
  const sugar = Math.min(Math.max(0, fallback.sugar), carbohydrates);
  const fibre = Math.max(0, fallback.fibre);
  const expected = atwater(protein, carbohydrates, fat);
  const given = fallback.calories;
  const calories =
    expected === 0
      ? Math.max(0, given)
      : given <= 0 || Math.abs(given - expected) / expected > 0.15
        ? expected
        : given;
  return clampPerServing({
    calories,
    protein,
    carbohydrates,
    fat,
    sugar,
    fibre,
  });
}

export function macrosForRecipe(
  ingredients: Array<{ name: string; quantity: number; unit: string }>,
  servings: number,
  fallback: RecipeMacros,
): RecipeMacros {
  let known = 0;
  let unknown = 0;
  let p = 0;
  let c = 0;
  let f = 0;
  let sugar = 0;
  let fibre = 0;

  for (const ingredient of ingredients) {
    const food = lookup(ingredient.name);
    const grams = toGrams(ingredient.quantity, ingredient.unit, food);
    if (!food) {
      if (grams > 8) unknown += grams;
      continue;
    }
    const scale = grams / 100;
    p += food.p * scale;
    c += food.c * scale;
    f += food.f * scale;
    sugar += food.sugar * scale;
    fibre += fibrePer100g(ingredient.name) * scale;
    if (grams > 5 && (food.kcal > 0 || food.p + food.c + food.f > 0)) {
      known += grams;
    }
  }

  const coverage = known / Math.max(1, known + unknown);
  // Prefer food-table maths whenever we recognise most of the plate.
  if (known >= 20 && coverage >= 0.45) {
    const portions = Math.max(1, servings || 1);
    const protein = p / portions;
    const carbohydrates = c / portions;
    const fat = f / portions;
    const sugarPer = Math.min(sugar / portions, carbohydrates);
    return clampPerServing({
      calories: atwater(protein, carbohydrates, fat),
      protein,
      carbohydrates,
      fat,
      sugar: sugarPer,
      fibre: fibre / portions,
    });
  }

  return reconcile(fallback);
}
