import 'package:dio/dio.dart';

/// An error from the Swara API, read from its envelope:
/// `{"error": {"code", "message", "details"}}`.
class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;
  final Object? details;

  const ApiException(this.code, this.message, {this.statusCode, this.details});

  bool get isNetwork => code == 'network';
  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get needsParentMode => code == 'parent_mode_required';

  factory ApiException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      return ApiException(
        (error['code'] ?? 'error').toString(),
        (error['message'] ?? 'Something went wrong.').toString(),
        statusCode: status,
        details: error['details'],
      );
    }
    if (e.response == null) {
      return const ApiException(
        'network',
        'Could not reach Swara. Check that the server is running and try again.',
      );
    }
    return ApiException('http_$status', 'The server returned an error ($status).', statusCode: status);
  }

  /// Any error as an ApiException, so screens can show one message.
  static ApiException from(Object e) {
    if (e is ApiException) return e;
    if (e is DioException) return ApiException.fromDio(e);
    return ApiException('error', e.toString().replaceAll('Exception: ', ''));
  }

  @override
  String toString() => message;
}
