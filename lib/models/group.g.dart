// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Group _$GroupFromJson(Map<String, dynamic> json) => Group(
  id: JsonParse.asInt(json['id']),
  name: JsonParse.asNullableString(json['name']),
  ownerId: JsonParse.asNullableInt(json['ownerId']),
  headImage: JsonParse.asNullableString(json['headImage']),
  headImageThumb: JsonParse.asNullableString(json['headImageThumb']),
  notice: JsonParse.asNullableString(json['notice']),
  remarkNickName: JsonParse.asNullableString(json['remarkNickName']),
  showNickName: JsonParse.asNullableString(json['showNickName']),
  showGroupName: JsonParse.asNullableString(json['showGroupName']),
  remarkGroupName: JsonParse.asNullableString(json['remarkGroupName']),
  isAllMuted: json['isAllMuted'] == null
      ? false
      : JsonParse.asBool(json['isAllMuted']),
  isAllowInvite: json['isAllowInvite'] == null
      ? false
      : JsonParse.asBool(json['isAllowInvite']),
  isAllowShareCard: json['isAllowShareCard'] == null
      ? false
      : JsonParse.asBool(json['isAllowShareCard']),
  dissolve: json['dissolve'] == null
      ? false
      : JsonParse.asBool(json['dissolve']),
  quit: json['quit'] == null ? false : JsonParse.asBool(json['quit']),
  isMuted: json['isMuted'] == null ? false : JsonParse.asBool(json['isMuted']),
  isBanned: json['isBanned'] == null
      ? false
      : JsonParse.asBool(json['isBanned']),
  reason: JsonParse.asNullableString(json['reason']),
  isDnd: json['isDnd'] == null ? false : JsonParse.asBool(json['isDnd']),
  isTop: json['isTop'] == null ? false : JsonParse.asBool(json['isTop']),
  topMessage: json['topMessage'] == null
      ? null
      : GroupMessage.fromJson(json['topMessage'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GroupToJson(Group instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'ownerId': instance.ownerId,
  'headImage': instance.headImage,
  'headImageThumb': instance.headImageThumb,
  'notice': instance.notice,
  'remarkNickName': instance.remarkNickName,
  'showNickName': instance.showNickName,
  'showGroupName': instance.showGroupName,
  'remarkGroupName': instance.remarkGroupName,
  'isAllMuted': instance.isAllMuted,
  'isAllowInvite': instance.isAllowInvite,
  'isAllowShareCard': instance.isAllowShareCard,
  'dissolve': instance.dissolve,
  'quit': instance.quit,
  'isMuted': instance.isMuted,
  'isBanned': instance.isBanned,
  'reason': instance.reason,
  'isDnd': instance.isDnd,
  'isTop': instance.isTop,
  'topMessage': instance.topMessage,
};
