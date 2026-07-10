// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: JsonParse.asInt(json['id']),
  userName: JsonParse.asNullableString(json['userName']),
  phone: JsonParse.asNullableString(json['phone']),
  email: JsonParse.asNullableString(json['email']),
  nickName: JsonParse.asNullableString(json['nickName']),
  sex: json['sex'] == null ? 0 : JsonParse.asInt(json['sex']),
  type: json['type'] == null ? 1 : JsonParse.typeFromJson(json['type']),
  signature: JsonParse.asNullableString(json['signature']),
  headImage: JsonParse.asNullableString(json['headImage']),
  headImageThumb: JsonParse.asNullableString(json['headImageThumb']),
  companyName: JsonParse.asNullableString(json['companyName']),
  isBanned: json['isBanned'] == null
      ? false
      : JsonParse.asBool(json['isBanned']),
  reason: JsonParse.asNullableString(json['reason']),
  isManualApprove: json['isManualApprove'] == null
      ? false
      : JsonParse.asBool(json['isManualApprove']),
  isInBlacklist: json['isInBlacklist'] == null
      ? false
      : JsonParse.asBool(json['isInBlacklist']),
  isAudioTip: json['isAudioTip'] == null
      ? false
      : JsonParse.asBool(json['isAudioTip']),
  status: json['status'] == null ? 0 : JsonParse.asInt(json['status']),
  online: json['online'] == null ? false : JsonParse.asBool(json['online']),
  lastLoginTime: JsonParse.asNullableDateTimeMs(json['lastLoginTime']),
  userIdentity: json['userIdentity'] == null
      ? 0
      : JsonParse.asInt(json['userIdentity']),
  agentId: JsonParse.asNullableInt(json['agentId']),
  isRealName: json['isRealName'] == null
      ? false
      : JsonParse.asBool(json['isRealName']),
  totpEnabled: json['totpEnabled'] == null
      ? false
      : JsonParse.asBool(json['totpEnabled']),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'userName': instance.userName,
  'phone': instance.phone,
  'email': instance.email,
  'nickName': instance.nickName,
  'sex': instance.sex,
  'type': instance.type,
  'signature': instance.signature,
  'headImage': instance.headImage,
  'headImageThumb': instance.headImageThumb,
  'companyName': instance.companyName,
  'isBanned': instance.isBanned,
  'reason': instance.reason,
  'isManualApprove': instance.isManualApprove,
  'isInBlacklist': instance.isInBlacklist,
  'isAudioTip': instance.isAudioTip,
  'status': instance.status,
  'online': instance.online,
  'lastLoginTime': instance.lastLoginTime,
  'userIdentity': instance.userIdentity,
  'agentId': instance.agentId,
  'isRealName': instance.isRealName,
  'totpEnabled': instance.totpEnabled,
};
