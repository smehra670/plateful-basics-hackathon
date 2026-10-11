import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import multer from 'multer';

import { demoAnalyse, demoRecipes } from './demo';
import { analyseImageBuffer, generateRecipes } from './openai';
import { findRecipeImage } from './pexels';
import { generateRequestSchema } from './schemas';

const app = express();
const port = Number(process.env.PORT || 3001);
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 8 * 1024 * 1024 },
});

app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.get('/api/health', (_req, res) => {
  const openaiConfigured = Boolean(process.env.OPENAI_API_KEY?.trim());
  res.json({
    ok: true,
    openaiConfigured,
    pexelsConfigured: Boolean(process.env.PEXELS_API_KEY?.trim()),
    demoFallback: !openaiConfigured,
    model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
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

    const result = await analyseImageBuffer(
      req.file.buffer,
      req.file.mimetype || 'image/jpeg',
    );
    res.json(result);
  } catch (e) {
    console.error(e);
    res.status(200).json(demoAnalyse);
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

    const result = await generateRecipes(parsed.data);

    const withImages = await Promise.all(
      result.recipes.map(async (recipe) => {
        if (recipe.imageUrl && recipe.imageUrl.length > 8) return recipe;
        const imageUrl = await findRecipeImage(recipe.name);
        return { ...recipe, imageUrl };
      }),
    );

    res.json({ ...result, recipes: withImages });
  } catch (e) {
    console.error(e);
    const names = Array.isArray(req.body?.ingredients)
      ? req.body.ingredients.map((i: { name?: string }) => i.name || '')
      : [];
    res.status(200).json(demoRecipes(names));
  }
});

app.get('/api/recipe-image', async (req, res) => {
  const q = String(req.query.q || '').trim();
  if (!q) {
    res.status(400).json({ error: 'Query parameter q is required.' });
    return;
  }
  const imageUrl = await findRecipeImage(q);
  res.json({ imageUrl, query: q });
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
    process.env.OPENAI_API_KEY?.trim()
      ? `OpenAI: configured (${process.env.OPENAI_MODEL || 'gpt-4o-mini'})`
      : 'OpenAI: missing — using demo responses',
  );
});
