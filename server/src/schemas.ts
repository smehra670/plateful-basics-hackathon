import { z } from 'zod';

export const detectedIngredientSchema = z.object({
  name: z.string().min(1),
  quantity: z.number().positive().optional().nullable(),
  unit: z.string().default('pcs'),
  confidence: z.number().min(0).max(1).default(0.8),
  needsClarification: z.boolean().optional().default(false),
});

export const clarificationQuestionSchema = z.object({
  id: z.string(),
  prompt: z.string(),
  options: z.array(z.string()).min(1).max(6),
  allowOther: z.boolean().optional().default(true),
});

export const analyseResponseSchema = z.object({
  ingredients: z.array(detectedIngredientSchema).min(1),
  questions: z.array(clarificationQuestionSchema).max(3),
  isDemo: z.boolean().optional(),
});

export const recipeIngredientSchema = z.object({
  name: z.string(),
  quantity: z.number().positive(),
  unit: z.string(),
  inPantry: z.boolean(),
  estimatedCostGbp: z.number().min(0).default(0),
});

export const recipeSchema = z.object({
  id: z.string(),
  name: z.string(),
  description: z.string(),
  imageUrl: z.string().optional().default(''),
  cookingTime: z.number().int().positive(),
  difficulty: z.string(),
  calories: z.number().int().nonnegative(),
  protein: z.number().nonnegative(),
  carbohydrates: z.number().nonnegative(),
  fat: z.number().nonnegative(),
  servings: z.number().int().positive(),
  ingredients: z.array(recipeIngredientSchema),
  instructions: z.array(z.string()).min(1),
  estimatedAdditionalCost: z.number().min(0),
});

export const generateRecipesResponseSchema = z.object({
  recipes: z.array(recipeSchema).min(1).max(5),
  isDemo: z.boolean().optional(),
});

export const generateRequestSchema = z.object({
  ingredients: z.array(
    z.object({
      name: z.string(),
      quantity: z.number().optional(),
      unit: z.string().optional(),
      expiryDate: z.string().nullable().optional(),
    }),
  ),
  answers: z.record(z.string()).optional().default({}),
});

export type AnalyseResponse = z.infer<typeof analyseResponseSchema>;
export type GenerateRecipesResponse = z.infer<typeof generateRecipesResponseSchema>;
