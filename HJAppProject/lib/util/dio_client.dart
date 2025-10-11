import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';

class DioClient {
  // 私有静态实例
  static final DioClient _instance = DioClient._internal();

  // Dio实例
  late final Dio dio;

  // 日志记录器
  final Logger _logger = Logger();

  // 全局访问点
  factory DioClient() => _instance;

  // 私有构造函数
  DioClient._internal() {
    // 初始化Dio基础配置
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
    ));

    // // 添加拦截器
    dio.interceptors.addAll([
      // 日志拦截器
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: true,
        error: true,
        logPrint: (object) => debugPrint('$object'),
      ),
    ]);
  }

  // 动态更新配置
  void updateBaseUrl(String newUrl) {
    dio.options.baseUrl = newUrl;
  }

  void refreshToken(Map<String, dynamic> header) {
    dio.interceptors.addAll([
      // 统一认证拦截器
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 动态注入token
          bool needAuth = true;
          if (needAuth) {
            // 合并而不是覆盖，避免丢失 Content-Type 等原有头
            options.headers.addAll(header);
            // 如若缺失，则兜底设置为 application/json
            if (options.contentType == null || options.headers['Content-Type'] == null) {
              options.contentType = Headers.jsonContentType;
            }
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          return handler.next(error);
        },
      ),
    ]);
  }
}
