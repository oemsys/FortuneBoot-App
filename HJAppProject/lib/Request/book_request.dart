import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_login_example/Login/model/login_model.dart';
import 'package:flutter_login_example/util/dio_client.dart';
import 'package:retrofit/retrofit.dart';

part 'book_request.g.dart'; // 代码生成文件

// 使用下面命令自动生成代码
// flutter pub run build_runner build

// 分组API 分组相关的增删查改
@RestApi()
abstract class BookService {
  factory BookService({
    String? baseUrl,
  }) {
    Dio dio = DioClient().dio;
    return _BookService(dio,
        baseUrl: baseUrl ?? dio.options.baseUrl,
        errorLogger: AccountErrorReport());
  }

  // /fortune/book/base/{groupId}/getByGroupId
  /// [{"bookId":1,"groupId":1,"bookName":"演示分组的默认账本","defaultCurrency":"CNY","defaultExpenseAccountId":4,"defaultIncomeAccountId":4,"defaultTransferOutAccountId":4,"defaultTransferInAccountId":4,"sort":null,"remark":"用于个人生活记账。将支出分为维持类，消费类，提升类，社交类4个大类，收入分为主动收入，被动收入，社交收入3个大类。","enable":true},{"bookId":5,"groupId":1,"bookName":"测试账本","defaultCurrency":"CNY","defaultExpenseAccountId":null,"defaultIncomeAccountId":null,"defaultTransferOutAccountId":null,"defaultTransferInAccountId":null,"sort":null,"remark":"参考随手记","enable":true}]}
  @GET('/fortune/book/base/{groupId}/getByGroupId')
  Future<HJResponse> getByGroupId(@Path('groupId') int groupId);
}

class AccountErrorReport extends ParseErrorLogger {
  @override
  void logError(Object error, StackTrace stackTrace, RequestOptions options) {
    debugPrint('LoginErrorReport: $error $stackTrace $options');
  }
}
