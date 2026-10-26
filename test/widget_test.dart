import 'package:flutter_test/flutter_test.dart';
import 'package:plateful/config.dart';

void main() {
  test('default API base URL prefers USB reverse loopback', () {
    expect(AppConfig.apiBaseUrl, 'http://127.0.0.1:3001');
  });

  test('LAN and emulator hosts are available as fallbacks', () {
    expect(AppConfig.apiBaseUrlFallbacks, contains('http://192.168.1.24:3001'));
    expect(AppConfig.apiBaseUrlFallbacks, contains('http://10.0.2.2:3001'));
  });

  test('expiry soon threshold is one week', () {
    expect(AppConfig.expirySoonDays, 7);
    expect(AppConfig.expiryUrgentDays, 1);
  });
}
