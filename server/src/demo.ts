import type { AnalyseResponse, GenerateRecipesResponse } from './schemas';

export const demoAnalyse: AnalyseResponse = {
  ingredients: [
    { name: 'Eggs', quantity: 6, unit: 'pcs', confidence: 0.95, needsClarification: false },
    { name: 'Tomatoes', quantity: 3, unit: 'pcs', confidence: 0.9, needsClarification: false },
    { name: 'Spinach', quantity: 150, unit: 'g', confidence: 0.85, needsClarification: false },
    { name: 'Cheese', quantity: 100, unit: 'g', confidence: 0.88, needsClarification: false },
    { name: 'Bread', quantity: 4, unit: 'slices', confidence: 0.92, needsClarification: false },
  ],
  questions: [],
  isDemo: true,
};

export function demoRecipes(pantryNames: string[]): GenerateRecipesResponse {
  const names = new Set(pantryNames.map((n) => n.toLowerCase()));
  const has = (n: string) => names.has(n.toLowerCase());

  const recipes = [
    {
      id: 'srv-demo-1',
      name: 'Spinach & Cheese Omelette',
      description: 'A fluffy omelette folded around wilted spinach and melted cheese.',
      imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800&q=80',
      cookingTime: 15,
      difficulty: 'Easy',
      calories: 320,
      protein: 22,
      carbohydrates: 4,
      fat: 24,
      servings: 1,
      estimatedAdditionalCost: 0,
      ingredients: [
        { name: 'Eggs', quantity: 2, unit: 'pcs', inPantry: has('Eggs'), estimatedCostGbp: 0 },
        { name: 'Spinach', quantity: 50, unit: 'g', inPantry: has('Spinach') || has('Kale'), estimatedCostGbp: 0 },
        { name: 'Cheese', quantity: 30, unit: 'g', inPantry: has('Cheese'), estimatedCostGbp: 0 },
      ],
      instructions: [
        'Whisk the eggs with a pinch of salt.',
        'Wilt the greens, then set aside.',
        'Cook the omelette, add greens and cheese, fold and finish.',
      ],
    },
    {
      id: 'srv-demo-2',
      name: 'Tomato & Egg Toast',
      description: 'Crispy toast topped with soft eggs and juicy tomatoes.',
      imageUrl: 'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=800&q=80',
      cookingTime: 12,
      difficulty: 'Easy',
      calories: 280,
      protein: 14,
      carbohydrates: 28,
      fat: 12,
      servings: 1,
      estimatedAdditionalCost: 0,
      ingredients: [
        { name: 'Bread', quantity: 2, unit: 'slices', inPantry: has('Bread'), estimatedCostGbp: 0 },
        { name: 'Eggs', quantity: 1, unit: 'pcs', inPantry: has('Eggs'), estimatedCostGbp: 0 },
        { name: 'Tomatoes', quantity: 1, unit: 'pcs', inPantry: has('Tomatoes'), estimatedCostGbp: 0 },
      ],
      instructions: [
        'Toast the bread until golden.',
        'Cook the egg to your liking.',
        'Top toast with tomato slices and the egg.',
      ],
    },
    {
      id: 'srv-demo-3',
      name: 'Creamy Spinach Pasta',
      description: 'Comforting pasta with a light spinach and cheese sauce.',
      imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800&q=80',
      cookingTime: 25,
      difficulty: 'Easy',
      calories: 450,
      protein: 16,
      carbohydrates: 58,
      fat: 16,
      servings: 2,
      estimatedAdditionalCost: has('Pasta') ? 0 : 1.2,
      ingredients: [
        { name: 'Spinach', quantity: 80, unit: 'g', inPantry: has('Spinach') || has('Kale'), estimatedCostGbp: 0 },
        { name: 'Cheese', quantity: 40, unit: 'g', inPantry: has('Cheese'), estimatedCostGbp: 0 },
        { name: 'Pasta', quantity: 180, unit: 'g', inPantry: has('Pasta'), estimatedCostGbp: has('Pasta') ? 0 : 1.2 },
      ],
      instructions: [
        'Boil pasta until al dente.',
        'Sauté spinach until wilted.',
        'Stir in cheese with pasta water and toss.',
      ],
    },
    {
      id: 'srv-demo-4',
      name: 'Shakshuka',
      description: 'Eggs gently poached in a spiced tomato pan sauce.',
      imageUrl: 'https://images.unsplash.com/photo-1590412200988-a436970781fa?w=800&q=80',
      cookingTime: 30,
      difficulty: 'Medium',
      calories: 310,
      protein: 18,
      carbohydrates: 14,
      fat: 20,
      servings: 2,
      estimatedAdditionalCost: 0.8,
      ingredients: [
        { name: 'Tomatoes', quantity: 3, unit: 'pcs', inPantry: has('Tomatoes'), estimatedCostGbp: 0 },
        { name: 'Eggs', quantity: 3, unit: 'pcs', inPantry: has('Eggs'), estimatedCostGbp: 0 },
        { name: 'Cumin', quantity: 1, unit: 'tsp', inPantry: false, estimatedCostGbp: 0.8 },
      ],
      instructions: [
        'Simmer chopped tomatoes into a thick sauce.',
        'Season with cumin and salt.',
        'Crack in eggs and cover until whites set.',
      ],
    },
    {
      id: 'srv-demo-5',
      name: 'Cheesy Vegetable Breakfast Bake',
      description: 'A one-dish bake of eggs, greens, tomatoes, and cheese.',
      imageUrl: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80',
      cookingTime: 35,
      difficulty: 'Easy',
      calories: 380,
      protein: 24,
      carbohydrates: 12,
      fat: 26,
      servings: 2,
      estimatedAdditionalCost: 0,
      ingredients: [
        { name: 'Eggs', quantity: 3, unit: 'pcs', inPantry: has('Eggs'), estimatedCostGbp: 0 },
        { name: 'Spinach', quantity: 60, unit: 'g', inPantry: has('Spinach') || has('Kale'), estimatedCostGbp: 0 },
        { name: 'Tomatoes', quantity: 2, unit: 'pcs', inPantry: has('Tomatoes'), estimatedCostGbp: 0 },
        { name: 'Cheese', quantity: 40, unit: 'g', inPantry: has('Cheese'), estimatedCostGbp: 0 },
      ],
      instructions: [
        'Preheat oven to 180°C.',
        'Layer greens and tomatoes in a dish.',
        'Pour whisked eggs over, top with cheese, bake until set.',
      ],
    },
  ].map((r) => {
    const missing = r.ingredients.filter((i) => !i.inPantry);
    const cost = missing.reduce((s, i) => s + i.estimatedCostGbp, 0);
    return {
      ...r,
      sugar: 8,
      fibre: 0,
      imageSearchQuery: `${r.name} plated food dish`,
      estimatedAdditionalCost: cost,
      rescueLine: 'Cooks what is already in the kitchen.',
      plating: 'Serve straight away.',
      wasteTip: 'Box leftovers for lunch tomorrow.',
    };
  }).filter((r) => r.ingredients.filter((i) => !i.inPantry).length <= 2);

  return { recipes: recipes.slice(0, 5), isDemo: true };
}
