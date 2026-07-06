import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

class ApiLogEntry {
  final String method;
  final String url;
  final Map<String, dynamic>? requestHeaders;
  final dynamic requestBody;
  final int? statusCode;
  final dynamic responseBody;
  final String? errorMessage;
  final DateTime timestamp;
  final Duration? duration;

  ApiLogEntry({
    required this.method,
    required this.url,
    this.requestHeaders,
    this.requestBody,
    this.statusCode,
    this.responseBody,
    this.errorMessage,
    required this.timestamp,
    this.duration,
  });

  bool get isError =>
      errorMessage != null || (statusCode != null && statusCode! >= 400);
}

/// Global in-memory log of every API call made through Dio instances that
/// have ApiLogInterceptor attached. Capped at 200 entries so it doesn't
/// grow unbounded during a long session.
class ApiLogService extends GetxService {
  static ApiLogService get to => Get.find<ApiLogService>();

  final RxList<ApiLogEntry> logs = <ApiLogEntry>[].obs;

  static const _maxEntries = 200;

  void add(ApiLogEntry entry) {
    logs.insert(0, entry); // newest first
    if (logs.length > _maxEntries) {
      logs.removeRange(_maxEntries, logs.length);
    }
  }

  void clear() => logs.clear();
}

/// Attach this to any Dio instance to have every request/response/error
/// automatically recorded into ApiLogService.
class ApiLogInterceptor extends Interceptor {
  final _startTimes = <RequestOptions, DateTime>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _startTimes[options] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final start = _startTimes.remove(response.requestOptions);
    ApiLogService.to.add(ApiLogEntry(
      method: response.requestOptions.method,
      url: response.requestOptions.uri.toString(),
      requestHeaders: response.requestOptions.headers,
      requestBody: response.requestOptions.data,
      statusCode: response.statusCode,
      responseBody: response.data,
      timestamp: DateTime.now(),
      duration: start != null ? DateTime.now().difference(start) : null,
    ));
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final start = _startTimes.remove(err.requestOptions);
    ApiLogService.to.add(ApiLogEntry(
      method: err.requestOptions.method,
      url: err.requestOptions.uri.toString(),
      requestHeaders: err.requestOptions.headers,
      requestBody: err.requestOptions.data,
      statusCode: err.response?.statusCode,
      responseBody: err.response?.data,
      errorMessage: err.message,
      timestamp: DateTime.now(),
      duration: start != null ? DateTime.now().difference(start) : null,
    ));
    handler.next(err);
  }
}
