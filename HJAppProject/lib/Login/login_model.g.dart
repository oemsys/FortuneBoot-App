// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResisterLogin _$ResisterLoginFromJson(Map<String, dynamic> json) =>
    ResisterLogin(
      json['userName'] as String,
      json['nickName'] as String,
      json['email'] as String,
      json['phoneNumber'] as String,
      (json['sex'] as num).toInt(),
      json['avatar'] as String,
      json['password'] as String,
      (json['status'] as num).toInt(),
      (json['roleId'] as num).toInt(),
      json['remark'] as String,
      (json['source'] as num).toInt(),
    );

Map<String, dynamic> _$ResisterLoginToJson(ResisterLogin instance) =>
    <String, dynamic>{
      'userName': instance.userName,
      'nickName': instance.nickName,
      'email': instance.email,
      'phoneNumber': instance.phoneNumber,
      'sex': instance.sex,
      'avatar': instance.avatar,
      'password': instance.password,
      'status': instance.status,
      'roleId': instance.roleId,
      'remark': instance.remark,
      'source': instance.source,
    };

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      (json['code'] as num).toInt(),
      json['msg'] as String,
      json['data'] as String?,
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'code': instance.code,
      'msg': instance.msg,
      'data': instance.data,
    };
