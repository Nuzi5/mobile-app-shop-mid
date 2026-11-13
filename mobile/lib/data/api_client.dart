import 'package:dio/dio.dart';

/// Ошибка при обращении к серверу, с понятным текстом для пользователя.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Тонкая обёртка над Dio: один базовый адрес и единая обработка ошибок.
class ApiClient {
  ApiClient({required String baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              contentType: Headers.jsonContentType,
            ));

  final Dio _dio;

  Future<Map<String, dynamic>> get(String path) =>
      _send(() => _dio.get<Map<String, dynamic>>(path));

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _send(() => _dio.post<Map<String, dynamic>>(path, data: body));

  Future<Map<String, dynamic>> delete(String path) =>
      _send(() => _dio.delete<Map<String, dynamic>>(path));

  Future<Map<String, dynamic>> _send(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      if (data == null) {
        throw const ApiException('Пустой ответ от сервера');
      }
      return data;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) {
        throw const ApiException('Не найдено на сервере');
      }
      if (status == 400) {
        throw const ApiException('Неверный запрос');
      }
      throw const ApiException(
        'Нет связи с сервером. Проверьте, что бэкенд запущен.',
      );
    }
  }
}
