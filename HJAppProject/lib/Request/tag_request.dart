// /fortune/tag/{bookId}/getEnableList
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_login_example/Login/model/login_model.dart';
import 'package:flutter_login_example/Request/base_request.dart';
import 'package:flutter_login_example/util/dio_client.dart';
import 'package:retrofit/retrofit.dart';

part 'tag_request.g.dart'; // 代码生成文件

// 使用下面命令自动生成代码
// flutter pub run build_runner build

// 账户API
@RestApi()
abstract class TagService extends BaseService {
  factory TagService({
    String? baseUrl,
  }) {
    Dio dio = DioClient().dio;
    return _TagService(dio,
        baseUrl: baseUrl ?? dio.options.baseUrl,
        errorLogger: AccountErrorReport());
  }

  /// 查询启动的战虎
  @GET('/fortune/tag/{bookId}/getEnableList')
  Future<HJResponse> getEnableList(
    @Path('bookId') int bookId, {
    @Query('billType') int? type,
  });
}
