import 'dart:convert';

import '../enums/chat_type.dart';
import '../enums/message_type.dart';
import 'string_util.dart';

const int _previewStorageMaxChars = 200;
const int _previewCardTitleMaxChars = 80;

/// 群聊会话列表是否显示「发送者: 」前缀。对齐 chat-item.vue `isShowSendName`。
bool shouldShowChatItemSendName({
  required String type,
  String? sendNickName,
  int? lastMsgType,
}) {
  if (type != ChatType.group) return false;
  if (!StringUtil.isNotBlank(sendNickName)) return false;
  final t = lastMsgType;
  if (t == null) return false;
  return _shouldPrefixSenderInPreview(t);
}

/// 会话预览是否按文本消息渲染表情。对齐 chat-item.vue `isTextMessage`。
bool isChatItemTextPreview(int? lastMsgType) =>
    lastMsgType == MessageType.text;

bool _shouldPrefixSenderInPreview(int type) {
  switch (type) {
    case MessageType.text:
    case MessageType.image:
    case MessageType.video:
    case MessageType.audio:
    case MessageType.file:
      return true;
    default:
      return false;
  }
}

/// 统一会话列表最后一条消息预览文案。
String? buildChatPreviewText(int type, String? content) {
  if (content == null) return null;
  if (type == MessageType.text || type == MessageType.tipText) {
    return _trimForStorage(content);
  }
  switch (type) {
    case MessageType.image:
      return '[图片]';
    case MessageType.video:
      return '[视频]';
    case MessageType.audio:
      return '[语音]';
    case MessageType.file:
      return '[文件]';
    case MessageType.recall:
      return '[撤回消息]';
    case MessageType.actRtVoice:
      return '[语音通话]';
    case MessageType.actRtVideo:
      return '[视频通话]';
    case MessageType.userCard:
      return _withCardTitle(
        prefix: '[个人名片]',
        content: content,
        keys: const ['nickName', 'name'],
      );
    case MessageType.groupCard:
      return _withCardTitle(
        prefix: '[群名片]',
        content: content,
        keys: const ['groupName', 'name'],
      );
    case MessageType.contractCard:
      return _withCardTitle(
        prefix: '[合同卡片]',
        content: content,
        keys: const ['title', 'name'],
      );
    case MessageType.loanCard:
      return _withCardTitle(
        prefix: '[借款卡片]',
        content: content,
        keys: const ['title', 'name'],
      );
    case MessageType.productCard:
      return _withCardTitle(
        prefix: '[产品卡片]',
        content: content,
        keys: const ['productName', 'title', 'name'],
      );
    case MessageType.systemMessage:
      return _systemTitle(content);
    case MessageType.receipt:
      return '[回执]';
    case MessageType.readed:
      return '[已读]';
    default:
      return '[消息]';
  }
}

String _withCardTitle({
  required String prefix,
  required String content,
  required List<String> keys,
}) {
  final title = _firstNonBlank(_decodeJsonMap(content), keys);
  return title == null ? prefix : '$prefix $title';
}

String _systemTitle(String content) {
  final title = _firstNonBlank(_decodeJsonMap(content), const ['title']);
  if (title != null) return title;
  final trimmed = content.trim();
  return trimmed.isEmpty ? '[系统通知]' : _trimForStorage(trimmed);
}

Map<String, dynamic>? _decodeJsonMap(String content) {
  try {
    final decoded = jsonDecode(content);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

String? _firstNonBlank(Map<String, dynamic>? map, List<String> keys) {
  if (map == null) return null;
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return StringUtil.ellipsis(text, _previewCardTitleMaxChars);
    }
  }
  return null;
}

String _trimForStorage(String input) {
  final text = input.trim();
  if (text.isEmpty) return text;
  return StringUtil.ellipsis(text, _previewStorageMaxChars);
}

/// 列表滑动/拖动时不弹出长按菜单。对齐 long-press-menu `isTouchMove`。
bool shouldOpenChatLongPressMenu({required bool touchMoved}) => !touchMoved;
