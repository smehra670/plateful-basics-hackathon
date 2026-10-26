import 'dotenv/config';

const payload = {
  ingredients: [
    { name: 'Eggs', quantity: 4, unit: 'pcs' },
    { name: 'Tomatoes', quantity: 2, unit: 'pcs' },
    { name: 'Cheese', quantity: 100, unit: 'g' },
  ],
  answers: {},
};

const started = Date.now();
const res = await fetch('http://127.0.0.1:3001/api/generate-recipes', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(payload),
});
const json = await res.json();
console.log(
  JSON.stringify(
    {
      status: res.status,
      seconds: Number(((Date.now() - started) / 1000).toFixed(1)),
      count: (json.recipes || []).length,
      titles: (json.recipes || []).map((r) => r.name),
      images: (json.recipes || []).map((r) => (r.imageUrl || '').slice(0, 80)),
      error: json.error || null,
    },
    null,
    2,
  ),
);
