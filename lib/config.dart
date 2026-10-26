/// Runtime configuration via `--dart-define`.
abstract final class AppConfig {
  /// Preferred API base URL.
  ///
  /// Default is USB reverse loopback — use `.\start-plateful.ps1` (or
  /// `adb reverse tcp:3001 tcp:3001`) so the phone reaches the PC server.
  ///
  /// Overrides:
  /// - Same Wi‑Fi LAN: `--dart-define=API_BASE_URL=http://192.168.1.24:3001`
  /// - Android emulator: `--dart-define=API_BASE_URL=http://10.0.2.2:3001`
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3001',
  );

  /// Extra candidates tried automatically if [apiBaseUrl] is unreachable.
  static const apiBaseUrlFallbacks = <String>[
    'http://192.168.1.24:3001',
    'http://10.0.2.2:3001',
    'http://localhost:3001',
  ];

  static const forceDemoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: false,
  );

  /// Orange "use this week" window.
  static const expirySoonDays = 7;

  /// Red "use today / tomorrow" window.
  static const expiryUrgentDays = 1;
}
