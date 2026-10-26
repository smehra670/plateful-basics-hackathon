import 'pantry_match.dart';

class FoodFact {
  const FoodFact({
    required this.keys,
    this.pieceGrams,
    this.gbpPerKg,
    this.gbpPerPiece,
    required this.shelfDays,
    required this.storage,
    required this.aisle,
  });

  final List<String> keys;
  final int? pieceGrams;
  final double? gbpPerKg;
  final double? gbpPerPiece;
  final int shelfDays;
  final String storage;
  final String aisle;
}

/// Piece weights follow the server food table in `server/src/nutrition.ts`.
/// Prices are typical UK supermarket shelf prices, used when a scan has no estimate.
abstract final class FoodFacts {
  static const facts = <FoodFact>[
    FoodFact(keys: ['peanut butter'], gbpPerKg: 6.5, shelfDays: 180, storage: 'Cupboard', aisle: 'Cupboard'),
    FoodFact(keys: ['butter bean', 'butter beans'], gbpPerKg: 1.6, shelfDays: 365, storage: 'Cupboard', aisle: 'Cupboard'),
    FoodFact(keys: ['butternut'], pieceGrams: 1000, gbpPerPiece: 1.4, shelfDays: 21, storage: 'Cupboard', aisle: 'Fruit & veg'),
    FoodFact(keys: ['eggplant', 'aubergine'], pieceGrams: 300, gbpPerPiece: 0.9, shelfDays: 5, storage: 'Fridge', aisle: 'Fruit & veg'),
    FoodFact(keys: ['coconut milk', 'oat milk', 'almond milk', 'soy milk'], gbpPerKg: 1.4, shelfDays: 120, storage: 'Cupboard', aisle: 'Cupboard'),
    FoodFact(keys: ['whole milk', 'semi-skimmed', 'skimmed milk', 'milk'], gbpPerKg: 1.2, shelfDays: 5, storage: 'Fridge', aisle: 'Dairy'),
    FoodFact(keys: ['greek yogurt', 'greek yoghurt', 'yogurt', 'yoghurt'], gbpPerKg: 2.4, shelfDays: 10, storage: 'Fridge', aisle: 'Dairy'),
    FoodFact(keys: ['cheddar', 'cheese'], gbpPerKg: 8.5, shelfDays: 21, storage: 'Fridge', aisle: 'Dairy'),
    FoodFact(keys: ['butter'], gbpPerKg: 8.0, shelfDays: 40, storage: 'Fridge', aisle: 'Dairy'),
    FoodFact(keys: ['double cream', 'single cream', 'cream'], gbpPerKg: 3.2, shelfDays: 5, storage: 'Fridge', aisle: 'Dairy'),
    FoodFact(keys: ['egg', 'eggs'], pieceGrams: 50, gbpPerPiece: 0.28, shelfDays: 21, storage: 'Fridge', aisle: 'Dairy'),
    FoodFact(keys: ['chicken breast', 'chicken'], pieceGrams: 170, gbpPerKg: 6.5, shelfDays: 2, storage: 'Fridge', aisle: 'Meat & fish'),
    FoodFact(keys: ['beef', 'mince'], gbpPerKg: 7.5, shelfDays: 2, storage: 'Fridge', aisle: 'Meat & fish'),
    FoodFact(keys: ['bacon'], pieceGrams: 20, gbpPerKg: 8.0, shelfDays: 7, storage: 'Fridge', aisle: 'Meat & fish'),
    FoodFact(keys: ['sausage'], pieceGrams: 60, gbpPerKg: 6.0, shelfDays: 4, storage: 'Fridge', aisle: 'Meat & fish'),
    FoodFact(keys: ['salmon'], pieceGrams: 150, gbpPerKg: 16, shelfDays: 2, storage: 'Fridge', aisle: 'Meat & fish'),
    FoodFact(keys: ['cod', 'haddock', 'fish'], pieceGrams: 150, gbpPerKg: 12, shelfDays: 2, storage: 'Fridge', aisle: 'Meat & fish'),
    FoodFact(keys: ['prawn', 'shrimp'], gbpPerKg: 14, shelfDays: 2, storage: 'Fridge', aisle: 'Meat & fish'),
    FoodFact(keys: ['banana'], pieceGrams: 118, gbpPerPiece: 0.18, shelfDays: 5, storage: 'Counter', aisle: 'Fruit & veg'),
    FoodFact(keys: ['apple'], pieceGrams: 180, gbpPerPiece: 0.35, shelfDays: 14, storage: 'Fridge', aisle: 'Fruit & veg'),
    FoodFact(keys: ['orange'], pieceGrams: 130, gbpPerPiece: 0.4, shelfDays: 10, storage: 'Fridge', aisle: 'Fruit & veg'),
    FoodFact(keys: ['lemon'], pieceGrams: 60, gbpPerPiece: 0.3, shelfDays: 21, storage: 'Fridge', aisle: 'Fruit & veg'),
    FoodFact(keys: ['lime'], pieceGrams: 67, gbpPerPiece: 0.3, shelfDays: 14, storage: 'Fridge', aisle: 'Fruit & veg'),
    FoodFact(keys: ['avocado'], pieceGrams: 150, gbpPerPiece: 0.9, shelfDays: 4, storage: 'Counter', aisle: 'Fruit & veg'),
    FoodFact(keys: ['tomato', 'tomatoes'], pieceGrams: 120, gbpPerKg: 2.8, shelfDays: 5, storage: 'Counter', aisle: 'Fruit & veg'),
    FoodFact(keys: ['spinach'], gbpPerKg: 8.0, shelfDays: 3, storage: 'Fridge', aisle: 'Fruit & veg'),
    FoodFact(keys: ['kale'], gbpPerKg: 7.0, shelfDays: 4, storage: 'Fridge', aisle: 'Fruit & veg'),
    FoodFact(keys: ['lettuce', 'salad'], gbpPerPiece: 0.7, pieceGrams: 200, shelfDays: 4, storage: 'Fridge', aisle: 'Fruit & veg'),
    FoodFact(keys: ['onion'], pieceGrams: 150, gbpPerPiece: 0.2, shelfDays: 30, storage: 'Cupboard', aisle: 'Fruit & veg'),
    FoodFact(keys: ['garlic'], pieceGrams: 3, gbpPerPiece: 0.05, shelfDays: 30, storage: 'Cupboard', aisle: 'Fruit & veg'),
    FoodFact(keys: ['potato'], pieceGrams: 170, gbpPerKg: 1.1, shelfDays: 21, storage: 'Cupboard', aisle: 'Fruit & veg'),
    FoodFact(keys: ['sweet potato'], pieceGrams: 130, gbpPerKg: 1.6, shelfDays: 14, storage: 'Cupboard', aisle: 'Fruit & veg'),
    FoodFact(keys: ['carrot'], pieceGrams: 60, gbpPerKg: 0.9, shelfDays: 14, storage: 'Fridge', aisle: 'Fruit & veg'),
    FoodFact(keys: ['broccoli'], gbpPerKg: 2.2, shelfDays: 5, storage: 'Fridge', aisle: 'Fruit & veg'),
    FoodFact(keys: ['pepper', 'bell pepper'], pieceGrams: 120, gbpPerPiece: 0.5, shelfDays: 7, storage: 'Fridge', aisle: 'Fruit & veg'),
    FoodFact(keys: ['mushroom', 'mushrooms'], gbpPerKg: 4.5, shelfDays: 4, storage: 'Fridge', aisle: 'Fruit & veg'),
    FoodFact(keys: ['cucumber'], pieceGrams: 300, gbpPerPiece: 0.6, shelfDays: 5, storage: 'Fridge', aisle: 'Fruit & veg'),
    FoodFact(keys: ['sourdough', 'bread'], pieceGrams: 30, gbpPerPiece: 0.2, shelfDays: 4, storage: 'Cupboard', aisle: 'Bakery'),
    FoodFact(keys: ['pasta', 'spaghetti', 'penne', 'noodle', 'noodles'], gbpPerKg: 1.8, shelfDays: 365, storage: 'Cupboard', aisle: 'Cupboard'),
    FoodFact(keys: ['rice'], gbpPerKg: 1.6, shelfDays: 365, storage: 'Cupboard', aisle: 'Cupboard'),
    FoodFact(keys: ['oats', 'porridge'], gbpPerKg: 1.5, shelfDays: 180, storage: 'Cupboard', aisle: 'Cupboard'),
    FoodFact(keys: ['flour'], gbpPerKg: 0.7, shelfDays: 180, storage: 'Cupboard', aisle: 'Cupboard'),
    FoodFact(keys: ['chickpea', 'chickpeas', 'lentil', 'lentils', 'beans'], gbpPerKg: 1.5, shelfDays: 365, storage: 'Cupboard', aisle: 'Cupboard'),
    FoodFact(keys: ['tofu'], gbpPerKg: 6.0, shelfDays: 7, storage: 'Fridge', aisle: 'Dairy'),
    FoodFact(keys: ['hummus'], gbpPerKg: 5.0, shelfDays: 5, storage: 'Fridge', aisle: 'Dairy'),
  ];

  static FoodFact? lookup(String name) {
    final n = name.toLowerCase();
    FoodFact? best;
    var bestLen = 0;
    for (final fact in facts) {
      for (final key in fact.keys) {
        if (key.length <= bestLen) continue;
        if (_phrase(n, key)) {
          best = fact;
          bestLen = key.length;
        }
      }
    }
    return best;
  }

  static bool _phrase(String hay, String key) {
    return RegExp('\\b${RegExp.escape(key)}\\b', caseSensitive: false).hasMatch(hay);
  }

  /// Grams in one piece, slice, or clove. Null when this food is not in the table.
  static int? pieceGrams(String name) => lookup(name)?.pieceGrams;

  static int shelfDays(String name) => lookup(name)?.shelfDays ?? 7;

  static String storage(String name) => lookup(name)?.storage ?? 'Fridge';

  static String aisle(String name) => lookup(name)?.aisle ?? 'Cupboard';

  /// Price for one pantry unit (so value = quantity × this).
  static double pricePerUnit(String name, String unit) {
    final fact = lookup(name);
    if (fact == null) return 0.45;
    final u = unit.trim().toLowerCase();
    if (_count(u)) {
      if (fact.gbpPerPiece != null) return fact.gbpPerPiece!;
      if (fact.gbpPerKg != null && fact.pieceGrams != null) {
        return fact.gbpPerKg! * fact.pieceGrams! / 1000;
      }
    }
    if (fact.gbpPerKg != null) {
      final grams = _gramsOfOne(u, fact);
      if (grams != null) return fact.gbpPerKg! * grams / 1000;
    }
    return fact.gbpPerPiece ?? 0.45;
  }

  static double? _gramsOfOne(String unit, FoodFact fact) {
    switch (unit) {
      case 'kg':
        return 1000;
      case 'g':
      case 'gram':
      case 'grams':
        return 1;
      case 'l':
      case 'litre':
      case 'liter':
        return 1000;
      case 'ml':
        return 1;
      default:
        return fact.pieceGrams?.toDouble();
    }
  }

  static bool _count(String unit) {
    return const {
      'pcs',
      'pc',
      'piece',
      'pieces',
      'item',
      'items',
      'slice',
      'slices',
      'clove',
      'cloves',
    }.contains(unit);
  }

  /// Kilograms for an amount, using a real piece weight when the unit is a count.
  static double toKg(double qty, String unit, String name) {
    final u = unit.trim().toLowerCase();
    switch (u) {
      case 'kg':
        return qty;
      case 'g':
      case 'gram':
      case 'grams':
        return qty / 1000;
      case 'l':
      case 'litre':
      case 'liter':
        return qty;
      case 'ml':
        return qty / 1000;
      default:
        final piece = pieceGrams(name);
        if (piece != null && _count(u)) return qty * piece / 1000;
        if (piece != null) return qty * piece / 1000;
        return qty * 0.08;
    }
  }
}

/// Convert between units, using a piece weight so 2 pcs and 100 g can meet.
double convertFoodAmount(
  double quantity,
  String fromUnit,
  String toUnit, {
  required String foodName,
}) {
  final piece = FoodFacts.pieceGrams(foodName);
  if (piece == null) {
    return convertToUnit(quantity, fromUnit, toUnit);
  }
  double toGrams(String unit, double qty) {
    final u = unit.trim().toLowerCase();
    if (const {'kg'}.contains(u)) return qty * 1000;
    if (const {'g', 'gram', 'grams'}.contains(u)) return qty;
    if (FoodFacts._count(u)) return qty * piece;
    return convertToUnit(qty, unit, 'g');
  }

  final from = fromUnit.trim().toLowerCase();
  final to = toUnit.trim().toLowerCase();
  final fromMass = const {'g', 'gram', 'grams', 'kg'}.contains(from) ||
      FoodFacts._count(from);
  final toMass = const {'g', 'gram', 'grams', 'kg'}.contains(to) ||
      FoodFacts._count(to);
  if (fromMass && toMass) {
    final grams = toGrams(from, quantity);
    if (FoodFacts._count(to)) return grams / piece;
    if (to == 'kg') return grams / 1000;
    return grams;
  }
  return convertToUnit(quantity, fromUnit, toUnit);
}
