import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Единственный HTTP-клиент приложения.
///
/// Автоматически добавляет Firebase ID-токен в каждый запрос.
/// При 401 — принудительно обновляет токен и повторяет запрос один раз.
///
/// НАСТРОЙКА BASEURL под среду:
///   Android эмулятор → http://10.0.2.2:8080/api
///   iOS симулятор     → http://localhost:8080/api
///   Реальный телефон  → http://192.168.X.X:8080/api  (IP компьютера в локальной сети)
///   ngrok             → https://xxxx.ngrok-free.app/api
class ApiClient {
  static const String baseUrl = 'http://localhost:8080/api';

  // Синглтон: ApiClient() всегда возвращает один и тот же экземпляр
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _attachToken,
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
