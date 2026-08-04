// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Friend _$FriendFromJson(Map<String, dynamic> json) => Friend(
  id: JsonParse.asInt(json['id']),
  nickName: JsonParse.asNullableString(json['nickName']),
  showNickName: JsonParse.asNullableString(json['showNickName']),
  remarkNickName: JsonParse.asNullableString(json['remarkNickName']),
  headImage: JsonParse.asNullableString(json['headImage']),
  companyName: JsonParse.asNullableString(json['companyName']),
  isDnd: json['isDnd'] == null ? false : JsonParse.asBool(json['isDnd']),
  isTop: json['isTop'] == null ? false : JsonParse.asBool(json['isTop']),
  deleted: json['deleted'] == null ? false : JsonParse.asBool(json['deleted']),
  online: json['online'] == null ? false : JsonParse.asBool(json['online']),
  onlineWeb: json['onlineWeb'] == null
      ? false
      : JsonParse.asBool(json['onlineWeb']),
  onlineApp: json['onlineApp'] == null
      ? false
      : JsonParse.asBool(json['onlineApp']),
  topMessage: json['topMessage'] == null
      ? null
      : PrivateMessage.fromJson(
          Map<String, dynamic>.from(json['topMessage'] as Map),
        ),
);

Map<String, dynamic> _$FriendToJson(Friend instance) => <String, dynamic>{
  'id': instance.id,
  'nickName': instance.nickName,
  'showNickName': instance.showNickName,
  'remarkNickName': instance.remarkNickName,
  'headImage': instance.headImage,
  'companyName': instance.companyName,
  'isDnd': instance.isDnd,
  'isTop': instance.isTop,
  'deleted': instance.deleted,
  'online': instance.online,
  'onlineWeb': instance.onlineWeb,
  'onlineApp': instance.onlineApp,
  'topMessage': instance.topMessage?.toJson(),
};
