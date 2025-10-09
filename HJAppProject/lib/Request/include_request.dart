import 'package:dio/dio.dart';
import 'package:hjproject/login/model/login_model.dart';
import 'package:hjproject/request/base_request.dart';
import 'package:hjproject/util/dio_client.dart';
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
        baseUrl: baseUrl ?? dio.options.baseUrl,
        errorLogger: AccountErrorReport());
  }

  @GET('/fortune/include/{groupId}/getTotalLiabilities')
  Future<HJResponse> getTotalLiabilities(@Path('groupId') int groupId);

  @GET('/fortune/include/{groupId}/getFortuneAssetsLiabilities')
  Future<HJResponse> getFortuneAssetsLiabilities(@Path('groupId') int groupId);

  @GET('/fortune/include/getBillStatistics')
  Future<HJResponse> getBillStatistics(
    @Query('bookId') int bookId,
    @Query('tradeTimeStartTime') String tradeTimeStartTime,
    @Query('tradeTimeEndTime') String tradeTimeEndTime,
  );

  /// 收入类型分析
  @GET('/fortune/include/getCategoryIncome')
  Future<HJResponse> getCategoryIncome(
    @Query('bookId') int bookId,
    @Query('startDate') String startDate,
    @Query('endDate') String endDate,
  );

  /// 支出类型分析
  /// [
  ///      {
  ///          "value": 492.0000,
  ///          "name": "维持类-1",
  ///          "percent": 0.04853905
  ///      },
  /// ]
  @GET('/fortune/include/getCategoryExpense')
  Future<HJResponse> getCategoryExpense(
    @Query('bookId') int bookId,
    @Query('startDate') String startDate,
    @Query('endDate') String endDate,
  );

  /// 收入折线图
  @GET('/fortune/include/getIncomeTrends')
  Future<HJResponse> getIncomeTrends(
    @Query('bookId') int bookId,
    @Query('timeGranularity') int timeGranularity, // 1，日 2，月 3，年
    @Query('timePoint') String timePoint,
  );

  ///
  /// 支出折线图
  /// data: [
  ///   {
  ///   name: 2025-09-09,
  ///   value: 199.0000
  ///   }
  /// ]
  @GET('/fortune/include/getExpenseTrends')
  Future<HJResponse> getExpenseTrends(
    @Query('bookId') int bookId,
    @Query('timeGranularity') int timeGranularity, // 1，日 2，月 3，年
    @Query('timePoint') String timePoint,
  );
}
