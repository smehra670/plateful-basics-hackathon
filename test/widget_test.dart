import 'package:flutter_test/flutter_test.dart';
import 'package:plateful/config.dart';

void main() {
  test('default API base URL targets Android emulator loopback', () {
    expect(AppConfig.apiBaseUrl, contains('10.0.2.2'));
  });

  test('expiry soon threshold is 3 days', () {
    expect(AppConfig.expirySoonDays, 3);
  });
}
