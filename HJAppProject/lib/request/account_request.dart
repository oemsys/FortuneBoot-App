import 'package:dio/dio.dart';
import 'package:hjproject/Home/account_manage/models/fortune_account.dart';
import 'package:hjproject/login/model/login_model.dart';
import 'package:hjproject/request/base_request.dart';
import 'package:hjproject/util/dio_client.dart';
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

// 封装账户分页查询（避免依赖 Retrofit 代码生成），与现有 PayeeService 风格一致
// - GET /fortune/account/getPage
// - 固定 recycleBin=false
// - 入参：groupId, accountType（1-4），可选 pageNum/pageSize
class AccountQueryService {
  final Dio _dio = DioClient().dio;

  Future<FortuneAccountPageData> getPage({
    required int groupId,
    required int accountType,
    int pageNum = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      '/fortune/account/getPage',
      queryParameters: {
        'groupId': groupId,
        'recycleBin': false,
        'accountType': accountType,
        'pageNum': pageNum,
        'pageSize': pageSize,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final code = data['code'] as int? ?? -1;
      if (code == 0) {
        final d = data['data'] as Map<String, dynamic>? ?? {};
        return FortuneAccountPageData.fromJson(d);
      } else {
        final msg = data['msg']?.toString() ?? '服务返回错误';
        throw Exception(msg);
      }
    } else {
      throw Exception('网络错误: ${response.statusCode}');
    }
  }
/// 将账户移入回收站
  /// - POST /fortune/account/{groupId}/{accountId}/moveToRecycleBin
  /// - 返回值：{"code":0,"msg":"操作成功","data":null}
  /// - code == 0 视为成功，否则抛出异常（沿用本文件分页查询的错误处理风格）
  Future<bool> moveToRecycleBin({
    required int groupId,
    required int accountId,
  }) async {
    final response = await _dio.post(
      '/fortune/account/$groupId/$accountId/moveToRecycleBin',
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final code = data['code'] as int? ?? -1;
      if (code == 0) {
        return true;
      } else {
        final msg = data['msg']?.toString() ?? '服务返回错误';
        throw Exception(msg);
      }
    } else {
      throw Exception('网络错误: ${response.statusCode}');
    }
  }
}
