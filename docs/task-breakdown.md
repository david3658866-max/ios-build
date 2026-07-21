# im-flutter 任务拆分文档（含并行与防冲突规则）

> 配套：`development-plan.md`（里程碑）、`architecture.md`（目录/模块）、`coding-conventions.md`（规范）。
> 本文档把里程碑拆成**可独立分配给子 agent 的任务卡**，并通过**文件所有权边界**从机制上避免并行冲突。

---

## 0. 并行与防冲突的核心机制

### 机制 1：契约先行（M0 产出，全程冻结）
M0 阶段先把以下"契约"定稿并冻结，之后并行 agent **只实现、不改签名**：
- `models/*`：所有数据模型字段
- `api/*_api.dart`：所有 REST 接口方法签名
- `stores/*`：各 Provider 对外暴露的方法签名
- `core/enums/*`：枚举值
- drift 表结构

> 改契约必须经"主 agent"统一修改并通知，禁止并行 agent 私改。

### 机制 2：文件所有权（同一时刻一个文件只属于一个任务）
每张任务卡声明 **独占目录/文件**；并行批次内**任务的文件集合互不相交**。共享文件（如路由表、pubspec、数据库聚合）只由"主 agent"在合并点统一改。

### 机制 3：分批并行（批次内并行，批次间串行）
只有同批次任务文件不相交时才并行；有依赖的放下一批。

### 机制 4：git 分支
每张任务卡一个 feature 分支 `feat/<task-id>`，完成后合并到 `develop`，主 agent 负责合并与冲突裁决。

---

## 1. 阶段 A：M0 地基（单 agent 串行，禁止并行）

> 地基是所有功能的根，必须一个 agent 焊死，产出"契约"。

| 任务ID | 内容 | 独占文件 | 验收 |
|---|---|---|---|
| M0-1 | 工程初始化、pubspec、主题、go_router 骨架 | `pubspec.yaml` `lib/main.dart` `lib/app.dart` `lib/router/` | 双端可运行 |
| M0-2 | 环境配置 + 多线路 | `lib/core/config/` `lib/core/line/` | 线路切换可用 |
| M0-3 | 枚举（message_type/status/cmd） | `lib/core/enums/` | 与后端一致 |
| M0-4 | Dio + token 单飞刷新 + ApiResult | `lib/core/http/` | 401 单飞重放正确 |
| M0-5 | WsManager（cmd0/1、重连、连接代次） | `lib/core/ws/` | 连测试服握手成功 |
| M0-6 | drift 建库 + 表 + DAO + Hive | `lib/core/storage/` | 建表读写成功 |
| M0-7 | **数据模型定稿**（契约） | `lib/models/` | 覆盖 ref ④ 全部 VO/DTO |
| M0-8 | **API 接口签名定稿**（契约） | `lib/api/` | 覆盖 ref ③⑤ 全部接口 |
| M0-9 | **stores 骨架 + 方法签名**（契约） | `lib/stores/` | 6 个 Provider 签名齐全 |
| M0-10 | 工具集 date/str/avatar/emotion | `lib/core/utils/` | 单测通过 |

**M0 出口**：契约冻结 + WS/HTTP/DB 跑通 → 用户验收 → 才可进入并行阶段。

---

## 2. 阶段 B：M1 登录（单 agent，依赖 M0）

| 任务ID | 内容 | 独占文件 |
|---|---|---|
| M1-1 | 登录页（账号/手机/邮箱、线路切换、验证码） | `lib/pages/login/` |
| M1-2 | 注册 + 找回密码 + 扫码确认 | `lib/pages/register/` `lib/pages/login/qr_*` |
| M1-3 | 启动链路 app_bootstrap | `lib/services/app_bootstrap.dart` |
| M1-4 | 主框架(三 Tab 骨架) | `lib/pages/main_shell.dart` |

---

## 3. 阶段 C：M2 会话+文字 MVP（单 agent，核心，禁止并行）

> chatStore + dispatcher 是最易出 bug 的核心，单一 owner 负责。

| 任务ID | 内容 | 独占文件 |
|---|---|---|
| M2-1 | chatStore（drift 实现）会话/消息分页/插入/撤回/已读 | `lib/stores/chat_store.dart` `lib/core/storage/daos/` |
| M2-2 | MessageDispatcher 分发骨架(cmd3/4/5 入库) | `lib/services/message_dispatcher.dart` |
| M2-3 | 会话列表页 | `lib/pages/chat/chat_list_page.dart` `lib/widgets/chat/chat_item.dart` |
| M2-4 | chat-box 第一批(文字/状态机/分页/时间分隔) | `lib/pages/chat/chat_box_page.dart` `lib/widgets/chat/bubbles/text_bubble.dart` |
| M2-5 | 离线摘要+按会话补离线 | `lib/services/offline_sync.dart` |
| M2-6 | 回放测试(dispatcher/chatStore) | `test/` |

**M2 出口**：用户双跑对照通过 → 才可进入 M3 并行。

---

## 4. 阶段 D：M3 功能完整化（**并行批次**）

> 所有批次都依赖 M0 契约 + M2 核心。批次内文件不相交，可分配给不同子 agent。

### 批次 D1（4 个 agent 并行）

| 任务ID | Agent | 内容 | 独占文件（不相交） |
|---|---|---|---|
| D1-A | agent-friend | 好友模块：列表/添加/申请/备注/资料/通讯录 | `lib/pages/friend/` `lib/stores/friend_store.dart` `lib/widgets/friend/` |
| D1-B | agent-group | 群组模块：列表/群信息/建改群/成员/二维码/设置/管理员 | `lib/pages/group/` `lib/stores/group_store.dart` `lib/widgets/group/` |
| D1-C | agent-mine | 我的模块：资料/改密/设置/绑定/二维码/实名/关于 | `lib/pages/mine/` |
| D1-D | agent-bubbles | chat-box 第二批气泡：图片/文件/语音/视频/名片 | `lib/widgets/chat/bubbles/` (除 text_bubble) |

### 批次 D2（依赖 D1-D 气泡，2 个 agent 并行）

| 任务ID | Agent | 内容 | 独占文件 |
|---|---|---|---|
| D2-A | agent-chat-adv | chat-box 高级交互：引用/@/长按菜单/转发/表情面板 | `lib/pages/chat/chat_box_page.dart`(由 M2 owner 或顺延) `lib/widgets/chat/at_*`、`quote_*`、`menu_*`、`emotion_*` |
| D2-B | agent-system | 系统通知页 + 聊天记录查询页 | `lib/pages/chat/system_*` `lib/pages/chat/history_*` |

> 注意：`chat_box_page.dart` 是热点文件，D2-A 若需改它，应由 M2 的 chat owner 串行接力，不与 D1-D 同时改。

### 批次 D3（上传服务，1 个 agent，D1-D 并行可用）

| 任务ID | 内容 | 独占文件 |
|---|---|---|
| D3-1 | upload_service：图片/文件/视频上传 + 文件下载 | `lib/services/upload_service.dart` |

---

## 5. 阶段 E：M4 音视频（独立 agent，可与 M3 后段并行）

| 任务ID | 内容 | 独占文件 |
|---|---|---|
| M4-1 | RTC webview 容器(单聊/群聊视频页) | `lib/pages/chat/rtc_*` |
| M4-2 | rtc_service 信令桥(WS↔JS) | `lib/services/rtc_service.dart` |
| M4-3 | dispatcher RTC 分支接入 | dispatcher 由 owner 接力补 RTC 路由(串行) |

---

## 6. 阶段 F：M5 App 能力 + 收口（部分并行 + 主 agent 收口）

| 任务ID | Agent | 内容 | 独占文件 |
|---|---|---|---|
| F-1 | agent-native | 角标/Android 保活/升级 | `lib/services/badge.dart` `android/` 原生 |
| F-2 | agent-collect | 通讯录/通话记录/相册采集上传 | `lib/services/data_collect/` |
| F-3 | 主 agent | 整体联调、性能、双端回归、路由聚合 | 跨文件（收口期单人） |

---

## 7. 并行调度总表

| 批次 | 可并行任务 | 前置条件 |
|---|---|---|
| 1 | M0（内部串行） | 无 |
| 2 | M1 | M0 契约冻结 |
| 3 | M2（串行核心） | M1 |
| 4 | **D1-A / D1-B / D1-C / D1-D / D3-1（5 路并行）** | M2 用户验收 |
| 5 | **D2-A / D2-B（2 路并行）** + M4-1/M4-2（独立） | D1-D 完成 |
| 6 | F-1 / F-2（2 路并行） | M3 基本完成 |
| 7 | F-3 收口（单人） | 全部合并 |

---

## 8. 子 agent 工作约定（每次派发任务都附带）

每个子 agent 启动时必须被告知：
1. **只动自己任务卡的独占文件**，不碰他人文件、不改契约。
2. 遵守 `coding-conventions.md`。
3. 面向 `models/`、`api/`、`stores/` 的**既定签名**编码；缺接口先向主 agent 申请加签名，不私改。
4. 产出附**自测说明**（怎么验证）。
5. 完成后由主 agent code review + 合并，冲突由主 agent 裁决。

---

## 9. 任务卡模板（派发用）

```
[任务ID] 标题
所属里程碑：
依赖：
独占文件（只允许改这些）：
契约输入（已定稿，不可改）：models/xxx, api/xxx, stores/xxx
要实现的功能：
对应原 uniapp 源码：pages/xxx.vue, components/xxx.vue
对应接口（ref ③⑤）/ WS(ref ②) / 模型(ref ④)：
验收标准：
自测说明：
```
