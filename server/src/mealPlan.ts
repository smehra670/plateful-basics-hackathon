import { allocatePlan, recipeHitsAllergen } from './allocate';
import { macrosForRecipe } from './nutrition';
import {
  getClient,
  modelName,
  completionTokenParams,
  createJsonCompletion,
  withRetry,
  extractJson,
  normalizeName,
  CreditError,
  isOpenAiBillingError,
} from './openai';
import type { MealPlanRequest, MealPlanResponse } from './schemas';
import { mealPlanResponseSchema } from './schemas';

type Slot = 'breakfast' | 'lunch' | 'dinner' | 'snack';

type PlanRecipe = MealPlanResponse['days'][number]['meals'][number]['recipe'];
type PantryItem = MealPlanRequest['pantry'][number];

function datesFor(startIso: string | undefined, days: number): string[] {
  const start = startIso ? new Date(startIso) : new Date();
  start.setHours(12, 0, 0, 0);
  return Array.from({ length: days }, (_, i) => {
    const d = new Date(start);
    d.setDate(start.getDate() + i);
    return d.toISOString().slice(0, 10);
  });
}

function slotsFor(meals: Slot[]): Slot[] {
  const order: Slot[] = ['breakfast', 'lunch', 'dinner', 'snack'];
  return order.filter((s) => meals.includes(s));
}

const SLOT_FORMS: Record<Slot, string[]> = {
  breakfast: ['Scramble', 'Toast', 'Bowl', 'Omelette', 'Porridge'],
  lunch: ['Salad', 'Wrap', 'Bowl', 'Soup', 'Plate'],
  dinner: ['Traybake', 'Stir-fry', 'Pasta', 'Curry', 'Roast plate'],
  snack: ['Dip', 'Toast', 'Cup', 'Bites', 'Yoghurt bowl'],
};

function topPantryNames(pantry: PantryItem[], take = 3): string[] {
  return pantry
    .map((p) => normalizeName(p.name))
    .filter(Boolean)
    .slice(0, take);
}

const DISH_FORMS = [
  'pancake',
  'omelette',
  'porridge',
  'frittata',
  'scramble',
  'curry',
  'pasta',
  'salad',
  'soup',
  'stir-fry',
  'traybake',
  'toast',
  'bowl',
  'wrap',
  'rice',
  'noodle',
  'sandwich',
  'taco',
  'bake',
];

function dishSignature(name: string): string {
  const raw = name
    .toLowerCase()
    .replace(/\d{1,2}-\d{1,2}/g, ' ')
    .replace(/[^a-z\s-]/g, ' ');
  const tokens = raw
    .split(/[\s-]+/)
    .filter((t) => t.length > 2 && !['with', 'and', 'the', 'mild', 'easy', 'fresh'].includes(t));
  const form =
    DISH_FORMS.find((f) => tokens.some((t) => t.startsWith(f.slice(0, 4)))) || 'plate';
  const foods = tokens
    .filter((t) => !DISH_FORMS.some((f) => t.startsWith(f.slice(0, 4))))
    .map((t) => t.replace(/s$/, ''))
    .sort();
  return `${form}:${foods.slice(0, 2).join('+')}`;
}

function pantryFallbackRecipe(
  slot: Slot,
  people: number,
  pantry: PantryItem[],
  focus: string[],
  usedNames: Set<string>,
  usedSignatures: Set<string>,
  date: string,
): PlanRecipe {
  const picks = [
    ...focus.map(normalizeName).filter(Boolean),
    ...topPantryNames(pantry, 8),
  ].filter((name, i, all) => all.findIndex((n) => n.toLowerCase() === name.toLowerCase()) === i);
  const forms = SLOT_FORMS[slot];
  const pool = picks.length ? picks : ['Eggs', 'Tomato', 'Rice', 'Chicken'];
  let name = `${pool[0]} ${forms[0]}`;
  let mains = pool.slice(0, 2);
  for (let n = 0; n < 30; n += 1) {
    const form = forms[n % forms.length];
    const a = pool[n % pool.length];
    const b = pool[(n + 1 + Math.floor(n / pool.length)) % pool.length];
    mains = a === b ? [a] : [a, b];
    name = mains.length === 2 ? `${a} & ${b} ${form}` : `${a} ${form}`;
    const sig = dishSignature(name);
    if (!usedNames.has(name.toLowerCase()) && !usedSignatures.has(sig)) break;
  }
  usedNames.add(name.toLowerCase());
  usedSignatures.add(dishSignature(name));

  const ingredients = (mains.length ? mains : ['Eggs', 'Bread', 'Tomato']).slice(0, 4).map((n, i) => {
    const fromPantry = pantry.find(
      (p) =>
        p.name.toLowerCase().includes(n.toLowerCase()) ||
        n.toLowerCase().includes(p.name.toLowerCase()),
    );
    const qty = fromPantry?.quantity && fromPantry.quantity > 0
      ? Math.min(fromPantry.quantity, i === 0 ? 2 : 1)
      : i === 0
        ? 2
        : 1;
    const unit = (fromPantry?.unit || (n.toLowerCase().includes('egg') ? 'pcs' : 'pcs')).trim();
    return {
      name: n,
      quantity: qty,
      unit,
      inPantry: true,
      estimatedCostGbp: 0,
    };
  });

  const nutrition = macrosForRecipe(ingredients, people, {
    calories: 0,
    protein: 0,
    carbohydrates: 0,
    fat: 0,
    sugar: 0,
    fibre: 0,
  });

  return {
    id: `fallback-${date}-${slot}`,
    name,
    description: `A ${slot} built around ${mains.join(' and ') || 'what you have'}.`,
    imageUrl: '',
    imageSearchQuery: `${name} plated ${slot}`,
    cookingTime: slot === 'snack' ? 10 : 20,
    difficulty: 'Easy',
    calories: nutrition.calories || 320,
    protein: nutrition.protein || 12,
    carbohydrates: nutrition.carbohydrates || 28,
    fat: nutrition.fat || 14,
    sugar: nutrition.sugar || 4,
    fibre: nutrition.fibre || 0,
    servings: people,
    ingredients,
    instructions: [
      `Prep ${mains[0] || 'your ingredients'} and set a pan over medium heat.`,
      'Cook until coloured and smelling ready, then season.',
      'Plate while hot and eat straight away.',
    ],
    estimatedAdditionalCost: 0,
    rescueLine: mains[0]
      ? `Uses your ${mains[0].toLowerCase()} before it sits unused.`
      : 'Uses what you already have.',
    plating: 'Serve with height and a fresh colour on the plate.',
    wasteTip: 'Box leftovers and eat within two days.',
  };
}

function finalizeRecipe(
  recipe: PlanRecipe,
  slot: Slot,
  date: string,
  people: number,
  pantry: PantryItem[],
  allergies: string[],
  usedNames: Set<string>,
  usedSignatures: Set<string>,
  focus: string[],
): PlanRecipe {
  let next = recipe;
  let name = normalizeName(next.name || '');
  const hit = recipeHitsAllergen(
    (next.ingredients || []).map((i) => i.name),
    allergies,
  );
  const generic =
    !name ||
    /^(breakfast|lunch|dinner|snack)\s+(idea|meal|with pantry)/i.test(name) ||
    /^safe\s+/i.test(name);
  const repeated =
    usedNames.has(name.toLowerCase()) || usedSignatures.has(dishSignature(name));
  if (hit || generic || repeated) {
    next = pantryFallbackRecipe(
      slot,
      people,
      pantry,
      focus,
      usedNames,
      usedSignatures,
      date,
    );
    name = next.name;
  } else {
    usedNames.add(name.toLowerCase());
    usedSignatures.add(dishSignature(name));
  }

  const pantryLower = new Set(pantry.map((p) => p.name.trim().toLowerCase()));
  const ingredients = (next.ingredients || []).map((ing) => {
    const n = normalizeName(ing.name);
    const inPantry =
      pantryLower.has(n.toLowerCase()) ||
      [...pantryLower].some(
        (p) => n.toLowerCase().includes(p) || p.includes(n.toLowerCase()),
      );
    return {
      ...ing,
      name: n,
      quantity: ing.quantity > 0 ? ing.quantity : 1,
      unit: (ing.unit || 'pcs').trim() || 'pcs',
      inPantry,
      estimatedCostGbp: Math.max(0, Number(ing.estimatedCostGbp || 0)),
    };
  });

  const nutrition = macrosForRecipe(ingredients, next.servings || people, {
    calories: next.calories || 0,
    protein: next.protein || 0,
    carbohydrates: next.carbohydrates || 0,
    fat: next.fat || 0,
    sugar: next.sugar || 0,
    fibre: next.fibre || 0,
  });

  const steps = (next.instructions || [])
    .map((s) => String(s).replace(/^\s*\d+[\.)]\s*/, '').trim())
    .filter(Boolean)
    .slice(0, 8);

  return {
    ...next,
    id: next.id || `${date}-${slot}`,
    name,
    description: next.description || `A ${slot} using your pantry.`,
    imageUrl: '',
    imageSearchQuery:
      next.imageSearchQuery?.trim() || `${name} plated ${slot}`,
    cookingTime: next.cookingTime || 20,
    difficulty: next.difficulty || 'Easy',
    calories: nutrition.calories,
    protein: nutrition.protein,
    carbohydrates: nutrition.carbohydrates,
    fat: nutrition.fat,
    sugar: nutrition.sugar,
    fibre: nutrition.fibre,
    servings: next.servings || people,
    ingredients,
    instructions: steps.length
      ? steps
      : ['Prep ingredients.', 'Cook until done.', 'Serve.'],
    estimatedAdditionalCost: next.estimatedAdditionalCost || 0,
    rescueLine: String(next.rescueLine || '').trim(),
    plating: String(next.plating || '').trim(),
    wasteTip: String(next.wasteTip || '').trim(),
  };
}

async function askPlanJson(
  client: NonNullable<ReturnType<typeof getClient>>,
  model: string,
  prompt: string,
  maxTokens: number,
): Promise<{ days?: MealPlanResponse['days'] } | null> {
  const result = await withRetry(
    () =>
      createJsonCompletion(client, {
        model,
        ...completionTokenParams(model, maxTokens),
        response_format: { type: 'json_object' },
        messages: [
          {
            role: 'system',
            content:
              'Return only valid JSON for a meal plan. Every recipe name must be a specific dish title (e.g. "Spinach & Feta Omelette"), never "breakfast idea 1". Honour allergies strictly.',
          },
          { role: 'user', content: prompt },
        ],
      }),
    2,
  );
  const text = result.choices[0]?.message?.content?.trim() ?? '';
  if (!text) return null;
  return extractJson(text) as { days?: MealPlanResponse['days'] };
}

function planPrompt(input: {
  dates: string[];
  slots: Slot[];
  people: number;
  pantry: PantryItem[];
  focus: string[];
  goals: string[];
  prefs: Record<string, unknown>;
  allergies: string[];
  avoid?: string[];
}): string {
  const totalMeals = input.dates.length * input.slots.length;
  return `You are Plateful. Create ONE meal plan as JSON only.

Dates: ${JSON.stringify(input.dates)}
Slots each day: ${JSON.stringify(input.slots)}
People/servings: ${input.people}
Pantry stock: ${JSON.stringify(input.pantry)}
Prioritise these ingredients: ${JSON.stringify(input.focus)}
Goals: ${JSON.stringify(input.goals)}
Spice: ${input.prefs.spiceTolerance || 'Medium'}
Cuisines: ${JSON.stringify(input.prefs.favouriteCuisines || [])}
Avoid: ${JSON.stringify(input.prefs.avoidIngredients || [])}
Allergies (HARD exclude): ${JSON.stringify(input.allergies)}
Diet (follow every one): ${
    (Array.isArray(input.prefs.diets) && input.prefs.diets.length
      ? (input.prefs.diets as string[]).join(', ')
      : input.prefs.dietType) || 'Omnivore'
  }
Max cook minutes: ${input.prefs.maxCookMinutes || 30}

Rules:
- Return exactly one meal for EVERY date × slot (${totalMeals} meals).
- EVERY recipe "name" must be a real dish title people would recognise, e.g. "Tomato & Egg Toast", "Chicken Rice Bowl". NEVER use placeholders like "breakfast idea 1", "lunch meal 2", or "dinner with pantry".
- Titles must name the main ingredients.
- EVERY recipe name must be UNIQUE across the plan.
- Do not repeat a dish, a close variation, or the same main pairing. If these are already planned, invent something else: ${JSON.stringify(input.avoid || [])}
- Use a different cooking method for every meal (do not serve pancakes, omelettes, porridge, curry, or pasta more than once).
- Prefer pantry; at most 2 missing ingredients per recipe (staples free).
- 6-8 sensory cook steps.
- rescueLine / plating / wasteTip required.
- imageSearchQuery: 3-6 words for the finished plated dish.
- Ingredient quantities must be realistic. Per-serving macros must match those amounts.

Return ONLY:
{
  "days": [{
    "date": "YYYY-MM-DD",
    "meals": [{
      "slot": "breakfast"|"lunch"|"dinner"|"snack",
      "date": "YYYY-MM-DD",
      "recipe": {
        "id": string,
        "name": string,
        "description": string,
        "imageUrl": "",
        "imageSearchQuery": string,
        "cookingTime": number,
        "difficulty": "Easy"|"Medium"|"Hard",
        "calories": number,
        "protein": number,
        "carbohydrates": number,
        "fat": number,
        "sugar": number,
        "servings": number,
        "ingredients": [{"name": string, "quantity": number, "unit": string, "inPantry": boolean, "estimatedCostGbp": number}],
        "instructions": string[],
        "estimatedAdditionalCost": number,
        "rescueLine": string,
        "plating": string,
        "wasteTip": string
      }
    }]
  }]
}`;
}

export async function generateMealPlan(
  input: MealPlanRequest,
): Promise<MealPlanResponse> {
  const dates = datesFor(input.startDate, input.durationDays);
  const slots = slotsFor(input.meals as Slot[]);
  const pantry = input.pantryMode === 'none' ? [] : input.pantry;
  const focus = input.focusIngredients ?? [];
  const allergies = input.preferences?.allergies ?? [];

  const prefs = {
    ...(input.preferences || {}),
    spiceTolerance: input.spiceTolerance || input.preferences?.spiceTolerance,
    favouriteCuisines:
      input.favouriteCuisines.length > 0
        ? input.favouriteCuisines
        : input.preferences?.favouriteCuisines,
    avoidIngredients: [
      ...(input.avoidIngredients || []),
      ...(input.preferences?.avoidIngredients || []),
    ],
    servings: input.people,
    householdSize: input.people,
    maxCookMinutes: input.maxCookMinutes || input.preferences?.maxCookMinutes,
    mealGoal: input.goals[0] || input.preferences?.mealGoal,
  };

  const client = getClient();
  const usedNames = new Set<string>();
  const usedSignatures = new Set<string>();
  let days: MealPlanResponse['days'] = [];

  const mapParsedDays = (parsed: { days?: MealPlanResponse['days'] } | null) => {
    return dates.map((date) => {
      const rawDay = (parsed?.days || []).find((d) => d.date === date);
      const meals = slots.map((slot) => {
        const rawMeal = (rawDay?.meals || []).find((m) => m.slot === slot);
        const recipe = finalizeRecipe(
          rawMeal?.recipe ||
            pantryFallbackRecipe(
              slot,
              input.people,
              pantry,
              focus,
              usedNames,
              usedSignatures,
              date,
            ),
          slot,
          date,
          input.people,
          pantry,
          allergies,
          usedNames,
          usedSignatures,
          focus,
        );
        return { slot, date, recipe };
      });
      return { date, meals };
    });
  };

  if (!client) {
    days = dates.map((date) => ({
      date,
      meals: slots.map((slot) => ({
        slot,
        date,
        recipe: pantryFallbackRecipe(
          slot,
          input.people,
          pantry,
          focus,
          usedNames,
          usedSignatures,
          date,
        ),
      })),
    }));
  } else {
    const model = modelName();
    try {
      // One day per request. A full week in one reply comes back empty and
      // the app times out. Three days at a time stays under the client limit.
      const dayParts: MealPlanResponse['days'] = [];
      const avoid: string[] = [];
      const wave = 3;
      for (let i = 0; i < dates.length; i += wave) {
        const slice = dates.slice(i, i + wave);
        const parsedDays = await Promise.all(
          slice.map(async (date) => {
            const dayParsed = await askPlanJson(
              client,
              model,
              planPrompt({
                dates: [date],
                slots,
                people: input.people,
                pantry,
                focus,
                goals: input.goals,
                prefs,
                allergies,
                avoid,
              }),
              2200 + slots.length * 500,
            );
            const day = dayParsed?.days?.find((d) => d.date === date) ||
              dayParsed?.days?.[0];
            if (!day?.meals?.length) {
              console.warn(`meal plan day empty ${date}`);
              return {
                date,
                meals: [] as MealPlanResponse['days'][number]['meals'],
              };
            }
            console.log(
              `meal plan day ${date}: ${day.meals.map((m) => m.recipe?.name || m.slot).join(' | ')}`,
            );
            return { ...day, date };
          }),
        );
        dayParts.push(...parsedDays);
        for (const day of parsedDays) {
          for (const meal of day.meals) {
            const title = meal.recipe?.name?.trim();
            if (title) avoid.push(title);
          }
        }
      }
      days = mapParsedDays({ days: dayParts });
    } catch (e) {
      if (e instanceof CreditError || isOpenAiBillingError(e)) {
        throw e instanceof CreditError ? e : new CreditError();
      }
      console.error('compact meal plan failed', e);
      days = dates.map((date) => ({
        date,
        meals: slots.map((slot) => ({
          slot,
          date,
          recipe: pantryFallbackRecipe(
            slot,
            input.people,
            pantry,
            focus,
            usedNames,
            usedSignatures,
            date,
          ),
        })),
      }));
    }
  }

  const allocation = allocatePlan({
    pantry,
    meals: days.flatMap((d) =>
      d.meals.map((m) => ({
        ingredients: m.recipe.ingredients.map((i) => ({
          name: i.name,
          quantity: i.quantity,
          unit: i.unit,
        })),
        servings: m.recipe.servings,
      })),
    ),
  });

  const plan = {
    days,
    shoppingList: allocation.shopping.map((l) => ({
      name: l.name,
      quantity: l.missing || l.needed,
      unit: l.unit,
      unconfirmed: l.unconfirmed,
    })),
    pantryUsage: allocation.pantryUsage.map((l) => ({
      name: l.name,
      quantity: l.fromPantry,
      unit: l.unit,
    })),
    allergyWarning:
      'Always check packaging and possible cross-contamination. Allergies listed in your account were treated as hard exclusions, but labels can change.',
    isDemo: !client,
  };

  return mealPlanResponseSchema.parse(plan);
}
