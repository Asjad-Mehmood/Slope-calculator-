// Numbers as the reports show them. Values are rounded before the sign is chosen, so a tiny
// negative never shows as "−0.000".

/// 2.5 → `2.500`; -0.0001 → `0.000`, never `-0.000`.
String fixed(double value, int decimals) {
  final text = value.toStringAsFixed(decimals);
  return double.parse(text) == 0 ? (0.0).toStringAsFixed(decimals) : text;
}

/// With a sign: -3.75 → `−3.750` (a real minus sign), 0.3 → `+0.300`, 0 → `0.000`.
String signed(double value, int decimals) {
  final text = fixed(value.abs(), decimals);
  if (double.parse(text) == 0) return text;
  return '${value < 0 ? '−' : '+'}$text';
}
