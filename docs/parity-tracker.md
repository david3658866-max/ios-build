# M1 复刻进度对照表



> 与 [m1-audit.md](./m1-audit.md) 配套。状态：✅ 已完成 · 🟡 基本完成/待验收 · ⬜ 未做



| ID | 页面/模块 | uniapp 来源 | Flutter | 状态 |

|----|-----------|-------------|---------|------|

| M1-01 | 设计系统 auth | auth-page.scss | AuthColors + AuthHero/Sheet/Field/GradientButton | ✅ |

| M1-02 | 登录页 | login.vue | login_page.dart | ✅ 已验收登录 |

| M1-03 | 注册页 | register.vue | register_page.dart | ✅ |

| M1-04 | 找回密码 | reset-pwd.vue | reset_pwd_page.dart | ✅ 代码对齐（跳过真机） |

| M1-05 | 扫码确认 | qr-login-confirm.vue | qr_login_confirm_page.dart | ✅ 代码对齐（跳过真机） |

| M1-06 | 启动链路 | App.vue bootstrap | splash + AuthController | ✅ refreshToken |

| M1-07 | 主框架 Tab | pages.json tabBar | main_shell + ImTabBar | ✅ |

| M1-08 | 消息 Tab 壳 | chat.vue 结构 | messages_tab.dart | ✅ 空状态+nav |

| M1-09 | 通讯录 Tab 壳 | friend.vue 结构 | contacts_tab.dart | ✅ 空状态+nav |

| M1-10 | 我的 Tab 壳 | mine.vue 结构 | mine_tab.dart | ✅ |

| M1-11 | 线路探活 | line-manager.js | LineNotifier.checkCurrentLineStatus | ✅ |

| M1-12 | HTTP 契约 | request.js | dio_client + token_interceptor | ✅ 登录+探活已测 |

| M1-13 | 工作法规则 | — | .cursor/rules/im-flutter-parity.mdc | ✅ |



## M1 出口（✅ 已收口，进入 M2）



1. 登录/注册/找回/扫码页 UI 与 uniapp 高度接近

2. 登录闭环集成测试通过（15222222222）

3. `flutter analyze` 0 error

4. login / line_probe / chat_store 单测通过



## M2 进度



| ID | 模块 | 状态 |

|----|------|------|

| M2-1 | chatStore + ChatDao/MessageDao | ✅ |

| M2-2 | MessageDispatcher cmd3/4/5 | ✅ 骨架 |

| M2-5a | 离线会话摘要 + WS 挂钩 | ✅ |

| M2-3 | 会话列表页 | ✅ messages_tab + chat_item |

| M2-4 | chat-box 文字消息 | ✅ UI+私聊/群聊发送+上拉历史+会话内已读 |

| M2-5b | 进会话补离线 | ✅ pullChatOffline |

| M2-6 | dispatcher 回放测试 | ✅ |

## M2 出口

自动化 **27/27 通过** ✅ · 双跑对照见 [m2-acceptance-checklist.md](./m2-acceptance-checklist.md)（B–G 待手动验收）

并行 side 任务见 [parallel-work.md](./parallel-work.md)



详见 [task-breakdown.md](./task-breakdown.md)

## M3 / M4 / M5 进度（F-3 UI 收口）

| ID | 模块 | 状态 |
|----|------|------|
| M3 页面与逻辑 | 群组/好友/我的/聊天/系统通知/历史搜索 | 🟡 代码完成，待真机勾选 |
| M3 F-3 chat-box | locate-tip、@预览条、refreshAtMessage、群标题人数 | ✅ |
| M3 F-3 群组子页 | edit/setting/manager/member/qrcode UI | ✅ |
| M3 F-3 会话列表 | messages_tab + chat_item token | ✅ |
| M3 F-3 我的缺页 | 绑定邮箱、青少年模式 | ✅ |
| M3 F-3 通讯录/我的/群信息 | contacts_tab、mine_tab、group_info UI | ✅ |
| M3 F-3 历史/系统 | chat_history*、chat_system、friend_top_item | ✅ |
| M3 P0 | 新消息提示音、消息定位高亮 2s | ✅ |
| F-3 走查清单 | [m3-device-checklist.md](./m3-device-checklist.md) | ✅ |
| M4 音视频 | RTC 私聊/群、信令桥、通话记录 | ✅ |
| M5 F-1 | 角标 bindBadgeAutoRefresh + Tab 刷新 | ✅ 代码就绪 |
| M5 F-2 | 数据采集 cmd55/56/57 + Android 权限 | ✅ 代码就绪 |

## 验收

- `flutter analyze` 0 error
- `flutter test` **36/36** 通过
- 真机安装：`flutter build apk --debug` + `adb install -r`

