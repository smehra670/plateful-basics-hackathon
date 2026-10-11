const FALLBACK =
  'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80';

export async function findRecipeImage(query: string): Promise<string> {
  const key = process.env.PEXELS_API_KEY;
  if (!key) return FALLBACK;

  try {
    const url = new URL('https://api.pexels.com/v1/search');
    url.searchParams.set('query', `${query} food dish plated`);
    url.searchParams.set('per_page', '5');
    url.searchParams.set('orientation', 'landscape');

    const res = await fetch(url, {
      headers: { Authorization: key },
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) return FALLBACK;
    const data = (await res.json()) as {
      photos?: Array<{ src?: { large2x?: string; large?: string } }>;
    };
    const photo = data.photos?.[0];
    return photo?.src?.large2x || photo?.src?.large || FALLBACK;
  } catch {
    return FALLBACK;
  }
}
