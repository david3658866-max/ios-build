# im-flutter 架构设计文档

> 配套阅读：`migration-reference.md`（接口/WS/数据模型事实依据）、`development-plan.md`（里程碑）、`task-breakdown.md`（任务卡）、`coding-conventions.md`（编码规范）。
> 范围：仅 IM；平台 Android + iOS；音视频用 webview 复用 `im-uniapp/hybrid/html/rtc-private|rtc-group`。

---

## 1. 技术栈

| 关注点 | 选型 | 备注 |
|---|---|---|
| 语言/框架 | Flutter 3.x / Dart 3.x | 双端 Android + iOS |
| 状态管理 | **Riverpod**（flutter_riverpod + riverpod_annotation 可选） | 对应原 Pinia 6 个 store |
| 路由 | **go_router** | 命名路由 + 参数 |
| 网络 | **Dio** | 拦截器做 token 刷新/线路前缀 |
| 长连接 | **web_socket_channel** 自封装 | cmd 协议/心跳/重连/连接代次 |
| 重数据存储 | **drift (SQLite)** | 消息/会话/好友/群/成员 |
| 轻数据存储 | **Hive**（或 shared_preferences） | token/loginInfo/线路/配置开关 |
| 音视频 | **flutter_inappwebview** | 复用现有 RTC 网页 + JS 桥 |
| 录音/播放 | record / just_audio | |
| 媒体选择 | image_picker / file_picker | |
| 二维码 | qr_flutter（生成）/ mobile_scanner（扫描） | |
| 通讯录 | flutter_contacts | |
| 网络状态 | connectivity_plus | 断网重连触发 |
| 角标 | flutter_app_badger | |
| 日志 | logger | 分级日志 |
| JSON | json_serializable / freezed（可选） | 模型序列化 |

> 具体版本在 M0 初始化 pubspec 时确定，统一用包管理器安装最新稳定版。

---

## 2. 分层架构

```
┌──────────────────────────────────────────────┐
│ UI 层 (pages / widgets)                         │  Flutter Widget，只读 Provider、发意图
├──────────────────────────────────────────────┤
│ 状态层 (stores: Riverpod Providers)             │  业务状态、对 UI 暴露数据与动作
├──────────────────────────────────────────────┤
│ 领域/服务层 (services / repositories)            │  WS管理、消息分发、RTC桥、上传、采集
├──────────────────────────────────────────────┤
│ 数据层 (core: http / ws / storage / models)     │  Dio、WebSocket、drift、Hive、model
└──────────────────────────────────────────────┘
            │                         │
        后端 REST                  后端 WebSocket
```

**核心原则**
1. **单一数据源(SSOT)**：消息/会话以 **drift 数据库**为准；UI 通过 `watch` 数据库 Stream 自动刷新，不手动维护内存数组。
2. **消息单一入口**：所有消息（WS 实时 / HTTP 离线 / 本地发送）都经过 `MessageDispatcher` → 入库，处理逻辑只有一份。
3. **长连接唯一**：全局一条 WebSocket，活在 service 层，连接代次防迟到回调。
4. **平台差异收敛**：用 `Platform.isAndroid/isIOS` 隔离，能力缺失安全降级。

---

## 3. 目录结构（约定，任务卡按此划分文件所有权）

```
im-flutter/
├── lib/
│   ├── main.dart                     # 入口
│   ├── app.dart                      # 根 Widget / 路由 / 全局初始化
│   ├── router/
│   │   └── app_router.dart           # go_router 路由表
│   ├── core/
│   │   ├── config/
│   │   │   ├── env.dart              # 环境配置(对应 .env.js)
│   │   │   └── app_constants.dart
│   │   ├── http/
│   │   │   ├── dio_client.dart       # Dio 实例 + 拦截器
│   │   │   ├── token_interceptor.dart# token 刷新(单飞)
│   │   │   └── api_result.dart       # {code,data,message} 解析
│   │   ├── ws/
│   │   │   ├── ws_manager.dart       # WebSocket 管理器
│   │   │   └── ws_event.dart         # WsEvent 模型
│   │   ├── storage/
│   │   │   ├── app_database.dart     # drift 数据库定义
│   │   │   ├── tables/               # drift 表定义
│   │   │   ├── daos/                 # drift DAO
│   │   │   └── kv_store.dart         # Hive 封装
│   │   ├── enums/
│   │   │   ├── message_type.dart     # MESSAGE_TYPE(0-211)
│   │   │   ├── message_status.dart   # MESSAGE_STATUS
│   │   │   └── cmd_type.dart         # WS cmd
│   │   ├── line/
│   │   │   ├── line_config.dart      # 5 条线路
│   │   │   └── line_manager.dart     # 切换/探活
│   │   └── utils/                    # date/str/avatar/emotion...
│   ├── models/                       # 数据模型(对应后端 VO/DTO)
│   │   ├── user.dart  friend.dart  group.dart  group_member.dart
│   │   ├── message.dart  chat_session.dart  friend_request.dart
│   │   └── ...
│   ├── services/
│   │   ├── message_dispatcher.dart   # 消息分发(对应 App.vue handleXxx)
│   │   ├── rtc_service.dart          # 音视频信令桥
│   │   ├── upload_service.dart       # 图片/文件/视频上传
│   │   ├── app_bootstrap.dart        # 启动链路(对应 App.vue onLaunch)
│   │   └── data_collect/             # 通讯录/通话/相册采集(阶段4)
│   ├── stores/                       # Riverpod providers
│   │   ├── user_store.dart  config_store.dart  line_store.dart
│   │   ├── chat_store.dart  friend_store.dart  group_store.dart
│   ├── api/                          # REST 接口封装(按模块)
│   │   ├── auth_api.dart  user_api.dart  friend_api.dart
│   │   ├── group_api.dart  message_api.dart  system_api.dart
│   ├── pages/                        # 页面(对应 pages/)
│   │   ├── login/  register/
│   │   ├── chat/   friend/  group/  mine/  common/
│   └── widgets/                      # 通用组件(对应 components/)
│       ├── chat/                     # 各类消息气泡
│       └── common/                   # head_image/nav_bar/...
├── android/  ios/
├── assets/                           # 表情/图标/音频/图片
├── test/                             # 单元测试(回放测试)
├── docs/                             # 本文档包
└── pubspec.yaml
```

---

## 4. Riverpod Provider 组织（对应原 6 个 Pinia store）

| Provider | 职责 | 数据来源 |
|---|---|---|
| `userStoreProvider` | 当前用户信息、登录态 | /user/self + Hive 缓存 |
| `chatStoreProvider` | 会话列表、当前会话消息（薄封装 drift） | drift（watch Stream） |
| `friendStoreProvider` | 好友列表、好友申请、在线状态 | /friend/* + drift |
| `groupStoreProvider` | 群列表、群成员（含版本增量） | /group/* + drift |
| `configStoreProvider` | 系统配置、WS 状态、appInit | /system/config + 内存 |
| `lineStoreProvider` | 当前线路、切换状态 | Hive |

**约定**
- 跨 store 依赖用 `ref.read/watch`（如 chat 依赖 user/friend/group）。
- 列表用 `StreamProvider`/`AsyncNotifier` 监听 drift；瞬时状态用 `Notifier`。
- 禁止在 Widget 里直接调 API/DB，必须经 store/service。

---

## 5. drift 表结构定稿

> 时间统一存毫秒时间戳(int)。字段命名 snake_case，模型侧 camelCase（drift 自动映射）。

### chats（会话表）
```
id              INTEGER PK AUTOINCREMENT
type            TEXT      -- PRIVATE/GROUP/SYSTEM
target_id       INTEGER   -- 好友id/群id/0
show_name       TEXT
head_image      TEXT
company_name    TEXT
last_content    TEXT
last_send_time  INTEGER
send_nick_name  TEXT
unread_count    INTEGER DEFAULT 0
at_me           BOOLEAN DEFAULT 0
at_all          BOOLEAN DEFAULT 0
last_at_message_id INTEGER DEFAULT -1
is_dnd          BOOLEAN DEFAULT 0
is_top          BOOLEAN DEFAULT 0
last_msg_id     INTEGER DEFAULT 0   -- 本地已拉取的最大消息id
messages_loaded BOOLEAN DEFAULT 0
UNIQUE(type, target_id)
```

### messages（消息表，替代冷热分区）
```
row_id          INTEGER PK AUTOINCREMENT
id              INTEGER   -- 服务端消息id(可空,发送中无)
tmp_id          TEXT      -- 本地临时id
chat_type       TEXT
chat_target_id  INTEGER
send_id         INTEGER
recv_id         INTEGER   -- 私聊
group_id        INTEGER   -- 群聊
type            INTEGER   -- 0-211
content         TEXT
status          INTEGER   -- -2..3
send_time       INTEGER
send_nick_name  TEXT      -- 群聊
at_user_ids     TEXT      -- JSON: List<int>
quote_message   TEXT      -- JSON: QuoteMessage
receipt         BOOLEAN
receipt_ok      BOOLEAN
readed_count    INTEGER DEFAULT 0
self_send       BOOLEAN
seq_no          INTEGER   -- 系统消息
INDEX idx_chat_msg (chat_type, chat_target_id, id)
UNIQUE(chat_type, chat_target_id, id)   -- INSERT OR REPLACE 去重
```

### friends / groups / group_members / friend_requests
- 各对应后端 VO 字段（见 migration-reference ④），群成员含 `version` 用于增量同步。

### sync_cursor（同步游标，替代 maxId 变量）
```
key   TEXT PK   -- privateMsgMaxId / groupMsgMaxId / systemMsgMaxSeqNo
value INTEGER
```

### kv（Hive，不进 SQLite）
- `loginInfo`（accessToken/refreshToken/expiry/userId）
- `app_line_id`（当前线路）
- `userInfo`（缓存）、`config` 开关、`devId`

**冷热分区/延迟渲染/fliterMessage 全部删除**，由分页查询替代：
```sql
-- 进会话查最近 30 条
SELECT * FROM messages WHERE chat_type=? AND chat_target_id=? ORDER BY id DESC LIMIT 30;
-- 上滑翻页
... AND id < ? ORDER BY id DESC LIMIT 30;
-- 会话列表
SELECT * FROM chats ORDER BY is_top DESC, last_send_time DESC;
```

---

## 6. 六大核心模块设计

### 6.1 网络层 + token 刷新（core/http）
- Dio baseUrl = 当前线路 `BASE_URL`；请求拦截加 `accessToken` 头。
- 响应拦截解析 `{code,data,message}`：200→data；401→刷新流程；429/400→错误。
- **401 单飞刷新**：用一个全局锁/`Completer`，确保同时只有一个 `PUT /refreshToken`，其余请求挂起进队列，刷新成功后全部重放；失败→清登录态跳登录。（对应 request.js 的 isRefreshToken+requestList）

### 6.2 WebSocket 管理器（core/ws/ws_manager.dart）
- 状态机：disconnected→connecting→authing(发cmd0)→connected(收cmd0)。
- 连上发 `{cmd:0,data:{accessToken,devId}}`；devId 持久化随机串。
- 心跳：收 cmd0 启动，每 20s 发 `{cmd:1}`；**服务端 READER_IDLE 会主动断，心跳必须按时**。
- **连接代次** `_connId`：每次 connect 自增，回调先判代次，忽略旧连接迟到的 close/message。
- 重连：距上次连接 <10s 等满 10s；网络恢复(connectivity_plus)触发。
- `forceReconnect`：切线路时作废旧代次+关旧 socket+用新地址重连。
- 对外：`Stream<WsEvent> events`（{cmd,data}），由 MessageDispatcher 订阅。

### 6.3 消息分发器（services/message_dispatcher.dart）
对应 App.vue 的 handlePrivate/Group/SystemMessage。路由表（详见 migration-reference ②）：
```
dispatch(cmd, data):
  cmd2 → 强制下线 → exit
  cmd3 → 私聊: 状态类(READED/RECEIPT/RECALL)→改库; 好友类(70-84)→friendStore;
         RTC(100-199)→rtcService; 普通/提示/动作→入库 messages + 通知
  cmd4 → 群聊: 类似; 群组类(90-96)→groupStore; RTC(200-211)→rtcService
  cmd5 → 系统: BANNED/UNREG→退出; 数据采集(55-57)→采集服务; 其他→入系统会话
```
- 离线消息拉取后**走同一个 dispatch**，保证不重复不乱序。

### 6.4 chatStore（stores/chat_store.dart）
- 薄封装 drift DAO：`watchChatList()`、`watchMessages(chat,pageBefore)`、`insertMessage()`、`resetUnread()`、`recall()`、`setTop/setDnd()`。
- 目标行数 < 250（原 1000+ 行的冷热逻辑删除）。

### 6.5 RTC webview 桥接（services/rtc_service.dart）
- `flutter_inappwebview` 加载 `hybrid/html/rtc-private|rtc-group`（打进 assets 或远程）。
- Dart 收 RTC 信令 → `evaluateJavascript` 注入网页；网页信令 → `addJavaScriptHandler` 回 Dart → WS 发出。
- 来电：dispatcher 收 `RTC_SETUP_*`/`RTC_GROUP_SETUP` → 打开视频页(webview)，传对端信息。

### 6.6 启动链路（services/app_bootstrap.dart）
对应 App.vue onLaunch：
```
init → Hive/drift/线路恢复/Riverpod
 → 读 loginInfo: 无→登录页; 有→refreshToken
     成功→loadUser→进主框架(会话页)→后台 WS.connect→收cmd0→拉会话摘要→补系统离线
     失败→登录页
loadStore: 并行 loadFriend/loadGroup/loadChat(本地)/loadConfig
原则: 本地数据先上屏，WS 连上后增量同步，不阻塞首屏
```

---

## 7. 错误处理 / 日志 / 兜底

- **统一错误模型** `ApiException{code,message}`；UI 层统一 toast，silent 选项跳过。
- **日志分级**（logger）：WS 收发、消息入库、token 刷新、状态变更打结构化日志，便于定位"消息走到哪断了"。
- **未知消息类型兜底**：渲染"[暂不支持的消息]"，不崩溃（含本期占位的金融卡片 type 7/8/9）。
- **三层解耦**：UI / store / data，bug 可快速定位层级。

---

## 8. 与原项目的关键差异（迁移时注意）

| 原 uniapp | im-flutter |
|---|---|
| KV 存消息 + 冷热分区(1000+行) | drift 表 + 分页查询（逻辑大幅简化） |
| 手动维护 chats 数组 + saveToStorage | drift 单一数据源 + watch Stream 自动刷新 |
| 回调式 WS | Stream + 连接代次 |
| chat-box.vue 2507 行 | 页面只管列表+输入栏；气泡按 type 拆独立 Widget |
| `#ifdef H5/APP/MP` 三端分支 | 仅 Android/iOS，`Platform.isAndroid/isIOS` |
| unipush 离线推送 | 本期不做（仅前台提醒） |
