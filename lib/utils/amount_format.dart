String formatAmount(num value) {
  final abs = value.abs().toDouble();
  final sign = value < 0 ? '-' : '';

  if (abs < 1000) {
    return '$sign${abs.toStringAsFixed(2)}';
  }

  const units = ['K', 'M', 'B', 'T'];
  var scaled = abs;
  var unitIndex = -1;

  while (scaled >= 1000 && unitIndex < units.length - 1) {
    scaled /= 1000;
    unitIndex++;
  }

  final unit = unitIndex >= 0 ? units[unitIndex] : '';
  return '$sign${scaled.toStringAsFixed(2)}$unit';
}
