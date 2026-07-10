/// 退群 / 解散群确认文案与 API 契约。对齐 group-info.vue。
abstract final class GroupLeaveUtil {
  /// uniapp 默认勾选「清除聊天记录」。
  static const bool defaultCleanOnLeave = true;

  static const String cleanSwitchLabel = '清除聊天记录';

  static GroupLeaveConfirm quitConfirm() => const GroupLeaveConfirm(
        title: '确认退出',
        content: '退出群聊后将不再接受群里的消息，确认退出吗?',
        confirmText: '退出',
        showCleanSwitch: true,
      );

  static GroupLeaveConfirm dissolveConfirm(String groupName) =>
      GroupLeaveConfirm(
        title: '确认解散',
        content: "确认要解散群聊'$groupName'吗?",
        confirmText: '解散',
        showCleanSwitch: true,
      );

  static String quitSuccessMessage(String groupName) =>
      "您退出了群聊'$groupName'";

  static String dissolveSuccessMessage(String groupName) =>
      "您解散了群聊'$groupName'";

  /// 退群后是否应清本地会话（开关为真时）。
  static bool shouldRemoveLocalChat(bool cleanSwitch) => cleanSwitch;

  static String quitApiPath(int groupId) => '/group/quit/$groupId';

  static String dissolveApiPath(int groupId) => '/group/delete/$groupId';
}

class GroupLeaveConfirm {
  const GroupLeaveConfirm({
    required this.title,
    required this.content,
    required this.confirmText,
    this.showCleanSwitch = false,
  });

  final String title;
  final String content;
  final String confirmText;
  final bool showCleanSwitch;
}

/// 真机双跑验收步骤（写入清单，非运行时）。
abstract final class GroupLeaveDeviceChecks {
  static const quit = [
    '非群主进入群资料 → 退出群聊',
    '确认弹窗含「清除聊天记录」开关且默认开启',
    '确认后回到群列表，会话列表不再显示该群（若勾选清除）',
  ];

  static const dissolve = [
    '群主进入群资料 → 解散群聊',
    '确认文案含群名称，解散后群列表无该群',
    '原成员进入 chat-box 应见「您已不在群聊中」遮罩',
  ];

  static const cleanOnLeave = [
    '退群/解散时关闭「清除聊天记录」→ 会话仍保留但不可发消息',
    '开启开关 → 本地群会话与消息被删除',
  ];
}
