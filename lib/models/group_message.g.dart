// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMessage _$GroupMessageFromJson(Map<String, dynamic> json) => GroupMessage(
  id: JsonParse.asNullableInt(json['id']),
  tmpId: JsonParse.asNullableString(json['tmpId']),
  groupId: JsonParse.asInt(json['groupId']),
  sendId: JsonParse.asInt(json['sendId']),
  sendNickName: JsonParse.asNullableString(json['sendNickName']),
  content: JsonParse.asNullableString(json['content']),
  type: json['type'] == null ? 0 : JsonParse.asInt(json['type']),
  receipt: json['receipt'] == null ? false : JsonParse.asBool(json['receipt']),
  receiptOk: json['receiptOk'] == null
      ? false
      : JsonParse.asBool(json['receiptOk']),
  readedCount: json['readedCount'] == null
      ? 0
      : JsonParse.asInt(json['readedCount']),
  atUserIds: json['atUserIds'] == null
      ? const []
      : JsonParse.asIntList(json['atUserIds']),
  quoteMessage: json['quoteMessage'] == null
      ? null
      : QuoteMessage.fromJson(json['quoteMessage'] as Map<String, dynamic>),
  status: json['status'] == null ? 0 : JsonParse.asInt(json['status']),
  sendTime: JsonParse.asNullableDateTimeMs(json['sendTime']),
);

Map<String, dynamic> _$GroupMessageToJson(GroupMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tmpId': instance.tmpId,
      'groupId': instance.groupId,
      'sendId': instance.sendId,
      'sendNickName': instance.sendNickName,
      'content': instance.content,
      'type': instance.type,
      'receipt': instance.receipt,
      'receiptOk': instance.receiptOk,
      'readedCount': instance.readedCount,
      'atUserIds': instance.atUserIds,
      'quoteMessage': instance.quoteMessage?.toJson(),
      'status': instance.status,
      'sendTime': instance.sendTime,
    };
