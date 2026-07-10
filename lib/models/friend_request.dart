import 'package:json_annotation/json_annotation.dart';

import '../core/utils/json_parse.dart';

part 'friend_request.g.dart';

/// 好友申请。对应后端 FriendRequestVO（GET /friend/request/list）。
@JsonSerializable()
class FriendRequest {
  const FriendRequest({
    required this.id,
    this.sendId,
    this.sendNickName,
    this.sendHeadImage,
    this.recvId,
    this.recvNickName,
    this.recvHeadImage,
    this.remark,
    this.status = 1,
    this.applyTime,
  });

  @JsonKey(fromJson: JsonParse.asInt)
  final int id;
  @JsonKey(fromJson: JsonParse.asNullableInt)
  final int? sendId;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? sendNickName;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? sendHeadImage;
  @JsonKey(fromJson: JsonParse.asNullableInt)
  final int? recvId;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? recvNickName;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? recvHeadImage;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? remark;

  /// 1 待处理 / 2 同意 / 3 拒绝 / 4 过期，见 RequestStatus。
  @JsonKey(fromJson: JsonParse.asInt)
  final int status;

  /// 申请时间（毫秒时间戳）。
  @JsonKey(fromJson: JsonParse.asNullableDateTimeMs)
  final int? applyTime;

  factory FriendRequest.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FriendRequestToJson(this);
}
