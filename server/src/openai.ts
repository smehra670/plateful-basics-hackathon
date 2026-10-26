import OpenAI from 'openai';
import {
  analyseResponseSchema,
  generateRecipesResponseSchema,
  type AnalyseResponse,
  type GenerateRecipesResponse,
} from './schemas';
import { demoAnalyse, demoRecipes } from './demo';
import { macrosForRecipe } from './nutrition';

export class CreditError extends Error {
  readonly status = 402;
  constructor() {
    super(
      'OpenAI credits ran out. Add billing credit at platform.openai.com, then try again.',
    );
    this.name = 'CreditError';
  }
}

export function isOpenAiBillingError(error: unknown): boolean {
  const err = error as {
    status?: number;
    code?: string;
    message?: string;
    error?: { code?: string; type?: string; message?: string };
  };
  const blob = [
    err.code,
    err.error?.code,
    err.error?.type,
    err.message,
    err.error?.message,
  ]
    .filter(Boolean)
    .join(' ')
    .toLowerCase();
  return (
    err.code === 'insufficient_quota' ||
    err.error?.code === 'insufficient_quota' ||
    /insufficient_quota|exceeded your current quota|billing hard limit/.test(blob)
  );
}

export function getClient(): OpenAI | null {
  const key = process.env.OPENAI_API_KEY?.trim();
  if (!key) return null;
  return new OpenAI({ apiKey: key });
}

export function modelName(): string {
  return process.env.OPENAI_MODEL?.trim() || 'gpt-6-luna';
}

function usesMaxCompletionTokens(model: string): boolean {
  return /gpt-[56]/i.test(model) || /o\d/i.test(model) || /nano|luna/i.test(model);
}

export function completionTokenParams(model: string, tokens: number) {
  if (usesMaxCompletionTokens(model)) {
    const extra: Record<string, unknown> = {
      max_completion_tokens: tokens,
    };
    // Leave room for visible JSON instead of spending the whole budget on reasoning.
    if (/gpt-[56]/i.test(model) || /luna|nano/i.test(model)) {
      extra.reasoning_effort = 'low';
    }
    return extra;
  }
  return { max_tokens: tokens };
}

function completionText(result: OpenAI.Chat.ChatCompletion): string {
  const choice = result.choices[0];
  const message = choice?.message;
  const content = message?.content;
  if (typeof content === 'string' && content.trim()) return content;
  const refusal = (message as { refusal?: string | null } | undefined)?.refusal;
  if (refusal?.trim()) {
    throw new Error(`Model refused: ${refusal}`);
  }
  const finish = choice?.finish_reason;
  throw new Error(
    `Empty recipe response from model (finish_reason=${finish || 'unknown'})`,
  );
}

export function extractJson(text: string): unknown {
  const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  const raw = fenced ? fenced[1] : text;
  const start = raw.indexOf('{');
  const end = raw.lastIndexOf('}');
  if (start === -1 || end === -1) {
    throw new Error('No JSON object in model output');
  }
  return JSON.parse(raw.slice(start, end + 1));
}

export async function createJsonCompletion(
  client: OpenAI,
  args: OpenAI.Chat.ChatCompletionCreateParamsNonStreaming,
) {
  try {
    return await client.chat.completions.create(args);
  } catch (e) {
    if (isOpenAiBillingError(e)) throw new CreditError();
    const message = e instanceof Error ? e.message : String(e);
    if (/reasoning_effort|Unsupported parameter/i.test(message)) {
      const { reasoning_effort: _ignored, ...rest } = args as OpenAI.Chat.ChatCompletionCreateParamsNonStreaming & {
        reasoning_effort?: unknown;
      };
      return client.chat.completions.create(rest);
    }
    throw e;
  }
}

export async function withRetry<T>(fn: () => Promise<T>, attempts = 3): Promise<T> {
  let last: unknown;
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (e) {
      if (e instanceof CreditError || isOpenAiBillingError(e)) {
        throw e instanceof CreditError ? e : new CreditError();
      }
      last = e;
      await new Promise((r) => setTimeout(r, 400 * (i + 1)));
    }
  }
  throw last;
}

export function normalizeName(name: string): string {
  return name.trim().replace(/\s+/g, ' ');
}

const KEEP_COMBINED =
  /macaroni and cheese|fish and chips|salt and pepper|bangers and mash|peanut butter|sweet and sour/i;

export function explodeCombinedFoods<T extends { name: string }>(items: T[]): T[] {
  const out: T[] = [];
  for (const item of items) {
    const name = item.name.trim();
    if (KEEP_COMBINED.test(name) || !/\s+(and|&)\s+/i.test(name)) {
      out.push(item);
      continue;
    }
    const parts = name
      .split(/\s+(?:and|&)\s+/i)
      .map((part) => normalizeName(part))
      .filter((part) => part.length > 1);
    if (parts.length < 2) {
      out.push(item);
      continue;
    }
    for (const part of parts) {
      out.push({ ...item, name: part, box: null } as T);
    }
  }
  const seen = new Set<string>();
  return out.filter((item) => {
    const key = item.name.toLowerCase();
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

/** Detect a real image MIME from magic bytes; never trust upload headers alone. */
export function detectImageMime(
  buffer: Buffer,
  declaredMime?: string,
): string {
  if (buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) {
    return 'image/jpeg';
  }
  if (
    buffer.length >= 8 &&
    buffer[0] === 0x89 &&
    buffer[1] === 0x50 &&
    buffer[2] === 0x4e &&
    buffer[3] === 0x47
  ) {
    return 'image/png';
  }
  if (
    buffer.length >= 6 &&
    buffer[0] === 0x47 &&
    buffer[1] === 0x49 &&
    buffer[2] === 0x46
  ) {
    return 'image/gif';
  }
  if (
    buffer.length >= 12 &&
    buffer.toString('ascii', 0, 4) === 'RIFF' &&
    buffer.toString('ascii', 8, 12) === 'WEBP'
  ) {
    return 'image/webp';
  }

  const declared = (declaredMime || '').toLowerCase().trim();
  if (declared.startsWith('image/')) {
    return declared.split(';')[0];
  }
  // Flutter compress / gallery picks are almost always JPEG.
  return 'image/jpeg';
}

export function isOpenAiConfigured(): boolean {
  return Boolean(process.env.OPENAI_API_KEY?.trim());
}

export async function analyseImageBuffer(
  buffer: Buffer,
  mimeType: string,
): Promise<AnalyseResponse> {
  const client = getClient();
  if (!client) return demoAnalyse;

  const model = modelName();
  const safeMime = detectImageMime(buffer, mimeType);
  const prompt = `You are Plateful, an expert kitchen vision model.

The photo may contain ONE item or MANY items together. Detect EVERY distinct edible food ingredient that is actually visible.

Return ONLY valid JSON:
{
  "ingredients": [
    {
      "name": string,
      "quantity": number|null,
      "unit": string,
      "confidence": 0-1,
      "needsClarification": boolean,
      "shelfLifeDays": number,
      "storagePlace": "Fridge"|"Freezer"|"Cupboard"|"Counter",
      "estimatedPriceGbp": number,
      "box": {"x": number, "y": number, "w": number, "h": number}
    }
  ],
  "questions": [
    {
      "id": string,
      "prompt": string,
      "options": string[],
      "allowOther": boolean
    }
  ]
}

Accuracy rules:
- Split EVERY distinct food into its own ingredient row. A photo of grapes AND bread MUST be two items: "Grapes" and "Bread" — never "grapes and bread".
- One bunch, loaf, carton, punnet, or packet = one row. Two different foods = two rows, even if they touch.
- List ALL distinct foods you can see (fruit, vegetables, proteins, dairy, grains, jars if contents are identifiable).
- If there are multiple items in one photo, include each of them. Do not stop after the first item.
- Do NOT invent items that are not visible. Do not add generic pantry staples.
- Never default to spinach, kale, eggs, tomatoes, cheese, or bread unless they are clearly in the photo.
- Ignore cookware, utensils, tableware, hands, packaging logos, and non-food objects.
- Use short grocery names: "Banana", "Red bell pepper", "Greek yoghurt". Never combine two foods with "and".
- Every ingredient needs its own "box": fractions of the image from 0 to 1. x and y are the top-left of that food only; w and h are its width and height. A banana on the left and an orange on the right must have two different boxes. Never reuse one box for two foods. Only box the whole photo when a single food fills it.
- Count pieces when you can see them; otherwise quantity=null and unit="pcs".
- shelfLifeDays: typical days this food stays good in a home kitchen (spinach 3, eggs 21, bread 4, milk 5). Not a safety judgement of this photo.
- storagePlace: Fridge, Freezer, Cupboard, or Counter.
- estimatedPriceGbp: typical UK supermarket price for ONE unit of this item (one egg, one banana, or one kilogram when the unit is kg).
- Ask 0 questions unless two lookalike foods would change cooking (max 3).
- Never judge food safety from appearance.`;

  if (!buffer.length) {
    throw new Error('Empty image buffer');
  }

  const dataUrl = `data:${safeMime};base64,${buffer.toString('base64')}`;
  console.log(
    `analyseImage: bytes=${buffer.length} declared=${mimeType || 'none'} using=${safeMime}`,
  );

  try {
    const result = await withRetry(() =>
      createJsonCompletion(client, {
        model,
        ...completionTokenParams(model, 4000),
        response_format: { type: 'json_object' },
        messages: [
          {
            role: 'user',
            content: [
              { type: 'text', text: prompt },
              { type: 'image_url', image_url: { url: dataUrl, detail: 'high' } },
            ],
          },
        ],
      }),
    );

    let text = '';
    try {
      text = completionText(result);
    } catch {
      text = result.choices[0]?.message?.content ?? '';
    }
    if (!text.trim()) {
      throw new Error('Empty vision response from model');
    }
    const parsed = analyseResponseSchema.parse(extractJson(text));
    const ingredients = explodeCombinedFoods(
      parsed.ingredients
        .map((ing) => ({
          ...ing,
          name: normalizeName(ing.name),
          unit: ing.unit?.trim() || 'pcs',
        }))
        .filter((ing) => ing.name.length > 0 && ing.confidence >= 0.4),
    );

    if (ingredients.length === 0) {
      throw new Error('No confident ingredients detected');
    }

    // Drop generic demo-style clarification unless ingredients need it.
    const questions = parsed.questions
      .filter((q) => {
        const p = q.prompt.toLowerCase();
        const isSpinachKale =
          p.includes('spinach') && p.includes('kale');
        if (!isSpinachKale) return true;
        const hasAmbiguousGreens = ingredients.some(
          (i) =>
            i.needsClarification &&
            /spinach|kale|leaf|green|lettuce|chard/i.test(i.name),
        );
        return hasAmbiguousGreens;
      })
      .slice(0, 3);

    return {
      ingredients,
      questions,
      isDemo: false,
    };
  } catch (e) {
    console.error('analyseImage failed', e);
    throw e;
  }
}

function recipeUsesFocus(
  recipe: {
    name: string;
    description?: string;
    ingredients: Array<{ name: string }>;
  },
  focus: string[],
): boolean {
  if (focus.length === 0) return true;
  const hay = [
    recipe.name,
    recipe.description || '',
    ...recipe.ingredients.map((i) => i.name),
  ]
    .join(' ')
    .toLowerCase();
  return focus.some((f) => {
    const token = f.trim().toLowerCase();
    if (!token) return false;
    return (
      hay.includes(token) ||
      recipe.ingredients.some(
        (i) =>
          i.name.toLowerCase().includes(token) ||
          token.includes(i.name.toLowerCase()),
      )
    );
  });
}

export async function generateRecipes(input: {
  ingredients: Array<{
    name: string;
    quantity?: number;
    unit?: string;
    expiryDate?: string | null;
  }>;
  answers?: Record<string, string>;
  focusIngredients?: string[];
  mealType?:
    | 'starter'
    | 'main'
    | 'drink'
    | 'dessert'
    | 'breakfast'
    | 'lunch'
    | 'dinner'
    | 'snack';
  recipeCount?: number;
  preferences?: {
    allergies?: string[];
    diets?: string[];
    dietType?: string;
    avoidIngredients?: string[];
    favouriteCuisines?: string[];
    spiceTolerance?: string;
    servings?: number;
    householdSize?: number;
    maxCookMinutes?: number;
    cookingSkill?: string;
    mealGoal?: string;
    equipment?: string[];
    units?: string;
  };
}): Promise<GenerateRecipesResponse> {
  const client = getClient();
  const pantryNames = input.ingredients.map((i) => i.name);
  if (!client) return demoRecipes(pantryNames);

  if (input.ingredients.length === 0) {
    throw new Error('No pantry ingredients provided');
  }

  const focus = (input.focusIngredients ?? [])
    .map((n) => normalizeName(n))
    .filter(Boolean);
  // If the user just scanned items, make those the recipe centrepiece.
  const workingPantry =
    focus.length > 0
      ? [
          ...input.ingredients.filter((i) =>
            focus.some(
              (f) =>
                i.name.toLowerCase().includes(f.toLowerCase()) ||
                f.toLowerCase().includes(i.name.toLowerCase()),
            ),
          ),
          ...input.ingredients.filter(
            (i) =>
              !focus.some(
                (f) =>
                  i.name.toLowerCase().includes(f.toLowerCase()) ||
                  f.toLowerCase().includes(i.name.toLowerCase()),
              ),
          ),
        ]
      : input.ingredients;

  const model = modelName();
  const wantedCount = Math.min(8, Math.max(1, input.recipeCount ?? 5));
  const courseLabels: Record<string, string> = {
    starter: 'STARTER / APPETISER — small plates only, not a full meal',
    main: 'MAIN COURSE — a complete savoury meal',
    drink: 'DRINK — smoothie, juice, shake, infusion, or cocktail-style drink. No baked meals.',
    dessert: 'DESSERT — sweet course only (pudding, ice cream, baked sweet, fruit dessert)',
    breakfast: 'BREAKFAST — morning meal',
    lunch: 'LUNCH — midday meal',
    dinner: 'DINNER — evening main meal',
    snack: 'SNACK — small bite, not a full meal',
  };
  const mealType = input.mealType;
  const courseRule = mealType
    ? `
COURSE (mandatory): ${courseLabels[mealType] || mealType}
- ALL ${wantedCount} recipes MUST be this course. Do not mix in other courses.
- imageSearchQuery must match the course. Drinks: "banana smoothie in a glass". Never use dinner/pasta/plated meal photos for drinks.
`
    : '';
  const focusRule =
    focus.length > 0
      ? `
CRITICAL FOCUS INGREDIENTS (the user selected these to cook with): ${JSON.stringify(focus)}
- These items are the MAIN ingredients. EVERY recipe must use ALL of them when realistic, otherwise as many as possible.
- Recipe titles should name these chosen ingredients.
- Do NOT ignore them in favour of unrelated pantry staples.
`
      : '';
  const prefs = input.preferences ?? {};
  const dietRule = `
ACCOUNT CONSTRAINTS (mandatory — violating these makes a recipe unusable):
- Allergies: ${JSON.stringify(prefs.allergies ?? [])}. NEVER include these or derivatives (e.g. dairy allergy → no milk, butter, cheese, yoghurt, cream).
- Diet (all of these apply together): ${(prefs.diets && prefs.diets.length ? prefs.diets.join(', ') : prefs.dietType) || 'Omnivore'}. Vegetarian: no meat/gelatine. Vegan: no animal products. Pescatarian: fish/seafood ok, no meat. Halal and Kosher can combine with one of those. Respect every listed diet.
- Never use: ${JSON.stringify(prefs.avoidIngredients ?? [])}.
- Prefer cuisines: ${JSON.stringify(prefs.favouriteCuisines ?? [])} if possible without breaking pantry/focus rules.
- Spice: ${prefs.spiceTolerance || 'Medium'}.
- Servings: ${prefs.servings || 2} (household of ${prefs.householdSize || 2}).
- Cooking time: at most ${prefs.maxCookMinutes || 45} minutes.
- Skill: ${prefs.cookingSkill || 'Beginner'} — keep techniques matching this.
- Goal: ${prefs.mealGoal || 'Balanced'}.
- Equipment available: ${JSON.stringify(prefs.equipment ?? [])}. Do not require appliances they do not have.
- Units: ${prefs.units || 'metric'} (g/ml vs oz/cups).
`;

  const prompt = `You are Plateful, a professional cookbook author and chef.
Write detailed, beautiful, cookable recipes — not vague summaries.

Generate exactly ${wantedCount} DISTINCT ${mealType || 'home'} recipes — never fewer than ${wantedCount}.
Prioritise scanned focus ingredients, then items that expire soon.
Each recipe may require at most TWO missing ingredients not in the pantry. Prefer zero missing.
Common staples (salt, pepper, oil, water) may be assumed without counting as "missing".

Return ONLY JSON:
{
  "recipes": [{
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
  }]
}

Pantry (focus items listed first): ${JSON.stringify(workingPantry)}
Clarification answers: ${JSON.stringify(input.answers ?? {})}
${courseRule}
${focusRule}
${dietRule}
Quality rules:
- Recipes must be meaningfully different techniques, still all the same course.
- name: appetising Title Case, 2-7 words, naming the main scanned ingredient.
- description: 2 magazine-style sentences — flavour, texture, and the feeling of eating it. Not a shopping-list summary.
- rescueLine: one sentence on which soon-to-expire pantry item this dinner saves, and why tonight.
- plating: 1-2 sentences on how to plate (height, garnish, contrast, bowl vs plate).
- wasteTip: one clever leftover or second-use idea so nothing goes in the bin.
- ingredients: complete mise en place. Realistic quantities (g, ml, pcs, tbsp, tsp). Include every item used in the method.
- Mark inPantry=true only for pantry matches.
- instructions: 6-8 sensory steps (plain strings, no numbering). Include heat level, timing, sight/smell cues ("until edges caramelise", "when it smells nutty"). Cover prep, cook, rest, and serve.
- Never write "cook until done". Be specific and chef-like.
- imageSearchQuery: short Google Images query for the finished plated dish only — 3 to 6 words. Prefer "main ingredient + dish form + plated", e.g. "spinach frittata plated", "mango chicken rice bowl", "banana oat smoothie in a glass". Never search raw produce, logos, packaging, or generic "healthy meal". Unique per recipe.
- cookingTime: realistic minutes, never over the max cook time. servings: match account servings.
- Quantities are for the whole recipe. Use real weights (egg 50g, chicken breast 170g, banana 120g, dry pasta and rice listed dry). Nutrition is checked against those amounts per serving: calories must agree with protein, carbs, and fat.
- estimatedAdditionalCost: sum of estimatedCostGbp for missing ingredients only (GBP).`;

  try {
    const run = async (tokens: number, jsonMode: boolean) =>
      createJsonCompletion(client, {
        model,
        ...completionTokenParams(model, tokens),
        ...(jsonMode ? { response_format: { type: 'json_object' as const } } : {}),
        messages: [
          {
            role: 'system',
            content:
              'You return only valid JSON objects. Write detailed cookbook recipes. Honour course, selected ingredients, allergies, and diet with zero exceptions.',
          },
          { role: 'user', content: prompt },
        ],
      });

    let result = await withRetry(
      () => run(wantedCount <= 3 ? 4500 : 7000, true),
      1,
    );
    let text = result.choices[0]?.message?.content?.trim() ?? '';
    if (!text) {
      console.warn(
        'generateRecipes empty first pass',
        result.choices[0]?.finish_reason,
      );
      result = await withRetry(() => run(24000, true));
      text = result.choices[0]?.message?.content?.trim() ?? '';
    }
    if (!text) {
      result = await withRetry(() => run(24000, false));
      text = result.choices[0]?.message?.content?.trim() ?? '';
    }
    if (!text) {
      throw new Error(
        `Empty recipe response from model (finish_reason=${result.choices[0]?.finish_reason || 'unknown'})`,
      );
    }
    const parsed = generateRecipesResponseSchema.parse(extractJson(text));
    const pantryLower = new Set(
      input.ingredients.map((i) => i.name.trim().toLowerCase()),
    );

    const normalized = parsed.recipes.map((r, index) => {
      const ingredients = r.ingredients
        .map((ing) => {
          const name = normalizeName(ing.name);
          const inPantry =
            pantryLower.has(name.toLowerCase()) ||
            [...pantryLower].some(
              (p) =>
                name.toLowerCase().includes(p) ||
                p.includes(name.toLowerCase()),
            );
          const quantity =
            typeof ing.quantity === 'number' && ing.quantity > 0
              ? ing.quantity
              : 1;
          const unit = (ing.unit || 'pcs').trim() || 'pcs';
          return {
            ...ing,
            name,
            quantity,
            unit,
            inPantry,
            estimatedCostGbp: Math.max(
              0.05,
              Number((ing.estimatedCostGbp || (inPantry ? 0.2 : 0.6)).toFixed(2)),
            ),
          };
        })
        .filter((ing) => ing.name.length > 0);

      const instructions = (r.instructions || [])
        .map((step) =>
          String(step)
            .replace(/^\s*\d+[\.)]\s*/, '')
            .trim(),
        )
        .filter((step) => step.length > 0)
        .slice(0, 10);

      const missing = ingredients.filter((i) => !i.inPantry);
      // Staples shouldn't block a recipe or inflate cost.
      const staple = /^(salt|pepper|black pepper|oil|olive oil|vegetable oil|water|butter)$/i;
      const realMissing = missing.filter((i) => !staple.test(i.name));
      const cost = realMissing.reduce((s, i) => s + (i.estimatedCostGbp || 0), 0);
      const title = normalizeName(r.name);
      const nutrition = macrosForRecipe(
        ingredients,
        r.servings || 1,
        {
          calories: r.calories || 0,
          protein: r.protein || 0,
          carbohydrates: r.carbohydrates || 0,
          fat: r.fat || 0,
          sugar: r.sugar || 0,
          fibre: r.fibre || 0,
        },
      );
      const courseHint =
        mealType === 'drink'
          ? 'drink in a glass'
          : mealType === 'dessert'
            ? 'dessert plate'
            : mealType === 'starter'
              ? 'starter appetizer plate'
              : 'plated main course';
      const imageSearchQuery =
        r.imageSearchQuery?.trim() || `${title} ${courseHint}`;

      return {
        ...r,
        id: r.id || `recipe-${Date.now()}-${index}`,
        name: title,
        description: (r.description || '').trim(),
        imageSearchQuery,
        calories: nutrition.calories,
        protein: nutrition.protein,
        carbohydrates: nutrition.carbohydrates,
        fat: nutrition.fat,
        sugar: nutrition.sugar,
        fibre: nutrition.fibre,
        ingredients,
        instructions:
          instructions.length >= 4
            ? instructions
            : [
                ...instructions,
                'Taste and adjust seasoning.',
                'Serve immediately while warm.',
              ].slice(0, 8),
        estimatedAdditionalCost: Number(cost.toFixed(2)),
        rescueLine: String(r.rescueLine || '').trim(),
        plating: String(r.plating || '').trim(),
        wasteTip: String(r.wasteTip || '').trim(),
        _realMissingCount: realMissing.length,
      } as typeof r & { _realMissingCount: number };
    });

    const focused = normalized.filter((r) => recipeUsesFocus(r, focus));
    const usable = (focused.length >= wantedCount ? focused : normalized).filter(
      (r) => (r._realMissingCount ?? 99) <= 4,
    );
    const padded = [...usable];
    while (padded.length < wantedCount && normalized.length > 0) {
      padded.push(normalized[padded.length % normalized.length]);
    }

    const recipes = padded.slice(0, wantedCount).map(
      ({ _realMissingCount, ...r }) => r,
    );

    if (recipes.length === 0) {
      throw new Error('Model returned no usable recipes for this pantry');
    }

    if (focus.length > 0) {
      const usedFocus = recipes.filter((r) => recipeUsesFocus(r, focus)).length;
      console.log(
        `generateRecipes: focus=${focus.join(', ')} recipes=${recipes.length} usingFocus=${usedFocus}`,
      );
    }

    return { recipes, isDemo: false };
  } catch (e) {
    console.error('generateRecipes failed', e);
    throw e;
  }
}
