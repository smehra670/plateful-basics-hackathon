/// Runtime configuration via `--dart-define`.
abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3001',
  );

  static const forceDemoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: false,
  );

  /// Highlight ingredients expiring within this many days.
  static const expirySoonDays = 3;
}
