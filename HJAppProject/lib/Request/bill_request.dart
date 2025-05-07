import 'package:dio/dio.dart';
import 'package:flutter_login_example/Home/todos_overview/models/bill_item_add.dart';
import 'package:flutter_login_example/Login/model/login_model.dart';
import 'package:flutter_login_example/Request/base_request.dart';
import 'package:flutter_login_example/util/dio_client.dart';
import 'package:retrofit/retrofit.dart';

part 'bill_request.g.dart'; // 代码生成文件

// 使用下面命令自动生成代码
// flutter pub run build_runner build

// 账单API账单相关的增删查改
@RestApi()
abstract class BillService {
  factory BillService({
    String? baseUrl,
  }) {
    Dio dio = DioClient().dio;
    return _BillService(dio,
        baseUrl: baseUrl ?? dio.options.baseUrl,
        errorLogger: AccountErrorReport());
  }

  /// /fortune/bill/getPage
  /// 账单分页查询接口
  @GET('/fortune/bill/getPage')
  Future<HJResponse> getPage({
    // 基础分页参数
    @Query('pageNum') int pageNum = 1,
    @Query('pageSize') int pageSize = 20,

    // 时间范围参数（ISO 8601格式）
    @Query('beginTime') String? beginTime,
    @Query('endTime') String? endTime,

    // 金额范围过滤
    @Query('amountMin') int? amountMin,
    @Query('amountMax') int? amountMax,

    // 业务ID参数（大整数用String处理）
    @Query('bookId') String? bookId,
    @Query('accountId') String? accountId,
    @Query('payeeId') String? payeeId,

    // 分类/标签过滤（数组参数特殊处理） Uri.encodeComponent(jsonEncode(categoryIds))
    @Query('categoryIds') List<int>? categoryIds,
    @Query('tagIds') List<int>? tagIds,

    // 布尔型参数
    @Query('confirm') bool? confirm,
    @Query('include') bool? include,
    @Query('fileInclude') bool? fileInclude,

    // 字符串类型参数
    @Query('orderDirection') String? orderDirection,
    @Query('title') String? title,
    @Query('remark') String? remark,

    // 交易时间范围（自定义格式）
    @Query('tradeTimeStartTime') String? tradeTimeStartTime,
    @Query('tradeTimeEndTime') String? tradeTimeEndTime,

    // 账单类型过滤
    @Query('billType') String? billType,
  });

  // /fortune/bill/add
  @POST('/fortune/bill/add')
  Future<HJResponse> addBill(@Body() BillItemAdd addItem);
}
