// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMember _$GroupMemberFromJson(Map<String, dynamic> json) => GroupMember(
  userId: JsonParse.asInt(json['userId']),
  showNickName: JsonParse.asNullableString(json['showNickName']),
  remarkNickName: JsonParse.asNullableString(json['remarkNickName']),
  headImage: JsonParse.asNullableString(json['headImage']),
  companyName: JsonParse.asNullableString(json['companyName']),
  isManager: json['isManager'] == null
      ? false
      : JsonParse.asBool(json['isManager']),
  isMuted: json['isMuted'] == null ? false : JsonParse.asBool(json['isMuted']),
  quit: json['quit'] == null ? false : JsonParse.asBool(json['quit']),
  online: json['online'] == null ? false : JsonParse.asBool(json['online']),
  showGroupName: JsonParse.asNullableString(json['showGroupName']),
  remarkGroupName: JsonParse.asNullableString(json['remarkGroupName']),
  version: json['version'] == null ? 0 : JsonParse.asInt(json['version']),
);

Map<String, dynamic> _$GroupMemberToJson(GroupMember instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'showNickName': instance.showNickName,
      'remarkNickName': instance.remarkNickName,
      'headImage': instance.headImage,
      'companyName': instance.companyName,
      'isManager': instance.isManager,
      'isMuted': instance.isMuted,
      'quit': instance.quit,
      'online': instance.online,
      'showGroupName': instance.showGroupName,
      'remarkGroupName': instance.remarkGroupName,
      'version': instance.version,
    };
