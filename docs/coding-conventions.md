# im-flutter 编码规范文档

> 目的：保证多个子 agent 并行开发产出**风格一致、能无缝拼接**的代码。所有 agent 必须遵守。
> 配套：`architecture.md`（目录/分层）、`task-breakdown.md`（文件所有权）。

---

## 1. 命名约定

| 对象 | 规则 | 示例 |
|---|---|---|
| 文件名 | snake_case | `chat_box_page.dart`、`ws_manager.dart` |
| 类名 | UpperCamelCase | `ChatStore`、`MessageDispatcher` |
| 变量/方法 | lowerCamelCase | `loadFriend()`、`unreadCount` |
| 常量 | lowerCamelCase + `const` | `const wsHeartbeatMs = 20000` |
| 枚举值 | lowerCamelCase | `MessageType.text` |
| 私有成员 | 前缀 `_` | `_connId` |
| Provider | 后缀 `Provider` | `chatStoreProvider` |
| 页面类 | 后缀 `Page` | `LoginPage` |
| 组件 Widget | 语义化名 | `HeadImage`、`TextBubble` |
| drift 表 | 复数 snake | `messages`、`chats` |
| 模型类 | 单数 | `Message`、`ChatSession` |

---

## 2. 目录与文件所有权

- 严格按 `architecture.md` 第 3 节目录放置文件。
- **一个子 agent 只改自己任务卡声明的独占文件**（见 task-breakdown）。
- 共享/聚合文件（`pubspec.yaml`、`router/app_router.dart`、`core/storage/app_database.dart` 的聚合、`models` 导出文件）只由**主 agent**在合并点修改。
- 新增页面需挂路由时：**不直接改 app_router.dart**，而是向主 agent 申请登记（或在任务卡里预留路由名，主 agent 统一接）。

---

## 3. 状态管理（Riverpod）约定

- UI 用 `ConsumerWidget`/`ConsumerStatefulWidget`，通过 `ref.watch` 读状态、`ref.read(...).method()` 发动作。
- **禁止** 在 Widget 内直接调用 `api/` 或 drift；必须经 `stores/` 或 `services/`。
- 列表类用 `StreamProvider` 监听 drift 的 `watch`；命令式状态用 `Notifier`/`AsyncNotifier`。
- 跨 store 依赖用 `ref`，不要用全局单例互相 import 实例。
- Provider 对外方法签名在 M0 冻结，**并行期不得改签名**，只能加（加也要先报主 agent）。

---

## 4. 网络层约定

- 所有 REST 调用经 `api/*_api.dart` 封装，返回**已解包的 data**（拦截器统一处理 `{code,data,message}`）。
- 不在业务里手写 `dio.get`；新增接口加到对应 `*_api.dart`。
- 错误统一抛 `ApiException{code,message}`；需要静默的传 `silent: true`。
- 路径常量集中，不散落字符串（与 migration-reference ③⑤ 对齐）。

---

## 5. 数据模型约定

- 模型放 `models/`，字段**严格对齐后端 VO/DTO**（migration-reference ④）。
- 用 `json_serializable`（或 freezed）生成 `fromJson/toJson`；**时间字段是毫秒 int**，不要当 ISO 字符串解析。
- 兼容后端大小写不一致字段（如系统消息 `SeqNo`/`seqNo`）。
- 可空性按后端实际；拿不准的设为可空 + 默认值，避免解析崩溃。

---

## 6. drift / 存储约定

- 表定义放 `core/storage/tables/`，DAO 放 `core/storage/daos/`。
- 消息入库统一走 chatStore/DAO，**不在页面里直接写库**。
- 写库用 `INSERT OR REPLACE`（按唯一键去重）；批量写用事务。
- 轻量 KV（token/线路/配置）走 Hive 封装 `kv_store.dart`，不进 SQLite。
- 改表结构 = 改契约，必须主 agent 统一改并升级 schemaVersion。

---

## 7. 消息处理约定

- 所有消息（WS/离线/本地发送）统一经 `MessageDispatcher.dispatch`，**不在多处各写一套**。
- 消息类型判断用 `core/enums/message_type.dart` 的区间辅助方法（isNormal/isTip/isRtc 等），不写魔法数字。
- 气泡渲染按 type 分发到 `widgets/chat/bubbles/` 下独立 Widget，**每种一个文件，单文件 ≤ 300 行**。
- 未知 type 渲染"[暂不支持的消息]"占位，不崩溃。

---

## 8. 错误处理与日志

- 统一用 `logger`，分级：`d`(调试) `i`(信息) `w`(警告) `e`(错误)。
- **关键链路必打日志**：WS 收发(cmd)、消息入库、token 刷新、状态切换、重连。
- 日志带模块前缀：`[WS]`、`[Dispatch]`、`[Chat]`、`[Http]`。
- 不吞异常；catch 后要么处理要么上抛，并记日志。
- 用户可见错误统一 toast，不直接抛栈到 UI。

---

## 9. 平台差异

- 用 `Platform.isAndroid` / `Platform.isIOS` 隔离原生能力；缺失能力安全降级（return/no-op）。
- 原生通道（保活/通话记录）封装在 `services/` 下，UI 不直接调 MethodChannel。

---

## 10. UI / 样式

- 颜色、间距、字号集中到 `theme`，不散写魔法值（对标原 `im.scss` 变量）。
- 列表一律 `ListView.builder` 懒加载（替代原虚拟滚动）。
- 头像统一用 `HeadImage` 组件；空数据用 `NoDataTip`。
- 中文文案集中常量管理，便于核对与后续 i18n。

---

## 11. 注释

- 只写"为什么/约束/坑"，不写"翻译代码"的废话注释。
- 复刻原逻辑的关键坑点（如 WS 连接代次、token 单飞、离线去重）**必须注释说明意图**，并标注对应 uniapp 源码位置。
- 公共 API 加简短文档注释。

---

## 12. 测试

- 核心逻辑（dispatcher / chatStore / token 刷新 / WS 代次）写单测，放 `test/`。
- 用**抓包的真实报文**作为夹具回放，断言入库/状态结果。
- 改动核心逻辑前先跑 `flutter test`，不破坏已有用例。

---

## 13. Git 约定

- 分支：`feat/<task-id>`（如 `feat/D1-A-friend`）、修复 `fix/xxx`。
- 提交信息：`<type>(<scope>): <说明>`，type ∈ feat/fix/refactor/test/docs/chore。
  - 例：`feat(friend): 好友列表与申请处理`
- 一个任务卡一分支，完成后 PR/合并到 `develop`，主 agent review。
- **不提交** 生成文件冲突、密钥、`.env` 真实地址外的私密信息。

---

## 14. 并行开发红线（务必遵守）

1. 不改不属于自己任务卡的文件。
2. 不改契约（models/api/stores 签名、drift 表、enums）——需要变更先找主 agent。
3. 不在多处重复实现同一逻辑（消息处理只在 dispatcher）。
4. 合并前自测 + 不破坏现有单测。
5. 热点文件（`chat_box_page.dart`、`app_router.dart`、`app_database.dart`、`message_dispatcher.dart`）串行接力，不并行同改。
