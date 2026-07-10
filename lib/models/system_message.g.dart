// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemMessage _$SystemMessageFromJson(Map<String, dynamic> json) =>
    SystemMessage(
      id: JsonParse.asInt(json['id']),
      seqNo: _readSeqNo(json, 'seqNo') == null
          ? 0
          : JsonParse.asInt(_readSeqNo(json, 'seqNo')),
      title: JsonParse.asNullableString(json['title']),
      coverUrl: JsonParse.asNullableString(json['coverUrl']),
      intro: JsonParse.asNullableString(json['intro']),
      content: JsonParse.asNullableString(json['content']),
      type: json['type'] == null ? 0 : JsonParse.asInt(json['type']),
      status: json['status'] == null ? 0 : JsonParse.asInt(json['status']),
      sendTime: JsonParse.asNullableDateTimeMs(json['sendTime']),
    );

Map<String, dynamic> _$SystemMessageToJson(SystemMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'seqNo': instance.seqNo,
      'title': instance.title,
      'coverUrl': instance.coverUrl,
      'intro': instance.intro,
      'content': instance.content,
      'type': instance.type,
      'status': instance.status,
      'sendTime': instance.sendTime,
    };
