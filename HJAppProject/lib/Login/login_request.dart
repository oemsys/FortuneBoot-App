import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:retrofit/retrofit.dart';
import 'login_model.dart'; // 导入数据模型
import 'login_constants.dart';

part 'login_request.g.dart'; // 代码生成文件

// 使用下面命令自动生成代码
// flutter pub run build_runner build
@RestApi()
abstract class LoginService {
  factory LoginService(
    Dio dio, {
    String? baseUrl,
    ParseErrorLogger? errorLogger,
  }) {
    return _LoginService(dio, baseUrl: baseUrl ?? LoginConstants.baseUrl, errorLogger: errorLogger);
  }

  @GET(LoginConstants.getRsaPublicKey)
  Future<LoginResponse> getRsaPublicKey();

  @POST(LoginConstants.login)
  Future<LoginResponse> login(@Body() Login post);

  @GET(LoginConstants.captchaImage)
  Future<LoginResponse> captchaImage();

  @GET(LoginConstants.getAllowRegisterRoles)
  Future<LoginResponse> getAllowRegisterRoles();

  @POST(LoginConstants.register)
  Future<LoginResponse> loginRegister(@Body() ResisterLogin post);
}

class LoginErrorReport extends ParseErrorLogger {
  @override
  void logError(Object error, StackTrace stackTrace, RequestOptions options) {
    debugPrint('LoginErrorReport: $error $stackTrace $options');
  }
}
