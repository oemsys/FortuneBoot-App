import 'package:json_annotation/json_annotation.dart';

part 'login_model.g.dart';
// 使用下面命令自动生成代码
// flutter pub run build_runner build 
@JsonSerializable()
class ResisterLogin {
  final String userName;
  final String nickName;
  final String email;
  final String phoneNumber;
  final int sex;
  final String avatar;
  final String password;
  final int status;
  final int roleId;
  final String remark;
  final int source;


  ResisterLogin(this.userName, this.nickName, this.email, this.phoneNumber, this.sex, this.avatar, this.password, this.status, this.roleId, this.remark, this.source);

  factory ResisterLogin.fromJson(Map<String, dynamic> json) => _$ResisterLoginFromJson(json);
  Map<String, dynamic> toJson() => _$ResisterLoginToJson(this);
  @override
  String toString() {
    return 'ResisterLogin{userName: $userName, nickName: $nickName, email: $email, phoneNumber: $phoneNumber, sex: $sex, avatar: $avatar, password: $password, status: $status, roleId: $roleId, remark: $remark, source: $source}';
  }
}

@JsonSerializable()
class LoginResponse {
  final int code;
  final String msg;
  final String? data;
  LoginResponse(this.code, this.msg, this.data);
  factory LoginResponse.fromJson(Map<String, dynamic> json) => _$LoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
  @override
  String toString() {
    return 'LoginResponse{code: $code, msg: $msg, data: $data}';
  }
}