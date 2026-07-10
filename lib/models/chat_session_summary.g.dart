// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_session_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatSessionSummary _$ChatSessionSummaryFromJson(Map<String, dynamic> json) =>
    ChatSessionSummary(
      type: JsonParse.asString(json['type']),
      targetId: JsonParse.asInt(json['targetId']),
      lastContent: JsonParse.asNullableString(json['lastContent']),
      lastSendTime: JsonParse.asNullableDateTimeMs(json['lastSendTime']),
      sendNickName: JsonParse.asNullableString(json['sendNickName']),
      unreadCount: json['unreadCount'] == null
          ? 0
          : JsonParse.asInt(json['unreadCount']),
      maxMsgId: json['maxMsgId'] == null
          ? 0
          : JsonParse.asInt(json['maxMsgId']),
      showName: JsonParse.asNullableString(json['showName']),
      headImage: JsonParse.asNullableString(json['headImage']),
      companyName: JsonParse.asNullableString(json['companyName']),
      isDnd: json['isDnd'] == null ? false : JsonParse.asBool(json['isDnd']),
      isTop: json['isTop'] == null ? false : JsonParse.asBool(json['isTop']),
    );

Map<String, dynamic> _$ChatSessionSummaryToJson(ChatSessionSummary instance) =>
    <String, dynamic>{
      'type': instance.type,
      'targetId': instance.targetId,
      'lastContent': instance.lastContent,
      'lastSendTime': instance.lastSendTime,
      'sendNickName': instance.sendNickName,
      'unreadCount': instance.unreadCount,
      'maxMsgId': instance.maxMsgId,
      'showName': instance.showName,
      'headImage': instance.headImage,
      'companyName': instance.companyName,
      'isDnd': instance.isDnd,
      'isTop': instance.isTop,
    };
