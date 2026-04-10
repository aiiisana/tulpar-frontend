import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Единственный HTTP-клиент приложения.
///
/// Автоматически добавляет Firebase ID-токен в каждый запрос.
/// При 401 — принудительно обновляет токен и повторяет запрос один раз.
///
/// НАСТРОЙКА BASEURL под среду:
///   Android эмулятор → --dart-define=API_BASE=http://10.0.2.2:8080/api
///   iOS симулятор     → --dart-define=API_BASE=http://localhost:8080/api  (по умолчанию)
///   Реальный телефон  → --dart-define=API_BASE=http://192.168.X.X:8080/api
///   Production        → --dart-define=API_BASE=https://api.yourapp.com/api
///
/// Пример запуска: flutter run --dart-define=API_BASE=http://10.0.2.2:8080/api
class ApiClient {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:8080/api',
  );

  // Синглтон: ApiClient() всегда возвращает один и тот же экземпляр
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _attachToken,
        onResponse: _unwrapApiResponse,
        onError: _handleError,
      ),
    );
  }

  // ---------- interceptors ----------

  Future<void> _attachToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _fetchToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  /// Бэкенд оборачивает все ответы в ApiResponse:
  ///   { "success": true, "data": <реальные данные>, "error": null }
  /// Этот interceptor автоматически разворачивает конверт, чтобы сервисы
  /// работали напрямую с реальными данными через response.data.
  void _unwrapApiResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('success')) {
      if (body['success'] == true) {
        response.data = body['data'];
      }
      // success == false: оставляем как есть, ошибка будет обработана выше
    }
    handler.next(response);
  }

  Future<void> _handleError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    // 401 — токен протух: обновляем принудительно и повторяем запрос
    if (error.response?.statusCode == 401) {
      final freshToken = await _fetchToken(forceRefresh: true);
      if (freshToken != null) {
        final retryOpts = error.requestOptions
          ..headers['Authorization'] = 'Bearer $freshToken';
        try {
          final retryResponse = await _dio.fetch(retryOpts);
          handler.resolve(retryResponse);
          return;
        } catch (_) {
          // если и после refresh упало — пробрасываем оригинальную ошибку
        }
      }
    }
    handler.next(error);
  }

  // ---------- helpers ----------

  Future<String?> _fetchToken({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }

  // ---------- public API ----------

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? params,
  }) =>
      _dio.get<T>(path, queryParameters: params);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _dio.patch<T>(path, data: data);
}
