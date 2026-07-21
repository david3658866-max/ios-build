# 须真人验收清单（自动生成）

> 由 `dart run tool/generate_acceptance_report.dart` 从 `tool/feature_registry.dart` 生成。
> 测试账号：`15222222222` / `123456` · 对照同账号 im-uniapp 真机

下列项 **自动化无法替代**（权限、双机、感官、网络切换等）。验收时逐项勾选 Flutter 列。

---

## 1. App能力

- [ ] **Tab 角标（未读/好友申请）** (P1+)
  - 原因：角标数字与红点位置需肉眼
  - 细项：app-capability-parity-checklist.md §B

- [ ] **桌面角标（Android）** (P1+)
  - 原因：launcher 角标因厂商而异
  - 细项：app-capability-parity-checklist.md §B

- [ ] **断网恢复 WS 重连与消息补齐** (**P0**)
  - 原因：飞行模式/弱网切换需真机网络操作
  - 细项：app-capability-parity-checklist.md §A

- [ ] **数据采集 cmd55/56/57** (P1+)
  - 原因：Android 权限弹窗与后台采集需真机
  - 细项：app-capability-parity-checklist.md §F

## 2. 我的

- [ ] **修改密码表单** (P1+)
  - 原因：改密后重新登录需真人验证
  - 细项：mine-parity-checklist.md §C

- [ ] **绑定手机/邮箱（验证码）** (P1+)
  - 原因：短信/邮件验证码需真实通道
  - 细项：mine-parity-checklist.md §D

- [ ] **个人二维码** (P1+)
  - 原因：他人扫码加好友需双机
  - 细项：mine-parity-checklist.md §G

## 3. 消息Tab

- [ ] **长按：置顶/免打扰/删除会话** (**P0**)
  - 原因：长按手势与删除后列表刷新需真机确认
  - 细项：messages-tab-parity-checklist.md §E

- [ ] **新消息提示音播放** (P1+)
  - 原因：扬声器出声、勿扰模式需真人听
  - 细项：messages-tab-parity-checklist.md §H

## 4. 群组

- [ ] **建群 / 改群** (**P0**)
  - 原因：建群后成员可见性与头像上传需真机
  - 细项：group-parity-checklist.md §C

- [ ] **退群 / 解散群** (**P0**)
  - 原因：退群/解散后会话列表变化需真机确认
  - 细项：group-parity-checklist.md §G

- [ ] **群二维码** (P1+)
  - 原因：扫码入群需另一设备扫二维码
  - 细项：group-parity-checklist.md §F

## 5. 聊天辅助

- [ ] **扫一扫（用户/群/登录码）** (P1+)
  - 原因：需摄像头扫真实二维码
  - 细项：chat-aux-parity-checklist.md §E

- [ ] **单聊语音/视频 RTC** (**P0**)
  - 原因：双机呼叫接听挂断、权限、悬浮窗
  - 细项：chat-aux-parity-checklist.md §G

- [ ] **群聊 RTC 邀请/加入** (**P0**)
  - 原因：多机群 RTC、信令时序需双机以上
  - 细项：chat-aux-parity-checklist.md §H

## 6. 聊天页

- [ ] **消息长按菜单（复制/转发/撤回/删除）** (**P0**)
  - 原因：长按弹出位置、系统剪贴板、撤回时限需真机
  - 细项：chat-box-parity-checklist.md §H

- [ ] **图片/文件/语音/视频发送与预览** (**P0**)
  - 原因：相机/相册/麦克风/播放器需真机与权限
  - 细项：chat-box-parity-checklist.md §E

- [ ] **定位引用/@ 消息 2 秒高亮** (P1+)
  - 原因：滚动动画与高亮时序需肉眼
  - 细项：chat-box-parity-checklist.md §C

## 7. 认证

- [ ] **扫码登录确认页** (P1+)
  - 原因：需另一设备生成登录二维码并扫码确认
  - 细项：auth-parity-checklist.md §E

- [ ] **异地登录 WS cmd2 踢下线** (P1+)
  - 原因：需双账号或双机同时登录同一账号
  - 细项：auth-parity-checklist.md §F

## 8. 通讯录

- [ ] **好友申请同意/拒绝/撤回** (**P0**)
  - 原因：需双账号互发申请并验证 WS 推送与角标
  - 细项：friend-parity-checklist.md §E

- [ ] **手机通讯录匹配** (P1+)
  - 原因：需通讯录权限与真实联系人数据
  - 细项：friend-parity-checklist.md §G

---

## 问题记录

| 功能 | 现象 | 截图/备注 |
|------|------|-----------|
|      |      |           |
