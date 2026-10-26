String pantryNorm(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ');

String pantrySingular(String value) {
  final n = pantryNorm(value);
  if (n.endsWith('ies') && n.length > 4) return '${n.substring(0, n.length - 3)}y';
  if (n.endsWith('oes') && n.length > 4) return n.substring(0, n.length - 2);
  if (n.endsWith('ses') && n.length > 4) return n.substring(0, n.length - 2);
  if (n.endsWith('s') && !n.endsWith('ss') && n.length > 3) {
    return n.substring(0, n.length - 1);
  }
  return n;
}

bool pantryNamesMatch(String a, String b) {
  final na = pantrySingular(a);
  final nb = pantrySingular(b);
  if (na.isEmpty || nb.isEmpty) return false;
  if (na == nb) return true;
  if (na.length < 3 || nb.length < 3) return false;
  return na.contains(nb) || nb.contains(na);
}

double convertToUnit(double quantity, String fromUnit, String toUnit) {
  final from = fromUnit.trim().toLowerCase();
  final to = toUnit.trim().toLowerCase();
  if (from == to) return quantity;

  double toBase(String unit, double qty) {
    switch (unit) {
      case 'kg':
        return qty * 1000;
      case 'g':
      case 'gram':
      case 'grams':
        return qty;
      case 'l':
      case 'litre':
      case 'liter':
      case 'litres':
      case 'liters':
        return qty * 1000;
      case 'ml':
        return qty;
      case 'tbsp':
      case 'tablespoon':
      case 'tablespoons':
        return qty * 15;
      case 'tsp':
      case 'teaspoon':
      case 'teaspoons':
        return qty * 5;
      case 'cup':
      case 'cups':
        return qty * 240;
      default:
        return qty;
    }
  }

  const mass = {'g', 'gram', 'grams', 'kg'};
  const vol = {
    'ml',
    'l',
    'litre',
    'liter',
    'litres',
    'liters',
    'tbsp',
    'tablespoon',
    'tablespoons',
    'tsp',
    'teaspoon',
    'teaspoons',
    'cup',
    'cups',
  };

  if (mass.contains(from) && mass.contains(to)) {
    return toBase(from, quantity) / toBase(to, 1);
  }
  if (vol.contains(from) && vol.contains(to)) {
    return toBase(from, quantity) / toBase(to, 1);
  }
  return quantity;
}
