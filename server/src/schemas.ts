import { z } from 'zod';

export const detectedIngredientSchema = z.object({
  name: z.string().min(1),
  quantity: z.number().positive().optional().nullable(),
  unit: z.string().default('pcs'),
  confidence: z.number().min(0).max(1).default(0.8),
  needsClarification: z.boolean().optional().default(false),
  shelfLifeDays: z.number().int().positive().nullable().optional(),
  storagePlace: z.string().nullable().optional(),
  estimatedPriceGbp: z.number().min(0).nullable().optional(),
  box: z
    .object({
      x: z.number(),
      y: z.number(),
      w: z.number(),
      h: z.number(),
    })
    .nullable()
    .optional(),
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
  imageSearchQuery: z.string().optional().default(''),
  cookingTime: z.number().int().positive(),
  difficulty: z.string(),
  calories: z.number().int().nonnegative(),
  protein: z.number().nonnegative(),
  carbohydrates: z.number().nonnegative(),
  fat: z.number().nonnegative(),
  sugar: z.number().nonnegative().optional().default(0),
  fibre: z.number().nonnegative().optional().default(0),
  servings: z.number().int().positive(),
  ingredients: z.array(recipeIngredientSchema),
  instructions: z.array(z.string()).min(1),
  estimatedAdditionalCost: z.number().min(0),
  rescueLine: z.string().optional().default(''),
  plating: z.string().optional().default(''),
  wasteTip: z.string().optional().default(''),
});

export const generateRecipesResponseSchema = z.object({
  recipes: z.array(recipeSchema).min(1).max(8),
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
  /** Ingredients the user chose to cook with. Recipes MUST feature these. */
  focusIngredients: z.array(z.string()).optional().default([]),
  mealType: z
    .enum([
      'starter',
      'main',
      'drink',
      'dessert',
      'breakfast',
      'lunch',
      'dinner',
      'snack',
    ])
    .optional(),
  recipeCount: z.number().int().min(1).max(8).optional(),
  preferences: z
    .object({
      allergies: z.array(z.string()).optional().default([]),
      diets: z.array(z.string()).optional().default([]),
      dietType: z.string().optional(),
      avoidIngredients: z.array(z.string()).optional().default([]),
      favouriteCuisines: z.array(z.string()).optional().default([]),
      spiceTolerance: z.string().optional(),
      servings: z.number().int().positive().optional(),
      householdSize: z.number().int().positive().optional(),
      maxCookMinutes: z.number().int().positive().optional(),
      cookingSkill: z.string().optional(),
      mealGoal: z.string().optional(),
      equipment: z.array(z.string()).optional().default([]),
      units: z.string().optional(),
    })
    .optional(),
});

export const mealPlanRequestSchema = z.object({
  durationDays: z.union([z.literal(3), z.literal(5), z.literal(7)]),
  meals: z.array(z.enum(['breakfast', 'lunch', 'dinner', 'snack'])).min(1),
  people: z.number().int().min(1).max(8),
  goals: z.array(z.string()).optional().default([]),
  spiceTolerance: z.string().optional(),
  favouriteCuisines: z.array(z.string()).optional().default([]),
  avoidIngredients: z.array(z.string()).optional().default([]),
  maxCookMinutes: z.number().int().positive().optional(),
  weeklyBudgetGbp: z.number().min(0).optional().nullable(),
  pantryMode: z.enum(['all', 'selected', 'none']),
  pantry: z.array(
    z.object({
      name: z.string(),
      quantity: z.number().optional(),
      unit: z.string().optional(),
      expiryDate: z.string().nullable().optional(),
    }),
  ),
  focusIngredients: z.array(z.string()).optional().default([]),
  startDate: z.string().optional(),
  preferences: generateRequestSchema.shape.preferences,
});

export const plannedMealSchema = z.object({
  slot: z.enum(['breakfast', 'lunch', 'dinner', 'snack']),
  date: z.string(),
  recipe: recipeSchema,
});

export const mealPlanResponseSchema = z.object({
  days: z.array(
    z.object({
      date: z.string(),
      meals: z.array(plannedMealSchema),
    }),
  ),
  shoppingList: z.array(
    z.object({
      name: z.string(),
      quantity: z.number(),
      unit: z.string(),
      unconfirmed: z.boolean().optional(),
    }),
  ),
  pantryUsage: z.array(
    z.object({
      name: z.string(),
      quantity: z.number(),
      unit: z.string(),
    }),
  ),
  allergyWarning: z.string(),
  isDemo: z.boolean().optional(),
});

export type AnalyseResponse = z.infer<typeof analyseResponseSchema>;
export type GenerateRecipesResponse = z.infer<typeof generateRecipesResponseSchema>;
export type MealPlanRequest = z.infer<typeof mealPlanRequestSchema>;
export type MealPlanResponse = z.infer<typeof mealPlanResponseSchema>;
