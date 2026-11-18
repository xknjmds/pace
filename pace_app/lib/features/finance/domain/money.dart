/// Pure money helpers. Amounts are whole minor units (cents), never floats.
library;

/// "12", "12.5", "12.50", "1,250.00" to minor units. Null when it is not
/// a positive amount.
int? parseAmount(String input) {
  final s = input.trim().replaceAll(',', '').replaceAll(' ', '');
  final m = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(s);
  if (m == null) return null;
  final whole = int.parse(m[1]!);
  final frac = (m[2] ?? '').padRight(2, '0');
  final minor = whole * 100 + (frac.isEmpty ? 0 : int.parse(frac));
  return minor > 0 ? minor : null;
}

/// "1,250.00" with the currency code after it when one is set.
String formatMoney(int minor, [String currencyCode = '']) {
  final negative = minor < 0;
  final abs = minor.abs();
  final whole = (abs ~/ 100).toString();
  final grouped = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final text =
      '${negative ? '-' : ''}$grouped.${(abs % 100).toString().padLeft(2, '0')}';
  final code = currencyCode.trim().toUpperCase();
  return code.isEmpty ? text : '$text $code';
}
