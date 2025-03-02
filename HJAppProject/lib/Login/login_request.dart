import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'login_model.dart'; // 导入数据模型
import 'login_constants.dart';

part 'login_request.g.dart'; // 代码生成文件

@RestApi(baseUrl: LoginConstants.loginHost)
abstract class LoginService {
  factory LoginService(Dio dio, {String baseUrl}) = _LoginService;

  @GET(LoginConstants.getRsaPublicKey)
  Future<LoginResponse> getRsaPublicKey();

  @POST(LoginConstants.register)
  Future<LoginResponse> loginRegister(@Body() ResisterLogin post);
}
