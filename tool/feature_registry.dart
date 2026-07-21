/// IM 功能验收注册表：对照 uniapp，标记自动化与须真人验收项。
///
/// 新增功能时在此登记，并补测试或标 `manualOnly`。
abstract final class FeatureRegistry {
  static List<FeatureSpec> get all => [
        ..._auth,
        ..._shell,
        ..._messagesTab,
        ..._chatBox,
        ..._friend,
        ..._group,
        ..._mine,
        ..._chatAux,
        ..._appCapability,
        ..._outOfScope,
      ];

  static List<FeatureSpec> get p0 =>
      all.where((f) => f.priority == FeaturePriority.p0).toList();

  static List<FeatureSpec> get manualOnly =>
      all.where((f) => f.manualOnly).toList();

  static List<FeatureSpec> get automationGaps => p0
      .where((f) => !f.manualOnly && !f.hasAutomation)
      .toList();

  // ---- 认证 ----
  static const _auth = [
    FeatureSpec(
      id: 'auth.login_password',
      module: '认证',
      title: '手机号/用户名+密码登录',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.apiLive, AutomationKind.widgetContract],
      testFiles: ['test/login_api_test.dart', 'test/m3_auth_mine_test.dart'],
      checklistDoc: 'auth-parity-checklist.md §A',
    ),
    FeatureSpec(
      id: 'auth.token_refresh',
      module: '认证',
      title: '冷启动 refreshToken 保持会话',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.logicUnit, AutomationKind.deviceLog],
      testFiles: ['test/providers_test.dart', 'tool/device_log_audit.ps1'],
      checklistDoc: 'auth-parity-checklist.md §F',
    ),
    FeatureSpec(
      id: 'auth.register_form',
      module: '认证',
      title: '注册表单校验与页面',
      priority: FeaturePriority.p1,
      automation: [AutomationKind.widgetContract],
      testFiles: ['test/m3_auth_mine_test.dart'],
      checklistDoc: 'auth-parity-checklist.md §B',
    ),
    FeatureSpec(
      id: 'auth.reset_password',
      module: '认证',
      title: '找回密码表单',
      priority: FeaturePriority.p1,
      automation: [AutomationKind.widgetContract],
      testFiles: ['test/m3_auth_mine_test.dart'],
      checklistDoc: 'auth-parity-checklist.md §C',
    ),
    FeatureSpec(
      id: 'auth.qr_login_confirm',
      module: '认证',
      title: '扫码登录确认页',
      priority: FeaturePriority.p1,
      automation: [AutomationKind.pageSmoke],
      testFiles: ['test/m3_page_smoke_test.dart'],
      checklistDoc: 'auth-parity-checklist.md §E',
      manualOnly: true,
      manualReason: '需另一设备生成登录二维码并扫码确认',
    ),
    FeatureSpec(
      id: 'auth.remote_kick',
      module: '认证',
      title: '异地登录 WS cmd2 踢下线',
      priority: FeaturePriority.p1,
      automation: const [],
      testFiles: const [],
      checklistDoc: 'auth-parity-checklist.md §F',
      manualOnly: true,
      manualReason: '需双账号或双机同时登录同一账号',
    ),
  ];

  // ---- 主壳 ----
  static const _shell = [
    FeatureSpec(
      id: 'shell.tab_bar',
      module: '主壳',
      title: '3 Tab 切换（消息/通讯录/我的）',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.pageSmoke, AutomationKind.widgetContract],
      testFiles: ['test/m3_page_smoke_test.dart', 'test/m3_shell_ui_test.dart'],
      checklistDoc: 'shell-parity-checklist.md §A',
    ),
    FeatureSpec(
      id: 'shell.line_switch',
      module: '主壳',
      title: '线路切换与探活',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.logicUnit, AutomationKind.apiLive],
      testFiles: ['test/line_switch_test.dart', 'test/line_probe_test.dart'],
      checklistDoc: 'shell-parity-checklist.md §D',
    ),
    FeatureSpec(
      id: 'shell.bootstrap',
      module: '主壳',
      title: '冷启动 bootstrap 进主页',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.logicUnit, AutomationKind.deviceLog],
      testFiles: ['test/providers_test.dart', 'tool/device_log_audit.ps1'],
      checklistDoc: 'shell-parity-checklist.md §G',
    ),
    FeatureSpec(
      id: 'shell.ws_connect',
      module: '主壳',
      title: 'WebSocket 连接与登录',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.deviceLog],
      testFiles: ['tool/device_log_audit.ps1'],
      checklistDoc: 'app-capability-parity-checklist.md §A',
    ),
  ];

  // ---- 消息 Tab ----
  static const _messagesTab = [
    FeatureSpec(
      id: 'messages.list_render',
      module: '消息Tab',
      title: '会话列表渲染（头像/名称/摘要/时间/未读）',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.widgetContract, AutomationKind.logicUnit],
      testFiles: [
        'test/m3_messages_tab_test.dart',
        'test/chat_dao_merge_test.dart',
      ],
      checklistDoc: 'messages-tab-parity-checklist.md §B',
    ),
    FeatureSpec(
      id: 'messages.search_filter',
      module: '消息Tab',
      title: '会话搜索与过滤',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.widgetContract],
      testFiles: ['test/m3_messages_tab_test.dart'],
      checklistDoc: 'messages-tab-parity-checklist.md §C',
    ),
    FeatureSpec(
      id: 'messages.long_press_menu',
      module: '消息Tab',
      title: '长按：置顶/免打扰/删除会话',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.widgetContract],
      testFiles: ['test/m3_messages_tab_test.dart'],
      checklistDoc: 'messages-tab-parity-checklist.md §E',
      manualOnly: true,
      manualReason: '长按手势与删除后列表刷新需真机确认',
    ),
    FeatureSpec(
      id: 'messages.badges',
      module: '消息Tab',
      title: '@我 / 置顶 / 免打扰角标展示',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.widgetContract, AutomationKind.logicUnit],
      testFiles: [
        'test/m3_group_session_test.dart',
        'test/m3_messages_tab_test.dart',
      ],
      checklistDoc: 'messages-tab-parity-checklist.md §D',
    ),
    FeatureSpec(
      id: 'messages.connection_bar',
      module: '消息Tab',
      title: '顶部连接状态条',
      priority: FeaturePriority.p1,
      automation: [AutomationKind.widgetContract],
      testFiles: ['test/m3_messages_tab_test.dart'],
      checklistDoc: 'messages-tab-parity-checklist.md §F',
    ),
    FeatureSpec(
      id: 'messages.tip_sound',
      module: '消息Tab',
      title: '新消息提示音播放',
      priority: FeaturePriority.p1,
      automation: [AutomationKind.logicUnit],
      testFiles: ['test/m3_group_permission_test.dart'],
      checklistDoc: 'messages-tab-parity-checklist.md §H',
      manualOnly: true,
      manualReason: '扬声器出声、勿扰模式需真人听',
    ),
  ];

  // ---- 聊天页 ----
  static const _chatBox = [
    FeatureSpec(
      id: 'chat.text_send',
      module: '聊天页',
      title: '文字发送、失败标记、重发队列',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.logicUnit, AutomationKind.apiLive],
      testFiles: [
        'test/chat_send_test.dart',
        'test/message_send_util_test.dart',
        'test/m3_api_flow_test.dart',
      ],
      checklistDoc: 'chat-box-parity-checklist.md §D',
    ),
    FeatureSpec(
      id: 'chat.tmp_id',
      module: '聊天页',
      title: '临时消息 ID 长度合规（≤32）',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.logicUnit],
      testFiles: ['test/message_tmp_id_test.dart'],
      checklistDoc: 'chat-box-parity-checklist.md §D',
    ),
    FeatureSpec(
      id: 'chat.dispatcher',
      module: '聊天页',
      title: 'WS 消息分发（私聊/群聊/撤回/已读/@）',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.logicUnit],
      testFiles: ['test/message_dispatcher_test.dart'],
      checklistDoc: 'chat-box-parity-checklist.md §J',
    ),
    FeatureSpec(
      id: 'chat.offline_sync',
      module: '聊天页',
      title: '离线消息拉取与合并',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.logicUnit, AutomationKind.apiLive],
      testFiles: [
        'test/offline_sync_test.dart',
        'test/m2_offline_api_test.dart',
        'test/m2_flow_integration_test.dart',
      ],
      checklistDoc: 'chat-box-parity-checklist.md §K',
    ),
    FeatureSpec(
      id: 'chat.read_receipt',
      module: '聊天页',
      title: '私聊已读状态与颜色',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.widgetContract],
      testFiles: ['test/m3_chat_contract_test.dart'],
      checklistDoc: 'chat-box-parity-checklist.md §D',
    ),
    FeatureSpec(
      id: 'chat.quote_at',
      module: '聊天页',
      title: '引用、@成员、表情协议',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.widgetContract],
      testFiles: [
        'test/m3_chat_contract_test.dart',
        'test/m3_uniapp_contract_test.dart',
      ],
      checklistDoc: 'chat-box-parity-checklist.md §G',
    ),
    FeatureSpec(
      id: 'chat.tools_panel',
      module: '聊天页',
      title: '工具栏四列（文件/相册/拍摄/视频）',
      priority: FeaturePriority.p0,
      automation: [
        AutomationKind.widgetContract,
        AutomationKind.layoutScan,
      ],
      testFiles: [
        'test/m3_chat_panel_layout_test.dart',
        'test/parity_layout_scan_test.dart',
      ],
      checklistDoc: 'chat-box-parity-checklist.md §F',
    ),
    FeatureSpec(
      id: 'chat.emotion_panel',
      module: '聊天页',
      title: '表情面板 flex 换行',
      priority: FeaturePriority.p0,
      automation: [
        AutomationKind.widgetContract,
        AutomationKind.layoutScan,
      ],
      testFiles: [
        'test/m3_chat_panel_layout_test.dart',
        'test/parity_layout_scan_test.dart',
      ],
      checklistDoc: 'chat-box-parity-checklist.md §F',
    ),
    FeatureSpec(
      id: 'chat.long_press_menu',
      module: '聊天页',
      title: '消息长按菜单（复制/转发/撤回/删除）',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.widgetContract],
      testFiles: ['test/m3_chat_contract_test.dart'],
      checklistDoc: 'chat-box-parity-checklist.md §H',
      manualOnly: true,
      manualReason: '长按弹出位置、系统剪贴板、撤回时限需真机',
    ),
    FeatureSpec(
      id: 'chat.media_send',
      module: '聊天页',
      title: '图片/文件/语音/视频发送与预览',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.logicUnit],
      testFiles: ['test/file_download_util_test.dart'],
      checklistDoc: 'chat-box-parity-checklist.md §E',
      manualOnly: true,
      manualReason: '相机/相册/麦克风/播放器需真机与权限',
    ),
    FeatureSpec(
      id: 'chat.scroll_highlight',
      module: '聊天页',
      title: '定位引用/@ 消息 2 秒高亮',
      priority: FeaturePriority.p1,
      automation: const [],
      testFiles: const [],
      checklistDoc: 'chat-box-parity-checklist.md §C',
      manualOnly: true,
      manualReason: '滚动动画与高亮时序需肉眼',
    ),
    FeatureSpec(
      id: 'chat.group_top_bar',
      module: '聊天页',
      title: '群置顶消息条',
      priority: FeaturePriority.p1,
      automation: [AutomationKind.widgetContract],
      testFiles: ['test/m3_chat_contract_test.dart'],
      checklistDoc: 'chat-box-parity-checklist.md §I',
    ),
    FeatureSpec(
      id: 'chat.virtual_window',
      module: '聊天页',
      title: '虚拟窗口与历史加载',
      priority: FeaturePriority.p1,
      automation: [AutomationKind.widgetContract],
      testFiles: ['test/m3_chat_contract_test.dart'],
      checklistDoc: 'chat-box-parity-checklist.md §B',
    ),
  ];

  // ---- 好友 ----
  static const _friend = [
    FeatureSpec(
      id: 'friend.list_pinyin',
      module: '通讯录',
      title: '好友列表拼音索引',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.widgetContract, AutomationKind.apiLive],
      testFiles: ['test/m3_friend_test.dart', 'test/m3_api_smoke_test.dart'],
      checklistDoc: 'friend-parity-checklist.md §B',
    ),
    FeatureSpec(
      id: 'friend.add_search',
      module: '通讯录',
      title: '搜索添加好友',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.widgetContract, AutomationKind.apiLive],
      testFiles: ['test/m3_friend_test.dart', 'test/m3_api_smoke_test.dart'],
      checklistDoc: 'friend-parity-checklist.md §D',
    ),
    FeatureSpec(
      id: 'friend.request_flow',
      module: '通讯录',
      title: '好友申请同意/拒绝/撤回',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.pageSmoke],
      testFiles: ['test/m3_page_smoke_test.dart'],
      checklistDoc: 'friend-parity-checklist.md §E',
      manualOnly: true,
      manualReason: '需双账号互发申请并验证 WS 推送与角标',
    ),
    FeatureSpec(
      id: 'friend.user_info',
      module: '通讯录',
      title: '好友资料页（备注/发消息入口）',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.pageSmoke, AutomationKind.widgetContract],
      testFiles: ['test/m3_friend_test.dart', 'test/m3_page_smoke_test.dart'],
      checklistDoc: 'friend-parity-checklist.md §F',
    ),
    FeatureSpec(
      id: 'friend.phone_contact',
      module: '通讯录',
      title: '手机通讯录匹配',
      priority: FeaturePriority.p1,
      automation: [AutomationKind.pageSmoke],
      testFiles: ['test/m3_page_smoke_test.dart'],
      checklistDoc: 'friend-parity-checklist.md §G',
      manualOnly: true,
      manualReason: '需通讯录权限与真实联系人数据',
    ),
  ];

  // ---- 群组 ----
  static const _group = [
    FeatureSpec(
      id: 'group.list_detail',
      module: '群组',
      title: '群列表 / 群资料 / 成员',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.pageSmoke, AutomationKind.apiLive],
      testFiles: ['test/m3_page_smoke_test.dart', 'test/m3_api_smoke_test.dart'],
      checklistDoc: 'group-parity-checklist.md §A-B',
    ),
    FeatureSpec(
      id: 'group.create_edit',
      module: '群组',
      title: '建群 / 改群',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.pageSmoke],
      testFiles: ['test/m3_page_smoke_test.dart'],
      checklistDoc: 'group-parity-checklist.md §C',
      manualOnly: true,
      manualReason: '建群后成员可见性与头像上传需真机',
    ),
    FeatureSpec(
      id: 'group.invite',
      module: '群组',
      title: '邀请成员',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.pageSmoke, AutomationKind.widgetContract],
      testFiles: [
        'test/group_invite_page_test.dart',
        'test/m3_page_smoke_test.dart',
      ],
      checklistDoc: 'group-parity-checklist.md §D',
    ),
    FeatureSpec(
      id: 'group.permissions',
      module: '群组',
      title: '管理员/禁言/邀请权限',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.logicUnit, AutomationKind.widgetContract],
      testFiles: ['test/m3_group_permission_test.dart'],
      checklistDoc: 'group-parity-checklist.md §E',
    ),
    FeatureSpec(
      id: 'group.leave_dissolve',
      module: '群组',
      title: '退群 / 解散群',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.logicUnit],
      testFiles: ['test/m3_group_leave_test.dart'],
      checklistDoc: 'group-parity-checklist.md §G',
      manualOnly: true,
      manualReason: '退群/解散后会话列表变化需真机确认',
    ),
    FeatureSpec(
      id: 'group.qrcode',
      module: '群组',
      title: '群二维码',
      priority: FeaturePriority.p1,
      automation: [AutomationKind.pageSmoke],
      testFiles: ['test/m3_page_smoke_test.dart'],
      checklistDoc: 'group-parity-checklist.md §F',
      manualOnly: true,
      manualReason: '扫码入群需另一设备扫二维码',
    ),
  ];

  // ---- 我的 ----
  static const _mine = [
    FeatureSpec(
      id: 'mine.profile',
      module: '我的',
      title: '个人资料卡与编辑',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.pageSmoke, AutomationKind.widgetContract],
      testFiles: ['test/m3_auth_mine_test.dart', 'test/m3_page_smoke_test.dart'],
      checklistDoc: 'mine-parity-checklist.md §A-B',
    ),
    FeatureSpec(
      id: 'mine.password',
      module: '我的',
      title: '修改密码表单',
      priority: FeaturePriority.p1,
      automation: [AutomationKind.pageSmoke],
      testFiles: ['test/m3_page_smoke_test.dart'],
      checklistDoc: 'mine-parity-checklist.md §C',
      manualOnly: true,
      manualReason: '改密后重新登录需真人验证',
    ),
    FeatureSpec(
      id: 'mine.bind_phone_email',
      module: '我的',
      title: '绑定手机/邮箱（验证码）',
      priority: FeaturePriority.p1,
      automation: [AutomationKind.logicUnit, AutomationKind.pageSmoke],
      testFiles: ['test/m3_mine_util_test.dart', 'test/m3_page_smoke_test.dart'],
      checklistDoc: 'mine-parity-checklist.md §D',
      manualOnly: true,
      manualReason: '短信/邮件验证码需真实通道',
    ),
    FeatureSpec(
      id: 'mine.settings',
      module: '我的',
      title: '设置开关（好友验证/提示音）',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.pageSmoke],
      testFiles: ['test/m3_page_smoke_test.dart'],
      checklistDoc: 'mine-parity-checklist.md §E',
    ),
    FeatureSpec(
      id: 'mine.teenager',
      module: '我的',
      title: '青少年模式 PIN',
      priority: FeaturePriority.p1,
      automation: [AutomationKind.logicUnit, AutomationKind.pageSmoke],
      testFiles: ['test/m3_mine_util_test.dart', 'test/m3_page_smoke_test.dart'],
      checklistDoc: 'mine-parity-checklist.md §F',
    ),
    FeatureSpec(
      id: 'mine.qrcode',
      module: '我的',
      title: '个人二维码',
      priority: FeaturePriority.p1,
      automation: [AutomationKind.pageSmoke],
      testFiles: ['test/m3_page_smoke_test.dart'],
      checklistDoc: 'mine-parity-checklist.md §G',
      manualOnly: true,
      manualReason: '他人扫码加好友需双机',
    ),
  ];

  // ---- 聊天辅助 ----
  static const _chatAux = [
    FeatureSpec(
      id: 'aux.system_message',
      module: '聊天辅助',
      title: '系统通知列表与详情',
      priority: FeaturePriority.p1,
      automation: [AutomationKind.pageSmoke, AutomationKind.logicUnit],
      testFiles: [
        'test/m3_page_smoke_test.dart',
        'test/system_message_json_test.dart',
      ],
      checklistDoc: 'chat-aux-parity-checklist.md §A',
    ),
    FeatureSpec(
      id: 'aux.chat_history',
      module: '聊天辅助',
      title: '聊天记录搜索/图片/文件子页',
      priority: FeaturePriority.p1,
      automation: [AutomationKind.pageSmoke],
      testFiles: ['test/m3_page_smoke_test.dart'],
      checklistDoc: 'chat-aux-parity-checklist.md §B-D',
    ),
    FeatureSpec(
      id: 'aux.scan_routing',
      module: '聊天辅助',
      title: '扫一扫（用户/群/登录码）',
      priority: FeaturePriority.p1,
      automation: [AutomationKind.logicUnit],
      testFiles: ['test/m3_group_session_test.dart'],
      checklistDoc: 'chat-aux-parity-checklist.md §E',
      manualOnly: true,
      manualReason: '需摄像头扫真实二维码',
    ),
    FeatureSpec(
      id: 'aux.rtc_private',
      module: '聊天辅助',
      title: '单聊语音/视频 RTC',
      priority: FeaturePriority.p0,
      automation: const [],
      testFiles: const [],
      checklistDoc: 'chat-aux-parity-checklist.md §G',
      manualOnly: true,
      manualReason: '双机呼叫接听挂断、权限、悬浮窗',
    ),
    FeatureSpec(
      id: 'aux.rtc_group',
      module: '聊天辅助',
      title: '群聊 RTC 邀请/加入',
      priority: FeaturePriority.p0,
      automation: const [],
      testFiles: const [],
      checklistDoc: 'chat-aux-parity-checklist.md §H',
      manualOnly: true,
      manualReason: '多机群 RTC、信令时序需双机以上',
    ),
  ];

  // ---- App 能力 ----
  static const _appCapability = [
    FeatureSpec(
      id: 'app.badge_tab',
      module: 'App能力',
      title: 'Tab 角标（未读/好友申请）',
      priority: FeaturePriority.p1,
      automation: [AutomationKind.logicUnit],
      testFiles: ['test/m3_group_session_test.dart'],
      checklistDoc: 'app-capability-parity-checklist.md §B',
      manualOnly: true,
      manualReason: '角标数字与红点位置需肉眼',
    ),
    FeatureSpec(
      id: 'app.badge_desktop',
      module: 'App能力',
      title: '桌面角标（Android）',
      priority: FeaturePriority.p2,
      automation: const [],
      testFiles: const [],
      checklistDoc: 'app-capability-parity-checklist.md §B',
      manualOnly: true,
      manualReason: 'launcher 角标因厂商而异',
    ),
    FeatureSpec(
      id: 'app.ws_reconnect',
      module: 'App能力',
      title: '断网恢复 WS 重连与消息补齐',
      priority: FeaturePriority.p0,
      automation: [AutomationKind.logicUnit],
      testFiles: ['test/offline_sync_test.dart', 'test/message_dispatcher_test.dart'],
      checklistDoc: 'app-capability-parity-checklist.md §A',
      manualOnly: true,
      manualReason: '飞行模式/弱网切换需真机网络操作',
    ),
    FeatureSpec(
      id: 'app.data_collect',
      module: 'App能力',
      title: '数据采集 cmd55/56/57',
      priority: FeaturePriority.p2,
      automation: const [],
      testFiles: const [],
      checklistDoc: 'app-capability-parity-checklist.md §F',
      manualOnly: true,
      manualReason: 'Android 权限弹窗与后台采集需真机',
    ),
  ];

  // ---- 范围外 ----
  static const _outOfScope = [
    FeatureSpec(
      id: 'scope.financial',
      module: '范围外',
      title: '金融 service/loan 全流程',
      priority: FeaturePriority.outOfScope,
      automation: const [],
      testFiles: const [],
      checklistDoc: 'parity-checklists-index.md',
    ),
    FeatureSpec(
      id: 'scope.complaint',
      module: '范围外',
      title: '投诉模块',
      priority: FeaturePriority.outOfScope,
      automation: const [],
      testFiles: const [],
    ),
  ];
}

enum FeaturePriority { p0, p1, p2, outOfScope }

enum AutomationKind {
  logicUnit,
  widgetContract,
  pageSmoke,
  apiLive,
  layoutScan,
  deviceLog,
}

class FeatureSpec {
  const FeatureSpec({
    required this.id,
    required this.module,
    required this.title,
    required this.priority,
    required this.automation,
    required this.testFiles,
    this.checklistDoc,
    this.manualOnly = false,
    this.manualReason,
  });

  final String id;
  final String module;
  final String title;
  final FeaturePriority priority;
  final List<AutomationKind> automation;
  final List<String> testFiles;
  final String? checklistDoc;
  final bool manualOnly;
  final String? manualReason;

  bool get hasAutomation => automation.isNotEmpty;

  /// P0 须至少有自动化或已登记真人验收。
  bool get isAcceptanceReady =>
      priority != FeaturePriority.p0 ||
      manualOnly ||
      hasAutomation;
}
