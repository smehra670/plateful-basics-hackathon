import OpenAI from 'openai';
import {
  analyseResponseSchema,
  generateRecipesResponseSchema,
  type AnalyseResponse,
  type GenerateRecipesResponse,
} from './schemas';
import { demoAnalyse, demoRecipes } from './demo';

const QUESTION_BANK = [
  'Is this spinach or kale?',
  'Approximately how many eggs do you have?',
  'Is this chicken or tofu?',
  'Is this yoghurt or cream?',
  'Are these spring onions or chives?',
];

function getClient(): OpenAI | null {
  const key = process.env.OPENAI_API_KEY?.trim();
  if (!key) return null;
  return new OpenAI({ apiKey: key });
}

function modelName(): string {
  return process.env.OPENAI_MODEL?.trim() || 'gpt-4o-mini';
}

function extractJson(text: string): unknown {
  const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  const raw = fenced ? fenced[1] : text;
  const start = raw.indexOf('{');
  const end = raw.lastIndexOf('}');
  if (start === -1 || end === -1) {
    throw new Error('No JSON object in model output');
  }
  return JSON.parse(raw.slice(start, end + 1));
}

async function withRetry<T>(fn: () => Promise<T>, attempts = 2): Promise<T> {
  let last: unknown;
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (e) {
      last = e;
      await new Promise((r) => setTimeout(r, 400 * (i + 1)));
    }
  }
  throw last;
}

export async function analyseImageBuffer(
  buffer: Buffer,
  mimeType: string,
): Promise<AnalyseResponse> {
  const client = getClient();
  if (!client) return demoAnalyse;

  const prompt = `You are Plateful, a food-waste assistant.
Identify edible ingredients visible in this kitchen photo.
Return ONLY valid JSON matching:
{
  "ingredients": [{"name": string, "quantity": number|null, "unit": string, "confidence": 0-1, "needsClarification": boolean}],
  "questions": [{"id": string, "prompt": string, "options": string[], "allowOther": boolean}]
}
Rules:
- Ask at most 3 clarification questions, and ONLY when uncertainty materially affects recipes.
- Prefer 0 questions when confident.
- Choose question prompts from this bank when possible: ${QUESTION_BANK.join(' | ')}
- Do not judge food safety from appearance.
- Estimate quantity only when reasonably identifiable.`;

  const dataUrl = `data:${mimeType || 'image/jpeg'};base64,${buffer.toString('base64')}`;

  try {
    const result = await withRetry(() =>
      client.chat.completions.create({
        model: modelName(),
        temperature: 0.2,
        max_tokens: 2048,
        response_format: { type: 'json_object' },
        messages: [
          {
            role: 'user',
            content: [
              { type: 'text', text: prompt },
              { type: 'image_url', image_url: { url: dataUrl, detail: 'low' } },
            ],
          },
        ],
      }),
    );

    const text = result.choices[0]?.message?.content ?? '';
    const parsed = analyseResponseSchema.parse(extractJson(text));
    return {
      ...parsed,
      questions: parsed.questions.slice(0, 3),
      isDemo: false,
    };
  } catch (e) {
    console.error('analyseImage fallback to demo', e);
    return demoAnalyse;
  }
}

export async function generateRecipes(input: {
  ingredients: Array<{
    name: string;
    quantity?: number;
    unit?: string;
    expiryDate?: string | null;
  }>;
  answers?: Record<string, string>;
}): Promise<GenerateRecipesResponse> {
  const client = getClient();
  const pantryNames = input.ingredients.map((i) => i.name);
  if (!client) return demoRecipes(pantryNames);

  const prompt = `You are Plateful. Generate exactly 5 distinct recipes using these pantry ingredients.
Prioritise ingredients that expire soon.
Each recipe may require at most TWO missing ingredients not in the pantry. Prefer zero missing.
Return ONLY JSON:
{
  "recipes": [{
    "id": string,
    "name": string,
    "description": string,
    "imageUrl": "",
    "cookingTime": number,
    "difficulty": "Easy"|"Medium"|"Hard",
    "calories": number,
    "protein": number,
    "carbohydrates": number,
    "fat": number,
    "servings": number,
    "ingredients": [{"name": string, "quantity": number, "unit": string, "inPantry": boolean, "estimatedCostGbp": number}],
    "instructions": string[],
    "estimatedAdditionalCost": number
  }]
}
Pantry: ${JSON.stringify(input.ingredients)}
Clarification answers: ${JSON.stringify(input.answers ?? {})}
estimatedAdditionalCost must equal the sum of estimatedCostGbp for missing ingredients only (GBP).
Recipes must be meaningfully different. Nutrition and prices are estimates.`;

  try {
    const result = await withRetry(() =>
      client.chat.completions.create({
        model: modelName(),
        temperature: 0.7,
        max_tokens: 4096,
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: 'You return only valid JSON objects.' },
          { role: 'user', content: prompt },
        ],
      }),
    );

    const text = result.choices[0]?.message?.content ?? '';
    const parsed = generateRecipesResponseSchema.parse(extractJson(text));
    const filtered = parsed.recipes
      .map((r) => {
        const missing = r.ingredients.filter((i) => !i.inPantry);
        const cost = missing.reduce((s, i) => s + (i.estimatedCostGbp || 0), 0);
        return { ...r, estimatedAdditionalCost: cost };
      })
      .filter((r) => r.ingredients.filter((i) => !i.inPantry).length <= 2)
      .slice(0, 5);

    if (filtered.length < 5) {
      const demo = demoRecipes(pantryNames);
      return {
        recipes: [...filtered, ...demo.recipes].slice(0, 5),
        isDemo: false,
      };
    }
    return { recipes: filtered, isDemo: false };
  } catch (e) {
    console.error('generateRecipes fallback to demo', e);
    return demoRecipes(pantryNames);
  }
}
