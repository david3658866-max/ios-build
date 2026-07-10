// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FriendRequest _$FriendRequestFromJson(Map<String, dynamic> json) =>
    FriendRequest(
      id: JsonParse.asInt(json['id']),
      sendId: JsonParse.asNullableInt(json['sendId']),
      sendNickName: JsonParse.asNullableString(json['sendNickName']),
      sendHeadImage: JsonParse.asNullableString(json['sendHeadImage']),
      recvId: JsonParse.asNullableInt(json['recvId']),
      recvNickName: JsonParse.asNullableString(json['recvNickName']),
      recvHeadImage: JsonParse.asNullableString(json['recvHeadImage']),
      remark: JsonParse.asNullableString(json['remark']),
      status: json['status'] == null ? 1 : JsonParse.asInt(json['status']),
      applyTime: JsonParse.asNullableDateTimeMs(json['applyTime']),
    );

Map<String, dynamic> _$FriendRequestToJson(FriendRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sendId': instance.sendId,
      'sendNickName': instance.sendNickName,
      'sendHeadImage': instance.sendHeadImage,
      'recvId': instance.recvId,
      'recvNickName': instance.recvNickName,
      'recvHeadImage': instance.recvHeadImage,
      'remark': instance.remark,
      'status': instance.status,
      'applyTime': instance.applyTime,
    };
