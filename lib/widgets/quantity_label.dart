/// Formats a quantity for pantry chips: whole numbers, or ½ / ¼ / ¾.
String formatQuantity(double value) {
  if (value.isNaN || value.isInfinite) return '0';
  final negative = value < 0;
  final v = value.abs();
  final whole = v.truncate();
  final frac = v - whole;
  String? glyph;
  if ((frac - 0.5).abs() < 0.06) {
    glyph = '½';
  } else if ((frac - 0.25).abs() < 0.06) {
    glyph = '¼';
  } else if ((frac - 0.75).abs() < 0.06) {
    glyph = '¾';
  }
  String text;
  if (glyph != null) {
    text = whole == 0 ? glyph : '$whole$glyph';
  } else if ((v - v.roundToDouble()).abs() < 0.001) {
    text = '${v.round()}';
  } else {
    text = v.toStringAsFixed(1);
  }
  return negative ? '-$text' : text;
}

/// "Eggs 10", "Spinach 52 g", "Mango 2½".
String pantryChipLabel(String name, double quantity, String unit) {
  final qty = formatQuantity(quantity);
  final u = unit.trim();
  const hidden = {'pcs', 'pc', 'piece', 'pieces', 'count', 'x'};
  if (u.isEmpty || hidden.contains(u.toLowerCase())) {
    return '$name $qty';
  }
  return '$name $qty $u';
}
