// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginDTO _$LoginDTOFromJson(Map<String, dynamic> json) => LoginDTO(
  mode: json['mode'] as String? ?? 'username',
  terminal: (json['terminal'] as num?)?.toInt() ?? 1,
  userName: json['userName'] as String?,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  password: json['password'] as String,
  totpCode: json['totpCode'] as String?,
  code: json['code'] as String?,
  deviceInfo: json['deviceInfo'] as String?,
  deviceId: json['deviceId'] as String?,
  clientVersion: json['clientVersion'] as String?,
  loginType: json['loginType'] as String?,
  platform: json['platform'] as String?,
  rawHardwareId: json['rawHardwareId'] as String?,
  imei: json['imei'] as String?,
  imei2: json['imei2'] as String?,
);

Map<String, dynamic> _$LoginDTOToJson(LoginDTO instance) => <String, dynamic>{
  'mode': instance.mode,
  'terminal': instance.terminal,
  'userName': ?instance.userName,
  'phone': ?instance.phone,
  'email': ?instance.email,
  'password': instance.password,
  'totpCode': ?instance.totpCode,
  'code': ?instance.code,
  'deviceInfo': ?instance.deviceInfo,
  'deviceId': ?instance.deviceId,
  'clientVersion': ?instance.clientVersion,
  'loginType': ?instance.loginType,
  'platform': ?instance.platform,
  'rawHardwareId': ?instance.rawHardwareId,
  'imei': ?instance.imei,
  'imei2': ?instance.imei2,
};
