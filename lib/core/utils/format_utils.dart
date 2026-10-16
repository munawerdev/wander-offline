import 'package:intl/intl.dart';

/// Presentation helpers shared by the pack screens.

final DateFormat _dayMonthYear = DateFormat('d MMM yyyy');
final DateFormat _dayMonth = DateFormat('d MMM');
final DateFormat _timeOfDay = DateFormat('HH:mm');

String formatDate(DateTime date) => _dayMonthYear.format(date);
String formatShortDate(DateTime date) => _dayMonth.format(date);
String formatTime(DateTime date) => _timeOfDay.format(date);

/// `just now`, `3 hours ago`, `5 days ago` - used for "rates updated" lines.
String formatRelative(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final difference = reference.difference(date);

  if (difference.isNegative || difference.inMinutes < 1) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays == 1) return 'yesterday';
  if (difference.inDays < 30) return '${difference.inDays} days ago';
  if (difference.inDays < 365) return '${(difference.inDays / 30).floor()}mo ago';
  return formatDate(date);
}

/// Groups thousands: `123300000` becomes `123,300,000`.
String formatThousands(num value) => NumberFormat.decimalPattern().format(value);

/// Money with a symbol prefix, choosing sensible precision.
///
/// Large results (a weak currency against the dollar) read better rounded,
/// while small ones need decimals to avoid showing `0`.
String formatMoney(double amount, String symbol) {
  final absolute = amount.abs();
  final String body;
  if (absolute == 0) {
    body = '0.00';
  } else if (absolute < 0.01) {
    body = amount.toStringAsFixed(4);
  } else if (absolute < 1) {
    body = amount.toStringAsFixed(3);
  } else if (absolute >= 1000) {
    body = NumberFormat.decimalPattern().format(amount.round());
  } else {
    body = amount.toStringAsFixed(2);
  }
  return '$symbol$body';
}

/// `42 MB` / `1.2 GB` for storage readouts.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
