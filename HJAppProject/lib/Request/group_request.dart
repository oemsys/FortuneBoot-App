import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_login_example/Login/model/login_model.dart';
import 'package:flutter_login_example/util/dio_client.dart';
import 'package:retrofit/retrofit.dart';

part 'group_request.g.dart'; // 代码生成文件

// 使用下面命令自动生成代码
// flutter pub run build_runner build

// 分组API 分组相关的增删查改
@RestApi()
abstract class GroupService {
  factory GroupService({
    String? baseUrl,
  }) {
    Dio dio = DioClient().dio;
    return _GroupService(dio,
        baseUrl: baseUrl ?? dio.options.baseUrl,
        errorLogger: AccountErrorReport());
  }

  @GET('/fortune/group/getDefaultGroupId')
  Future<HJResponse> getDefaultGroupId();

  /// 获取分组详情
  /// {"code":0,"msg":"操作成功","data":{"groupId":1,"groupName":"演示分组","defaultCurrency":"CNY","roleTypeDesc":null,"enable":true,"defaultBookId":1,"defaultBookName":null,"remark":null}}
  @GET('/fortune/group/{groupId}/getByGroupId')
  Future<HJResponse> getByGroupId(@Path('groupId') int groupId);
}

class AccountErrorReport extends ParseErrorLogger {
  @override
  void logError(Object error, StackTrace stackTrace, RequestOptions options) {
    debugPrint('LoginErrorReport: $error $stackTrace $options');
  }
}
