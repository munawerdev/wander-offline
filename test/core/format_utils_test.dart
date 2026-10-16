import 'package:flutter_test/flutter_test.dart';
import 'package:wander_offline/core/utils/format_utils.dart';

void main() {
  group('formatMoney', () {
    test('uses the symbol and two decimals for ordinary amounts', () {
      expect(formatMoney(12.5, r'$'), r'$12.50');
      expect(formatMoney(158.02, '¥'), '¥158.02');
    });

    test('keeps extra precision for tiny amounts instead of showing zero', () {
      expect(formatMoney(0.0067, r'$'), r'$0.0067');
      expect(formatMoney(0.5, r'$'), r'$0.500');
    });

    test('groups thousands and drops decimals for large amounts', () {
      expect(formatMoney(18031, '฿'), '฿18,031');
    });

    test('renders a true zero', () {
      expect(formatMoney(0, r'$'), r'$0.00');
    });
  });

  group('formatBytes', () {
    test('scales through the units', () {
      expect(formatBytes(512), '512 B');
      expect(formatBytes(2048), '2.0 KB');
      expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
      expect(formatBytes(3 * 1024 * 1024 * 1024), '3.00 GB');
    });
  });

  group('formatRelative', () {
    final now = DateTime(2026, 10, 16, 12);

    test('describes the recent past', () {
      expect(
        formatRelative(now.subtract(const Duration(seconds: 30)), now: now),
        'just now',
      );
      expect(
        formatRelative(now.subtract(const Duration(minutes: 5)), now: now),
        '5m ago',
      );
      expect(
        formatRelative(now.subtract(const Duration(hours: 3)), now: now),
        '3h ago',
      );
      expect(
        formatRelative(now.subtract(const Duration(days: 1)), now: now),
        'yesterday',
      );
      expect(
        formatRelative(now.subtract(const Duration(days: 5)), now: now),
        '5 days ago',
      );
    });

    test('treats a future timestamp as just now rather than negative time', () {
      expect(
        formatRelative(now.add(const Duration(minutes: 10)), now: now),
        'just now',
      );
    });
  });
}
