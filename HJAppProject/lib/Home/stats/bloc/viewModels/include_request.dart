import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_login_example/Login/model/login_constants.dart';
import 'package:flutter_login_example/Login/model/login_model.dart';
import 'package:flutter_login_example/util/dio_client.dart';
import 'package:retrofit/retrofit.dart';

part 'include_request.g.dart'; // 代码生成文件

// 使用下面命令自动生成代码
// flutter pub run build_runner build

// 统计 统计各种指标的接口
@RestApi()
abstract class IncludeService {
  factory IncludeService({
    String? baseUrl,
  }) {
    Dio dio = DioClient().dio;
    return _IncludeService(dio,
        baseUrl: baseUrl ?? LoginConstants.baseUrl,
        errorLogger: AccountErrorReport());
  }

  @GET('/fortune/include/{groupId}/getTotalLiabilities')
  Future<HJResponse> getTotalLiabilities(@Path('groupId') int groupId);

  @GET('/fortune/include/{groupId}/getFortuneAssetsLiabilities')
  Future<HJResponse> getFortuneAssetsLiabilities(@Path('groupId') int groupId);
}

class AccountErrorReport extends ParseErrorLogger {
  @override
  void logError(Object error, StackTrace stackTrace, RequestOptions options) {
    debugPrint('LoginErrorReport: $error $stackTrace $options');
  }
}
