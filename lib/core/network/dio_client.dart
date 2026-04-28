import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(_JwtInterceptor());
  }

  Dio get dio => _dio;

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}

class _JwtInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token renovado en AuthNotifier — aquí solo propagamos el error
      // para que el provider de auth lo intercepte
    }
    super.onError(err, handler);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiException('Sin conexión. Verificá tu internet.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const ApiException('No se pudo conectar al servidor.');
    }
    final statusCode = e.response?.statusCode;
    final message = e.response?.data?['message'] as String? ?? 'Error desconocido';
    return ApiException(message, statusCode: statusCode);
  }

  @override
  String toString() => message;
}
