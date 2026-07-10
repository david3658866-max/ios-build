// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterDTO _$RegisterDTOFromJson(Map<String, dynamic> json) => RegisterDTO(
  mode: json['mode'] as String? ?? 'username',
  userName: json['userName'] as String?,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  password: json['password'] as String,
  nickName: json['nickName'] as String?,
  code: json['code'] as String?,
  deviceInfo: json['deviceInfo'] as String?,
  deviceId: json['deviceId'] as String?,
  clientVersion: json['clientVersion'] as String?,
  loginType: json['loginType'] as String?,
  inviteCode: json['inviteCode'] as String?,
  registerTerminal: (json['registerTerminal'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$RegisterDTOToJson(RegisterDTO instance) =>
    <String, dynamic>{
      'mode': instance.mode,
      'userName': ?instance.userName,
      'phone': ?instance.phone,
      'email': ?instance.email,
      'password': instance.password,
      'nickName': ?instance.nickName,
      'code': ?instance.code,
      'deviceInfo': ?instance.deviceInfo,
      'deviceId': ?instance.deviceId,
      'clientVersion': ?instance.clientVersion,
      'loginType': ?instance.loginType,
      'inviteCode': ?instance.inviteCode,
      'registerTerminal': instance.registerTerminal,
    };
