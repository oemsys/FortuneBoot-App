import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_login_example/Login/model/login_model.dart';
import 'package:flutter_login_example/util/dio_client.dart';
import 'package:retrofit/retrofit.dart';

part 'account_request.g.dart'; // 代码生成文件

// 使用下面命令自动生成代码
// flutter pub run build_runner build

// 账户API
@RestApi()
abstract class AccountService {
  factory AccountService({
    String? baseUrl,
  }) {
    Dio dio = DioClient().dio;
    return _AccountService(dio,
        baseUrl: baseUrl ?? dio.options.baseUrl,
        errorLogger: AccountErrorReport());
  }

  /// 查询启动的战虎
  @GET('/fortune/account/{groupId}/getEnableList')
  Future<HJResponse> getEnableList(@Path('groupId') int groupId);
}

class AccountErrorReport extends ParseErrorLogger {
  @override
  void logError(Object error, StackTrace stackTrace, RequestOptions options) {
    debugPrint('LoginErrorReport: $error $stackTrace $options');
  }
}
