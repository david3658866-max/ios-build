# 功能验收矩阵（自动生成）

> 总功能 **57** · P0 **34** · 须真人 **22**
> 生成：`dart run tool/generate_acceptance_report.dart`

## 四层自动化

| 层 | 覆盖 | 命令 |
|----|------|------|
| L1 逻辑/Store | WS 分发、离线、发送队列、鉴权 | `flutter test test/*_test.dart` |
| L2 Widget 契约 | 页面组件行为、路由不串页 | `flutter test test/m3_*_test.dart` |
| L3 API 真链路 | 登录、发送、只读 GET | `flutter test test/m3_api_* test/m4_api_*` |
| L4 真机日志 | bootstrap、token、WS | `tool/quick_device_verify.ps1` |

**一键主机**：`powershell -File tool/run_host_verify.ps1`

## 按模块

| 模块 | 功能 | 优先级 | 自动化 | 真人 |
|------|------|--------|--------|------|
| App能力 | Tab 角标（未读/好友申请） | P1 | logicUnit | ✅须测 |
| App能力 | 桌面角标（Android） | P2 | — | ✅须测 |
| App能力 | 断网恢复 WS 重连与消息补齐 | P0 | logicUnit | ✅须测 |
| App能力 | 数据采集 cmd55/56/57 | P2 | — | ✅须测 |
| 主壳 | 3 Tab 切换（消息/通讯录/我的） | P0 | pageSmoke+widgetContract | — |
| 主壳 | 线路切换与探活 | P0 | logicUnit+apiLive | — |
| 主壳 | 冷启动 bootstrap 进主页 | P0 | logicUnit+deviceLog | — |
| 主壳 | WebSocket 连接与登录 | P0 | deviceLog | — |
| 我的 | 个人资料卡与编辑 | P0 | pageSmoke+widgetContract | — |
| 我的 | 修改密码表单 | P1 | pageSmoke | ✅须测 |
| 我的 | 绑定手机/邮箱（验证码） | P1 | logicUnit+pageSmoke | ✅须测 |
| 我的 | 设置开关（好友验证/提示音） | P0 | pageSmoke | — |
| 我的 | 青少年模式 PIN | P1 | logicUnit+pageSmoke | — |
| 我的 | 个人二维码 | P1 | pageSmoke | ✅须测 |
| 消息Tab | 会话列表渲染（头像/名称/摘要/时间/未读） | P0 | widgetContract+logicUnit | — |
| 消息Tab | 会话搜索与过滤 | P0 | widgetContract | — |
| 消息Tab | 长按：置顶/免打扰/删除会话 | P0 | widgetContract | ✅须测 |
| 消息Tab | @我 / 置顶 / 免打扰角标展示 | P0 | widgetContract+logicUnit | — |
| 消息Tab | 顶部连接状态条 | P1 | widgetContract | — |
| 消息Tab | 新消息提示音播放 | P1 | logicUnit | ✅须测 |
| 群组 | 群列表 / 群资料 / 成员 | P0 | pageSmoke+apiLive | — |
| 群组 | 建群 / 改群 | P0 | pageSmoke | ✅须测 |
| 群组 | 邀请成员 | P0 | pageSmoke+widgetContract | — |
| 群组 | 管理员/禁言/邀请权限 | P0 | logicUnit+widgetContract | — |
| 群组 | 退群 / 解散群 | P0 | logicUnit | ✅须测 |
| 群组 | 群二维码 | P1 | pageSmoke | ✅须测 |
| 聊天辅助 | 系统通知列表与详情 | P1 | pageSmoke+logicUnit | — |
| 聊天辅助 | 聊天记录搜索/图片/文件子页 | P1 | pageSmoke | — |
| 聊天辅助 | 扫一扫（用户/群/登录码） | P1 | logicUnit | ✅须测 |
| 聊天辅助 | 单聊语音/视频 RTC | P0 | — | ✅须测 |
| 聊天辅助 | 群聊 RTC 邀请/加入 | P0 | — | ✅须测 |
| 聊天页 | 文字发送、失败标记、重发队列 | P0 | logicUnit+apiLive | — |
| 聊天页 | 临时消息 ID 长度合规（≤32） | P0 | logicUnit | — |
| 聊天页 | WS 消息分发（私聊/群聊/撤回/已读/@） | P0 | logicUnit | — |
| 聊天页 | 离线消息拉取与合并 | P0 | logicUnit+apiLive | — |
| 聊天页 | 私聊已读状态与颜色 | P0 | widgetContract | — |
| 聊天页 | 引用、@成员、表情协议 | P0 | widgetContract | — |
| 聊天页 | 工具栏四列（文件/相册/拍摄/视频） | P0 | widgetContract+layoutScan | — |
| 聊天页 | 表情面板 flex 换行 | P0 | widgetContract+layoutScan | — |
| 聊天页 | 消息长按菜单（复制/转发/撤回/删除） | P0 | widgetContract | ✅须测 |
| 聊天页 | 图片/文件/语音/视频发送与预览 | P0 | logicUnit | ✅须测 |
| 聊天页 | 定位引用/@ 消息 2 秒高亮 | P1 | — | ✅须测 |
| 聊天页 | 群置顶消息条 | P1 | widgetContract | — |
| 聊天页 | 虚拟窗口与历史加载 | P1 | widgetContract | — |
| 认证 | 手机号/用户名+密码登录 | P0 | apiLive+widgetContract | — |
| 认证 | 冷启动 refreshToken 保持会话 | P0 | logicUnit+deviceLog | — |
| 认证 | 注册表单校验与页面 | P1 | widgetContract | — |
| 认证 | 找回密码表单 | P1 | widgetContract | — |
| 认证 | 扫码登录确认页 | P1 | pageSmoke | ✅须测 |
| 认证 | 异地登录 WS cmd2 踢下线 | P1 | — | ✅须测 |
| 通讯录 | 好友列表拼音索引 | P0 | widgetContract+apiLive | — |
| 通讯录 | 搜索添加好友 | P0 | widgetContract+apiLive | — |
| 通讯录 | 好友申请同意/拒绝/撤回 | P0 | pageSmoke | ✅须测 |
| 通讯录 | 好友资料页（备注/发消息入口） | P0 | pageSmoke+widgetContract | — |
| 通讯录 | 手机通讯录匹配 | P1 | pageSmoke | ✅须测 |

## 真人清单入口

- [human-only-acceptance.md](./human-only-acceptance.md) — 仅列须真人项
- [m3-device-checklist.md](./m3-device-checklist.md) — 真机双跑 10 章（含细项链接）
- [parity-checklists-index.md](./parity-checklists-index.md) — 300+ 细项对照
