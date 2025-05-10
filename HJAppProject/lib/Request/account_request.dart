import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_login_example/login/model/login_model.dart';
import 'package:flutter_login_example/request/base_request.dart';
import 'package:flutter_login_example/util/dio_client.dart';
import 'package:retrofit/retrofit.dart';

part 'account_request.g.dart'; // 代码生成文件

// 使用下面命令自动生成代码
// flutter pub run build_runner build

// 账户API
@RestApi()
abstract class AccountService extends BaseService {
  factory AccountService({
    String? baseUrl,
  }) {
    Dio dio = DioClient().dio;
    return _AccountService(dio,
        baseUrl: baseUrl ?? dio.options.baseUrl,
        errorLogger: AccountErrorReport());
  }

  /// 查询启动的账户列表
  @GET('/fortune/account/{groupId}/getEnableList')
  Future<HJResponse> getEnableList(@Path('groupId') int id, {int? type});
}
