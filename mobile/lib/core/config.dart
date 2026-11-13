/// Адрес бэкенда.
///   - Android-эмулятор обращается к компьютеру как 10.0.2.2;
///   - веб-версия и десктоп — localhost.
/// Переопределить можно при запуске:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);
