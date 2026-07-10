// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginInfo _$LoginInfoFromJson(Map<String, dynamic> json) => LoginInfo(
  accessToken: JsonParse.asString(json['accessToken']),
  refreshToken: JsonParse.asString(json['refreshToken']),
  userId: JsonParse.asInt(json['userId']),
  accessTokenExpiresIn: json['accessTokenExpiresIn'] == null
      ? 0
      : JsonParse.asInt(json['accessTokenExpiresIn']),
  refreshTokenExpiresIn: json['refreshTokenExpiresIn'] == null
      ? 0
      : JsonParse.asInt(json['refreshTokenExpiresIn']),
  deviceId: JsonParse.asString(json['deviceId']),
);

Map<String, dynamic> _$LoginInfoToJson(LoginInfo instance) => <String, dynamic>{
  'accessToken': instance.accessToken,
  'refreshToken': instance.refreshToken,
  'userId': instance.userId,
  'accessTokenExpiresIn': instance.accessTokenExpiresIn,
  'refreshTokenExpiresIn': instance.refreshTokenExpiresIn,
  'deviceId': instance.deviceId,
};
