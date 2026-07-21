# 真机统一验收清单

> 测试账号：`15222222222` / `123456` · 线路 **line1（kivola）**  
> 安装：`build/app/outputs/flutter-apk/app-debug.apk`  
> 对照：同账号 im-uniapp 真机

勾选 **Flutter** 列即可；与 uniapp 明显不一致记备注。

---

## 1. 登录 / 启动

> **细项对照**：[auth-parity-checklist.md](./auth-parity-checklist.md)（A–F）、[shell-parity-checklist.md](./shell-parity-checklist.md)（A–G）  
> **总索引**：[parity-checklists-index.md](./parity-checklists-index.md)

- [ ] 手机号+密码登录成功
- [ ] 线路切换器显示与探活状态
- [ ] 杀进程重启仍保持登录（refreshToken）
- [ ] 异地登录踢下线（cmd2，可选双机）

## 2. 消息 Tab

> **细项对照**：[messages-tab-parity-checklist.md](./messages-tab-parity-checklist.md)（A–I）

- [ ] 会话列表：头像/名称/摘要/时间/未读
- [ ] @我 / 置顶 / 免打扰展示
- [ ] 长按：置顶、免打扰、删除会话
- [ ] 顶部连接状态条
- [ ] 新消息提示音（设置里开启后）

## 3. 聊天页 chat-box

> **细项对照**（推荐开发时逐项打勾）：[chat-box-parity-checklist.md](./chat-box-parity-checklist.md)（A–L 共 70+ 检查点，含 ✅/🟡/⬜ 状态）

- [ ] 文字收发、失败重发、已读状态
- [ ] 图片 / 文件 / 语音 / 视频
- [ ] 引用、@、表情、长按菜单
- [ ] 回到底部 / N条新消息 / 有人@我
- [ ] 定位引用或 @ 消息时 **2 秒高亮**
- [ ] 群标题显示人数 `群名(N)`
- [ ] 群置顶消息条
- [ ] 上拉历史、进会话补离线

## 4. 通讯录

> **细项对照**：[friend-parity-checklist.md](./friend-parity-checklist.md)（A–K）

- [ ] 好友列表拼音索引、在线绿点
- [ ] 新的朋友 / 群聊入口样式
- [ ] 添加好友、申请同意/拒绝
- [ ] 好友资料、备注、发消息

## 5. 群组

> **细项对照**：[group-parity-checklist.md](./group-parity-checklist.md)（A–I）

- [ ] 群资料页：成员格、公告、操作按钮
- [ ] 建群/改群、邀请、成员管理
- [ ] 群设置、管理员、二维码
- [ ] 退群 / 加入群聊

## 6. 我的

> **细项对照**：[mine-parity-checklist.md](./mine-parity-checklist.md)（A–I）

- [ ] 头部渐变卡、菜单分组
- [ ] 资料编辑、改密
- [ ] 绑定手机 / 绑定邮箱
- [ ] 青少年模式 PIN
- [ ] 设置开关、关于、个人二维码

## 7. 系统通知 & 记录

> **细项对照**：[chat-aux-parity-checklist.md](./chat-aux-parity-checklist.md)（A–J）

- [ ] 系统消息列表与详情
- [ ] 聊天记录搜索 / 图片 / 文件子页

## 8. 音视频（双机）

> **细项对照**：[chat-aux-parity-checklist.md](./chat-aux-parity-checklist.md) §G–H

- [ ] 单聊语音/视频呼叫与接听
- [ ] 群聊 RTC 邀请/加入
- [ ] 挂断后会话出现通话记录消息

## 9. App 能力

> **细项对照**：[app-capability-parity-checklist.md](./app-capability-parity-checklist.md)（A–I）

- [ ] Tab 角标（消息未读、好友申请）
- [ ] 桌面角标（Android）
- [ ] 断网恢复后 WS 重连、消息补齐
- [ ] 数据采集 cmd55/56（Android 权限弹窗，可选）

## 10. 已知占位（不测 bug）

- 金融卡片 type 7/8/9 →「功能开发中」
- 投诉 / 贷款 service 页面 → 范围外
- 保活 / 版本升级 → 代码默认关闭

---

## 自动化已覆盖（脚本/主机测试，无需手勾）

| 项 | 命令 | 状态 |
|----|------|------|
| 冷启动 → 进主页（bootstrap） | `tool/device_log_audit.ps1` | ✅ 日志 `bootstrap done -> main` |
| refreshToken 冷启动 | 同上 | ✅ 日志 `token refreshed` |
| WS 登录 | 同上 | ✅ `WS login success` |
| 群聊/私聊 API 发送 | `dart run tool/probe_group_send.dart` | ✅ 全 200 |
| 主机单元+契约测试 | `flutter test` | ✅ 257 项 |
| 白屏启动 | 已修复（bootstrap 双触发+超时） | ✅ 真机确认 |

本地调试运行：`powershell -File scripts/run-device.ps1 -DeviceId <设备ID>`（会先恢复 `adb reverse`，含媒体端口 `9001`）  
一键真机验收：`powershell -File tool/quick_device_verify.ps1 -SkipBuild`  
一键主机：`powershell -File tool/run_host_verify.ps1`（含功能注册表 + 全量测试 + API 探测）  
说明：[parity-automation.md](./parity-automation.md) · **你只须手测**：[human-only-acceptance.md](./human-only-acceptance.md)（自动生成）

**仍须你手测**：见 [human-only-acceptance.md](./human-only-acceptance.md)（RTC、媒体、长按、双机、角标肉眼等，约 20 项）。

---

## 问题记录模板

| 页面 | 现象 | 截图/备注 |
|------|------|-----------|
|      |      |           |
