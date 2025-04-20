import 'package:dio/dio.dart';
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

    // 添加拦截器
    dio.interceptors.addAll([
      // 日志拦截器
      LogInterceptor(
        request: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: true,
        error: true,
        logPrint: (object) => _logger.d(object),
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
          options.headers.addAll(header);
          // options.headers['Authorization'] = 'Bearer ${_getToken()}';
          return handler.next(options);
        },
        onError: (error, handler) async {
          // 退出登录 lxjtodo
          // if (error.response?.statusCode == 401) {
          //   // token过期自动刷新逻辑
          //   // await _refreshToken();
          //   // return handler.resolve(await _retry(error.requestOptions));
          // }
          return handler.next(error);
        },
      ),
    ]);
  }
}
