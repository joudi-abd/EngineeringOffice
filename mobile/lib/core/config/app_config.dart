/// Where the app talks to. Override at build time:
/// `flutter run --dart-define=API_URL=http://10.0.2.2:8000/api`
class AppConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.ufuq-group.com/api',
  );

  /// Scheme + host (+ port) of the API, used to resolve `/storage/...` media.
  static String get origin {
    final uri = Uri.parse(apiUrl);
    return '${uri.scheme}://${uri.authority}';
  }
}
