export type MealType =
  | 'starter'
  | 'main'
  | 'drink'
  | 'dessert'
  | 'breakfast'
  | 'lunch'
  | 'dinner'
  | 'snack';

const DRINK_WORDS = [
  'drink',
  'smoothie',
  'juice',
  'shake',
  'glass',
  'latte',
  'cocktail',
  'mocktail',
  'milkshake',
];

const JUNK = [
  'logo',
  'clipart',
  'vector',
  'infographic',
  'collage',
  'advertisement',
  'coupon',
  'stock vector',
  'icon pack',
  'illustration',
  'drawing',
  'cartoon',
  'meme',
];

const RAW_WORDS = [
  'raw ingredient',
  'whole fruit',
  'produce aisle',
  'supermarket',
  'grocery store',
  'on the vine',
  'growing',
  'tree',
  'plantation',
  'orchard',
  'packet',
  'packaging',
  'white background',
  'isolated on white',
  'cutout',
  'seed',
  'seeds',
];

const DISH_FORMS = [
  'frittata',
  'omelette',
  'omelet',
  'scramble',
  'scrambled',
  'pancake',
  'pancakes',
  'waffle',
  'waffles',
  'toast',
  'toastie',
  'sandwich',
  'wrap',
  'wraps',
  'burrito',
  'taco',
  'tacos',
  'quesadilla',
  'pizza',
  'burger',
  'pasta',
  'spaghetti',
  'noodles',
  'noodle',
  'ramen',
  'risotto',
  'pilaf',
  'biryani',
  'paella',
  'fried rice',
  'curry',
  'stew',
  'soup',
  'salad',
  'bowl',
  'smoothie',
  'juice',
  'porridge',
  'oatmeal',
  'oats',
  'casserole',
  'traybake',
  'gratin',
  'pie',
  'tart',
  'cake',
  'cookie',
  'cookies',
  'hummus',
  'dip',
  'skewer',
  'skewers',
  'kebab',
  'stir fry',
  'stir-fry',
  'roast',
  'baked',
  'bake',
];

const FOOD_NOUNS = [
  'chicken',
  'salmon',
  'beef',
  'pork',
  'lamb',
  'turkey',
  'cod',
  'tuna',
  'prawn',
  'shrimp',
  'tofu',
  'paneer',
  'egg',
  'eggs',
  'pasta',
  'spaghetti',
  'noodle',
  'ramen',
  'rice',
  'risotto',
  'curry',
  'soup',
  'salad',
  'stew',
  'chili',
  'burger',
  'pizza',
  'taco',
  'pancake',
  'waffle',
  'oat',
  'oatmeal',
  'toast',
  'avocado',
  'banana',
  'berry',
  'strawberry',
  'mango',
  'apple',
  'orange',
  'tomato',
  'spinach',
  'broccoli',
  'potato',
  'aubergine',
  'eggplant',
  'lentil',
  'chickpea',
  'mushroom',
  'yogurt',
  'yoghurt',
  'smoothie',
  'chocolate',
  'cake',
  'cookie',
  'bread',
  'cheese',
  'cheddar',
  'mozzarella',
  'feta',
  'dal',
  'dhal',
  'pepper',
  'carrot',
  'pea',
  'beans',
  'bean',
  'corn',
  'courgette',
  'zucchini',
];

const SAFE_HOSTS = [
  'unsplash.com',
  'images.unsplash.com',
  'pexels.com',
  'images.pexels.com',
  'themealdb.com',
  'bbcgoodfood.com',
  'allrecipes.com',
  'simplyrecipes.com',
  'bonappetit.com',
  'seriouseats.com',
  'minimalistbaker.com',
  'cookieandkate.com',
  'loveandlemons.com',
  'budgetbytes.com',
  'wikipedia.org',
  'wikimedia.org',
  'nyt.com',
  'nytimes.com',
  'imgur.com',
  'cloudinary.com',
  'googleusercontent.com',
];

/** Specific dish photos — only used when search finds nothing. */
const KEYWORD_PHOTOS: Array<{ keys: string[]; url: string }> = [
  { keys: ['pancake', 'waffle'], url: 'https://images.unsplash.com/photo-1528207776546-365bb710ee93?w=800&q=80' },
  { keys: ['toast', 'avocado'], url: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800&q=80' },
  { keys: ['omelette', 'omelet', 'frittata', 'scrambled', 'scramble'], url: 'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=800&q=80' },
  { keys: ['traybake', 'casserole', 'gratin'], url: 'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=800&q=80' },
  { keys: ['pilaf', 'biryani', 'paella', 'fried rice'], url: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=800&q=80' },
  { keys: ['stew'], url: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800&q=80' },
  { keys: ['egg', 'eggs'], url: 'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=800&q=80' },
  { keys: ['smoothie', 'juice', 'shake'], url: 'https://images.unsplash.com/photo-1505252585461-04db1eb84625?w=800&q=80' },
  { keys: ['salad'], url: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80' },
  { keys: ['pasta', 'spaghetti', 'noodle'], url: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800&q=80' },
  { keys: ['rice', 'risotto', 'bowl'], url: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=800&q=80' },
  { keys: ['soup', 'stew'], url: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800&q=80' },
  { keys: ['curry'], url: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=800&q=80' },
  { keys: ['chicken'], url: 'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=800&q=80' },
  { keys: ['salmon', 'fish', 'cod', 'tuna'], url: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80' },
  { keys: ['burger'], url: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80' },
  { keys: ['pizza'], url: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80' },
  { keys: ['taco', 'quesadilla'], url: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800&q=80' },
  { keys: ['sandwich', 'toastie', 'wrap'], url: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=800&q=80' },
  { keys: ['cheese'], url: 'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=800&q=80' },
  { keys: ['banana', 'fruit', 'mango', 'berry', 'strawberry'], url: 'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?w=800&q=80' },
  { keys: ['spinach', 'broccoli', 'vegetable', 'aubergine', 'eggplant'], url: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800&q=80' },
  { keys: ['oatmeal', 'oat', 'porridge'], url: 'https://images.unsplash.com/photo-1517673400267-0251440c45dc?w=800&q=80' },
  { keys: ['dessert', 'cake', 'cookie', 'chocolate'], url: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800&q=80' },
  { keys: ['breakfast'], url: 'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=800&q=80' },
  { keys: ['lunch', 'dinner'], url: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80' },
];

const SLOT_PHOTOS: Record<string, string> = {
  breakfast: 'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=800&q=80',
  lunch: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80',
  dinner: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80',
  snack: 'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?w=800&q=80',
  drink: 'https://images.unsplash.com/photo-1505252585461-04db1eb84625?w=800&q=80',
  dessert: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800&q=80',
  starter: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80',
  main: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80',
};

const imageCache = new Map<string, { url: string; at: number }>();
const CACHE_MS = 1000 * 60 * 45;
let serpChain: Promise<unknown> = Promise.resolve();
let serpCooldownUntil = 0;

function hasWord(hay: string, key: string): boolean {
  const escaped = key.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const word = key.endsWith('s') ? escaped : `${escaped}(?:s|d|ed)?`;
  return new RegExp(`(?:^|[^a-z])${word}(?:$|[^a-z])`, 'i').test(hay);
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function canonImage(url: string): string {
  try {
    const parsed = new URL(url);
    parsed.search = '';
    parsed.hash = '';
    return parsed.toString();
  } catch {
    return url.split('?')[0];
  }
}

function taken(used: Set<string>, url: string): boolean {
  return used.has(url) || used.has(canonImage(url));
}

function remember(used: Set<string>, url: string): void {
  used.add(url);
  used.add(canonImage(url));
}

export function keywordFallback(
  query: string,
  mealType?: MealType,
  used: Set<string> = new Set(),
): string {
  const hay = query.toLowerCase();
  const ranked = [...KEYWORD_PHOTOS].sort(
    (a, b) => Math.max(...b.keys.map((k) => k.length)) - Math.max(...a.keys.map((k) => k.length)),
  );
  for (const row of ranked) {
    if (!row.keys.some((k) => hasWord(hay, k))) continue;
    if (!taken(used, row.url)) return row.url;
  }
  const slot = (mealType && SLOT_PHOTOS[mealType]) || SLOT_PHOTOS.dinner;
  if (!taken(used, slot)) return slot;
  const unused = KEYWORD_PHOTOS.find((row) => !taken(used, row.url));
  return unused?.url || slot;
}

const STOP = new Set([
  'with',
  'and',
  'the',
  'for',
  'from',
  'over',
  'under',
  'dish',
  'food',
  'plated',
  'recipe',
  'homemade',
  'easy',
  'quick',
  'best',
  'simple',
  'fresh',
  'style',
  'roasted',
  'creamy',
  'crispy',
  'healthy',
  'mild',
  'spicy',
  'halal',
  'free',
  'weeknight',
  'italian',
  'indian',
  'mexican',
  'british',
  'chinese',
  'thai',
]);

function tokenize(query: string): string[] {
  return query
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, ' ')
    .split(/[\s-]+/)
    .filter((t) => t.length > 2 && !STOP.has(t));
}

function foodTokens(query: string): string[] {
  const tokens = tokenize(query);
  const foods = tokens.filter((t) => FOOD_NOUNS.includes(t));
  return foods.length ? foods.slice(0, 4) : tokens.slice(0, 3);
}

function dishForm(query: string): string {
  const lower = query.toLowerCase();
  return DISH_FORMS.find((form) => hasWord(lower, form)) ?? '';
}

function scoreMatch(hay: string, tokens: string[], form = ''): number {
  if (!tokens.length && !form) return 0;
  let score = 0;
  for (const t of tokens) {
    if (hasWord(hay, t)) score += 3;
  }
  if (form && hasWord(hay, form)) score += 6;
  if (/plated|served|bowl|plate|skillet|pan|overhead|close.?up|food photography/.test(hay)) {
    score += 2;
  }
  if (RAW_WORDS.some((w) => hay.includes(w))) score -= 8;
  return score;
}

function looksLikeJunk(hay: string): boolean {
  return JUNK.some((w) => hay.includes(w)) || RAW_WORDS.some((w) => hay.includes(w));
}

function pickImageUrl(original?: string, thumbnail?: string): string | null {
  const orig = original?.trim() || '';
  const thumb = thumbnail?.trim() || '';
  if (orig && /^https?:\/\//i.test(orig) && !orig.toLowerCase().includes('.svg')) {
    try {
      const host = new URL(orig).hostname.toLowerCase();
      if (SAFE_HOSTS.some((safe) => host === safe || host.endsWith(`.${safe}`))) {
        return orig;
      }
    } catch {
      // fall through
    }
  }
  if (thumb && /^https?:\/\//i.test(thumb) && !thumb.toLowerCase().includes('.svg')) {
    return thumb;
  }
  if (orig && /^https?:\/\//i.test(orig) && !orig.toLowerCase().includes('.svg')) {
    return orig;
  }
  return null;
}

/** Build short Google-friendly queries from the dish name. */
export function buildSearchQueries(
  dishName: string,
  imageSearchQuery?: string,
  mealType?: MealType,
): string[] {
  const name = dishName.trim();
  const form = dishForm(name);
  const foods = foodTokens(name).filter((t) => t !== form);
  const hero = foods.slice(0, 2).join(' ');
  const plating =
    mealType === 'drink'
      ? 'in a glass'
      : mealType === 'dessert'
        ? 'dessert plated'
        : 'plated food photography';

  const queries: string[] = [];
  const specific = imageSearchQuery?.trim() ?? '';
  if (specific.length > 4) {
    queries.push(
      mealType === 'drink' && !/glass|drink|smoothie|juice|mocktail/i.test(specific)
        ? `${specific} in a glass`
        : specific,
    );
  }

  if (form && hero) queries.push(`${hero} ${form} ${plating}`);
  if (form) queries.push(`${form} ${hero || name.split(/\s+/).slice(0, 2).join(' ')} ${plating}`);
  queries.push(`${name} ${plating}`);
  if (hero) queries.push(`${hero} ${mealType || 'meal'} plated`);

  return [...new Set(queries.map((q) => q.replace(/\s+/g, ' ').trim()).filter((q) => q.length > 3))]
    .slice(0, 3);
}

/** Kept for callers that still pass a single query string. */
export function buildSearchQuery(
  dishName: string,
  imageSearchQuery?: string,
  mealType?: MealType,
): string {
  return buildSearchQueries(dishName, imageSearchQuery, mealType)[0] || dishName;
}

function enqueueSerp<T>(fn: () => Promise<T>): Promise<T> {
  const run = serpChain.then(async () => {
    await sleep(450);
    return fn();
  }, async () => {
    await sleep(450);
    return fn();
  });
  serpChain = run.then(
    () => undefined,
    () => undefined,
  );
  return run;
}

async function searchPexels(
  query: string,
  used: Set<string>,
  tokens: string[],
  form: string,
): Promise<{ url: string; score: number } | null> {
  const key = process.env.PEXELS_API_KEY?.trim();
  if (!key) return null;
  try {
    const url = new URL('https://api.pexels.com/v1/search');
    url.searchParams.set('query', query);
    url.searchParams.set('per_page', '15');
    url.searchParams.set('orientation', 'landscape');
    const res = await fetch(url, {
      headers: { Authorization: key },
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) return null;
    const data = (await res.json()) as {
      photos?: Array<{
        src?: { large2x?: string; large?: string; medium?: string };
        alt?: string;
      }>;
    };
    let best: { url: string; score: number } | null = null;
    for (const photo of data.photos ?? []) {
      const candidate =
        photo.src?.large2x || photo.src?.large || photo.src?.medium;
      if (!candidate || taken(used, candidate)) continue;
      const score = scoreMatch((photo.alt || '').toLowerCase(), tokens, form);
      if (!best || score > best.score) best = { url: candidate, score };
    }
    return best && best.score >= 3 ? best : best;
  } catch {
    return null;
  }
}

async function searchSerpOnce(
  dishName: string,
  query: string,
  used: Set<string>,
  mealType: MealType | undefined,
  tokens: string[],
  form: string,
): Promise<{ url: string; score: number } | null> {
  const key =
    process.env.SERP_API_KEY?.trim() || process.env.SERPAPI_API_KEY?.trim();
  if (!key || Date.now() < serpCooldownUntil) return null;

  return enqueueSerp(async () => {
    try {
      const url = new URL('https://serpapi.com/search.json');
      url.searchParams.set('engine', 'google_images');
      url.searchParams.set('q', query);
      url.searchParams.set('api_key', key);
      url.searchParams.set('ijn', '0');
      url.searchParams.set('safe', 'active');
      url.searchParams.set('hl', 'en');
      url.searchParams.set('tbs', 'isz:m');

      const res = await fetch(url, { signal: AbortSignal.timeout(15000) });
      if (!res.ok) {
        if (res.status === 429) serpCooldownUntil = Date.now() + 90 * 1000;
        console.warn('SerpAPI status', res.status);
        return null;
      }
      const data = (await res.json()) as {
        images_results?: Array<{
          original?: string;
          thumbnail?: string;
          title?: string;
          source?: string;
          link?: string;
        }>;
        error?: string;
      };
      if (data.error) {
        if (/rate|limit|quota/i.test(data.error)) {
          serpCooldownUntil = Date.now() + 90 * 1000;
        }
        console.warn('SerpAPI error', data.error);
        return null;
      }

      const ranked: Array<{ url: string; score: number }> = [];
      for (const img of data.images_results ?? []) {
        const candidate = pickImageUrl(img.original, img.thumbnail);
        if (!candidate || taken(used, candidate)) continue;
        const hay =
          `${img.title || ''} ${img.source || ''} ${img.link || ''}`.toLowerCase();
        if (looksLikeJunk(hay)) continue;
        if (mealType === 'drink') {
          const drinkHit = DRINK_WORDS.some((w) => hay.includes(w));
          const platedHit = /pizza|pasta|steak|burger|curry|omelette/.test(hay);
          if (platedHit && !drinkHit) continue;
        } else if (DRINK_WORDS.some((w) => hay.includes(w)) && form && !DRINK_WORDS.includes(form)) {
          continue;
        }
        const score = scoreMatch(hay, tokens, form);
        if (score < 3) continue;
        ranked.push({ url: candidate, score });
      }
      ranked.sort((a, b) => b.score - a.score);
      return ranked[0] ?? null;
    } catch (e) {
      console.warn('SerpAPI failed', e instanceof Error ? e.message : e);
      return null;
    }
  });
}

async function searchSerp(
  dishName: string,
  queries: string[],
  used: Set<string>,
  mealType?: MealType,
): Promise<{ url: string; score: number; query: string } | null> {
  const tokens = foodTokens(dishName);
  const form = dishForm(dishName);
  let best: { url: string; score: number; query: string } | null = null;
  for (const query of queries) {
    if (Date.now() < serpCooldownUntil) break;
    const hit = await searchSerpOnce(dishName, query, used, mealType, tokens, form);
    if (!hit) continue;
    if (!best || hit.score > best.score) {
      best = { ...hit, query };
    }
    if (hit.score >= 9) break;
  }
  return best;
}

async function searchMealDb(
  query: string,
  used: Set<string>,
  tokens: string[],
  form: string,
): Promise<{ url: string; score: number } | null> {
  const terms = [
    form,
    ...tokens.slice(0, 2),
    ...foodTokens(query).slice(0, 2),
  ].filter((t, i, all) => t && all.indexOf(t) === i);
  let best: { url: string; score: number } | null = null;
  for (const term of terms.slice(0, 3)) {
    try {
      const url = new URL('https://www.themealdb.com/api/json/v1/1/search.php');
      url.searchParams.set('s', term);
      const res = await fetch(url, { signal: AbortSignal.timeout(6000) });
      if (!res.ok) continue;
      const data = (await res.json()) as {
        meals?: Array<{ strMealThumb?: string; strMeal?: string }> | null;
      };
      for (const m of data.meals ?? []) {
        const image = m.strMealThumb?.trim();
        if (!image || taken(used, image)) continue;
        const title = (m.strMeal || '').toLowerCase();
        const score = scoreMatch(title, tokens, form);
        if (!best || score > best.score) best = { url: image, score };
      }
      if (best && best.score >= 6) return best;
    } catch {
      // try next term
    }
  }
  return best;
}

export async function findRecipeImage(
  dishName: string,
  options: {
    usedUrls?: Set<string>;
    index?: number;
    imageSearchQuery?: string;
    mealType?: MealType;
    skipSerp?: boolean;
    waitMs?: number;
  } = {},
): Promise<string> {
  const used = options.usedUrls ?? new Set<string>();
  for (const url of [...used]) remember(used, url);
  const name = dishName.trim() || 'homemade dinner';
  const queries = buildSearchQueries(name, options.imageSearchQuery, options.mealType);
  const primary = queries[0] || name;
  const cacheKey = `${name}|${primary}|${options.mealType || ''}`.toLowerCase();
  const cached = imageCache.get(cacheKey);
  if (cached && Date.now() - cached.at < CACHE_MS && !taken(used, cached.url)) {
    remember(used, cached.url);
    return cached.url;
  }

  const tokens = foodTokens(name);
  const form = dishForm(name);
  const timed = <T>(p: Promise<T | null>, ms: number) =>
    Promise.race([
      p,
      new Promise<null>((resolve) => setTimeout(() => resolve(null), ms)),
    ]);

  const wait = options.waitMs ?? (options.skipSerp ? 1800 : 10000);
  const serpPromise = options.skipSerp
    ? Promise.resolve(null)
    : timed(searchSerp(name, queries, used, options.mealType), wait);
  const pexelsPromise = timed(
    searchPexels(primary, used, tokens, form),
    Math.min(wait, 2800),
  );
  const mealPromise =
    options.mealType === 'drink'
      ? Promise.resolve(null)
      : timed(searchMealDb(name, used, tokens, form), Math.min(wait, 2500));

  const [serp, pexels, meal] = await Promise.all([
    serpPromise,
    pexelsPromise,
    mealPromise,
  ]);

  const ranked = [
    serp && { url: serp.url, score: serp.score, source: `serp:${serp.query}` },
    meal && { ...meal, source: 'mealdb' },
    pexels && { ...pexels, source: 'pexels' },
  ]
    .filter((x): x is { url: string; score: number; source: string } => !!x)
    .sort((a, b) => {
      const aSerp = a.source.startsWith('serp');
      const bSerp = b.source.startsWith('serp');
      if (aSerp && !bSerp && a.score >= 3) return -1;
      if (bSerp && !aSerp && b.score >= 3) return 1;
      return b.score - a.score;
    });

  const winner =
    ranked.find((r) => r.source.startsWith('serp') && r.score >= 3) ||
    ranked.find((r) => r.score >= 5) ||
    ranked[0];
  const chosen =
    winner && winner.score >= 3
      ? winner.url
      : keywordFallback(`${name} ${primary}`, options.mealType, used);

  console.log(
    `image ${winner && winner.score >= 3 ? winner.source : 'fallback'} "${name}" score=${winner?.score ?? 0}`,
  );
  imageCache.set(cacheKey, { url: chosen, at: Date.now() });
  remember(used, chosen);
  return chosen;
}

export async function attachUniqueRecipeImages<
  T extends { name: string; imageUrl?: string; imageSearchQuery?: string },
>(
  recipes: T[],
  mealType?: MealType,
  options: { skipSerp?: boolean } = {},
): Promise<Array<T & { imageUrl: string }>> {
  const used = new Set<string>();
  const out: Array<T & { imageUrl: string }> = new Array(recipes.length);

  for (let i = 0; i < recipes.length; i += 1) {
    const recipe = recipes[i];
    try {
      const existing = recipe.imageUrl?.trim();
      if (existing && existing.startsWith('http') && !taken(used, existing)) {
        remember(used, existing);
        out[i] = { ...recipe, imageUrl: existing };
        continue;
      }
      const query = recipe.imageSearchQuery?.trim() || recipe.name;
      const imageUrl = await findRecipeImage(recipe.name, {
        usedUrls: used,
        index: i,
        imageSearchQuery: query,
        mealType,
        skipSerp: options.skipSerp || Date.now() < serpCooldownUntil,
        waitMs: options.skipSerp ? 1800 : 9000,
      });
      out[i] = { ...recipe, imageUrl };
      if (!options.skipSerp) await sleep(200);
    } catch {
      out[i] = { ...recipe, imageUrl: recipe.imageUrl || '' };
    }
  }
  return out.filter(Boolean);
}
