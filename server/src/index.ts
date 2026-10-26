import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import multer from 'multer';

import { demoAnalyse, demoRecipes } from './demo';
import {
  analyseImageBuffer,
  CreditError,
  generateRecipes,
  isOpenAiBillingError,
  isOpenAiConfigured,
} from './openai';
import {
  attachUniqueRecipeImages,
  findRecipeImage,
  type MealType,
} from './images';
import { generateMealPlan } from './mealPlan';
import { generateRequestSchema, mealPlanRequestSchema } from './schemas';

function sendAiError(res: express.Response, e: unknown, fallback: string) {
  if (e instanceof CreditError || isOpenAiBillingError(e)) {
    const message =
      e instanceof CreditError
        ? e.message
        : new CreditError().message;
    res.status(402).json({ error: message, code: 'insufficient_quota' });
    return;
  }
  res.status(502).json({
    error: fallback,
    detail: e instanceof Error ? e.message : 'unknown',
  });
}

const app = express();
const port = Number(process.env.PORT || 3001);
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 8 * 1024 * 1024 },
});

app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.get('/api/health', (_req, res) => {
  const openaiConfigured = isOpenAiConfigured();
  res.json({
    ok: true,
    openaiConfigured,
    pexelsConfigured: Boolean(process.env.PEXELS_API_KEY?.trim()),
    serpConfigured: Boolean(
      process.env.SERP_API_KEY?.trim() || process.env.SERPAPI_API_KEY?.trim(),
    ),
    demoFallback: !openaiConfigured,
    model: process.env.OPENAI_MODEL || 'gpt-6-luna',
  });
});

app.post('/api/analyse-image', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      res.status(400).json({ error: 'Image file is required (field: image).' });
      return;
    }
    if (req.file.size > 8 * 1024 * 1024) {
      res.status(413).json({ error: 'Image too large. Max 8MB.' });
      return;
    }

    if (!isOpenAiConfigured()) {
      res.json(demoAnalyse);
      return;
    }

    const result = await analyseImageBuffer(
      req.file.buffer,
      req.file.mimetype || 'image/jpeg',
    );
    res.json(result);
  } catch (e) {
    console.error('analyse-image error', e);
    if (!isOpenAiConfigured()) {
      res.status(200).json(demoAnalyse);
      return;
    }
    sendAiError(
      res,
      e,
      'Image analysis failed. Please retake the photo and try again.',
    );
  }
});

app.post('/api/generate-recipes', async (req, res) => {
  try {
    const parsed = generateRequestSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({
        error: 'Invalid request body',
        details: parsed.error.flatten(),
      });
      return;
    }

    if (!isOpenAiConfigured()) {
      const demo = demoRecipes(
        parsed.data.ingredients.map((i) => i.name),
      );
      const withImages = await attachUniqueRecipeImages(
        demo.recipes,
        parsed.data.mealType as never,
      );
      res.json({ ...demo, recipes: withImages });
      return;
    }

    const result = await generateRecipes(parsed.data);
    const recipes = await attachUniqueRecipeImages(
      result.recipes,
      parsed.data.mealType as MealType | undefined,
    );
    res.json({ ...result, recipes, isDemo: false });
  } catch (e) {
    console.error('generate-recipes error', e);
    if (e instanceof CreditError || isOpenAiBillingError(e)) {
      sendAiError(res, e, 'Recipe generation failed.');
      return;
    }
    if (!isOpenAiConfigured()) {
      const names = Array.isArray(req.body?.ingredients)
        ? req.body.ingredients.map((i: { name?: string }) => i.name || '')
        : [];
      const demo = demoRecipes(names);
      const mealType = ['starter', 'main', 'drink', 'dessert'].includes(
        req.body?.mealType,
      )
        ? req.body.mealType
        : undefined;
      const withImages = await attachUniqueRecipeImages(demo.recipes, mealType);
      res.status(200).json({ ...demo, recipes: withImages });
      return;
    }
    sendAiError(res, e, 'Recipe generation failed. Please try again.');
  }
});

app.post('/api/generate-meal-plan', async (req, res) => {
  try {
    const parsed = mealPlanRequestSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({
        error: 'Invalid meal plan request',
        details: parsed.error.flatten(),
      });
      return;
    }
    const plan = await generateMealPlan(parsed.data);
    res.json(plan);
  } catch (e) {
    console.error('generate-meal-plan error', e);
    sendAiError(res, e, 'Meal plan generation failed. Please try again.');
  }
});

app.get('/api/recipe-image', async (req, res) => {
  const q = String(req.query.q || '').trim();
  if (!q) {
    res.status(400).json({ error: 'Query parameter q is required.' });
    return;
  }
  const mealType = String(req.query.mealType || '').trim() || undefined;
  const exclude = String(req.query.exclude || '')
    .split('|')
    .map((url) => url.trim())
    .filter((url) => url.startsWith('http'));
  const imageUrl = await findRecipeImage(q, {
    mealType: mealType as MealType | undefined,
    usedUrls: new Set(exclude),
    skipSerp: false,
    waitMs: 8000,
  });
  res.json({ imageUrl: imageUrl || '', query: q });
});

app.use(
  (
    err: Error,
    _req: express.Request,
    res: express.Response,
    _next: express.NextFunction,
  ) => {
    console.error(err);
    if (err.message?.includes('File too large')) {
      res.status(413).json({ error: 'Image too large. Max 8MB.' });
      return;
    }
    res.status(500).json({ error: 'Unexpected server error.' });
  },
);

app.listen(port, '0.0.0.0', () => {
  console.log(`Plateful API listening on http://0.0.0.0:${port}`);
  console.log(
    isOpenAiConfigured()
      ? `OpenAI: configured (${process.env.OPENAI_MODEL || 'gpt-6-luna'})`
      : 'OpenAI: missing — using demo responses',
  );
});
