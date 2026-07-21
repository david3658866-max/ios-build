# chat-box 设计 Token（从 im-uniapp scss 提取）

> 来源文件：
> - `im-uniapp/pages/chat/chat-box.vue`（页面布局、send-bar、消息区、工具/表情面板）
> - `im-uniapp/components/chat-message-item/chat-message-item.vue`（消息行、气泡、状态）
> - `im-uniapp/components/head-image/head-image.vue`（`size="small"` → 84rpx）
> - `im-uniapp/im-var.scss`（全局变量）
>
> **关联文档**：[design-tokens-chat.md](./design-tokens-chat.md)（会话列表 chat-item / chat.vue 页）  
> 本文档标注 **【chat-box 专用】** 的 token；未标注者复用 chat 文档 §1–§2 全局色/字号。
>
> **rpx → Flutter 逻辑像素**：`dp = rpx × screenWidth / 750`  
> 以 iPhone 12/13 宽度 390px 为参考：`dp ≈ rpx × 0.52`  
> Flutter 实现：`lib/theme/rpx.dart` 中 `rpx(context, value)`。

---

## 0. 与 design-tokens-chat.md 交叉引用

| 类别 | chat 文档章节 | chat-box 复用 | chat-box 专用 |
|------|---------------|---------------|---------------|
| 全局色板 | §1.1 | `primary` / `text` / `textLight` / `textLighter` / `danger` / `success` / `pageBg` / `border` / `bgActive` / `navBarBg` | §1.2–§1.4 |
| 字号 | §2 | `$im-font-size` 等全部字号变量 | §3.2 编辑器 30rpx、发送按钮等 |
| 导航栏 | §3.5 | 高 50px、`navBarBg` | chat-box 标题含群人数 `(size)` |
| head-image | §3.3 | 渐变文字头像算法 | **small = 84rpx**（消息行，非列表 96rpx） |
| ImColors 映射 | §4 | 同上 | §6 补充 primary 浅色阶 |

---

## 1. 色板

### 1.1 复用（见 [design-tokens-chat.md §1.1](./design-tokens-chat.md#11-全局im-varscss)）

chat-box 与 chat-message-item 直接引用的全局变量：

| scss 变量 | 值 | chat-box 用途 |
|-----------|-----|---------------|
| `$im-color-primary` | `#3e45d7` | locate-tip 文案、@ 栏图标、loading 图标 |
| `$im-color-danger` | `#e43d33` | 私聊「未读」状态 |
| `$im-color-success` | `#18bc37` | 回执「已确认」icon-ok |
| `$im-text-color` | `#000000` | 对方文字气泡正文 |
| `$im-text-color-light` | `#6a6a6a` | 群昵称、禁言 mask、工具名 |
| `$im-text-color-lighter` | `#909399` | 时间 tip、已读、回执人数、引用预览 |
| `$im-bg` | `#eef0f5` | 输入框背景、工具/表情面板、禁言 mask |
| `$im-border` | `#F0F0F0` | send-bar 顶部分割线 |
| `$im-bg-active` | `#f7f8fc` | 工具图标按压态 |

### 1.2 【chat-box 专用】页面与 send-bar（chat-box.vue）

| Token | scss / 值 | 用途 |
|-------|-----------|------|
| `msgAreaBg` | `#f6f8fa` | `.chat-msg` 消息滚动区背景 |
| `sendBarBg` | `#ffffff` | `.send-bar` 底栏 |
| `sendBarIcon` | `rgba(0, 0, 0, 0.8)` | 语音/键盘/@/表情/加号图标 |
| `inputBorderH5` | `#e8e8ef` | `.send-text` H5 边框（1px solid） |
| `quotePreviewBg` | `#eee` | send-bar 内引用条背景 |
| `quoteRemoveIcon` | `#888` | 引用清除 uni-icons（template 内联） |
| `locateTipBg` | `#ffffff` | 「回到底部 / N条新消息 / 有人@我」浮层 |
| `locateTipText` | `$im-color-primary` | 浮层文案色 |
| `locateTipShadow` | `$im-box-shadow-dark` | 见 §1.4 |
| `toolIconBg` | `#ffffff` | 工具格图标底 |
| `toolIconActive` | `$im-bg-active` | 工具格 `:active` |

### 1.3 【chat-box 专用】消息气泡（chat-message-item.vue）

| Token | scss / 值 | 用途 |
|-------|-----------|------|
| `bubbleOtherBg` | `#ffffff` | `.message-text` 对方气泡 |
| `bubbleOtherText` | `$im-text-color` | 对方正文 |
| `bubbleMineBg` | `$im-color-primary-light-2` | 己方气泡（mix #fff 20%）≈ **`#656adf`** |
| `bubbleMineText` | `#ffffff` | 己方正文 |
| `bubbleTailOther` | `#ffffff` | `:after` 三角指向头像 |
| `bubbleTailMine` | `$im-color-primary-light-2` | 己方三角 ≈ `#656adf` |
| `sendFailIcon` | `#e60c0c` | 发送失败 icon-warning-circle-fill |
| `sendingLoader` | `#656adf`（template `icon-color`） | 发送中 loading |
| `itemActiveBg` | `$im-bg-active-dark` = `$im-color-primary-light-9` ≈ **`#ececfb`** | 消息定位高亮 `.active` |
| `groupNameText` | `$im-text-color-light` | 群聊发送者昵称 |

**primary 浅色阶（im-var.scss `mix(#fff, #3e45d7, N%)`）**

| 变量 | 混合比 | 近似 hex | 用途 |
|------|--------|----------|------|
| `$im-color-primary-light-2` | 20% | `#656adf` | 己方气泡 |
| `$im-color-primary-light-5` | 50% | `#9fa2eb` | 图片边框 |
| `$im-color-primary-light-9` | 90% | `#ececfb` | 消息高亮背景 |

### 1.4 阴影（im-var.scss，chat-box 引用）

| Token | scss | 用途 |
|-------|------|------|
| `boxShadowDark` | `0px 1px 6px 2px rgba(#a5a4a4, 0.5)` | locate-tip |
| `boxShadow` | `0 2px 4px rgba(0,0,0,.12), 0 0 6px rgba(0,0,0,.04)` | 文件/名片卡片（M2-4 文字批次不涉及） |

---

## 2. 字号

复用 [design-tokens-chat.md §2](./design-tokens-chat.md#2-字号im-varscss)；chat-box 额外：

| 元素 | scss | rpx | 390px ≈ dp |
|------|------|-----|------------|
| send-bar 工具图标 | `.iconfont` | **60** | 31 |
| 输入区 editor | `.send-text-area` | **30** | 16 |
| 输入区容器 | `.send-text` | `$im-font-size` = 32 | 17 |
| locate-tip | `.locate-tip` | `$im-font-size` = 32 | 17 |
| @ 栏图标 | `.icon-at` | `$im-font-size-larger` = 36 | 19 |
| 禁言 mask | `.chat-editer-mask` | `$im-font-size-small` = 30 | 16 |
| 禁言 warning 图标 | `.icon` | **32** | 17 |
| 工具格图标 | `.tool-icon` | **54** | 28 |
| 工具名 | `.tool-name` | `$im-font-size-smaller` = 28 | 15 |
| 消息 tip（时间/系统） | `.message-tip` | `$im-font-size-smaller-extra` = 26 | 14 |
| 群昵称 | `.name` | `$im-font-size-smaller` = 28 | 15 |
| 文字气泡 | `.message-text` | `$im-font-size` = 32 | 17 |
| 发送失败图标 | `.send-fail` | **50** | 26 |
| 已读/未读 | `.message-status` | `$im-font-size-smaller-extra` = 26 | 14 |
| 回执 | `.chat-receipt` | `$im-font-size-smaller` = 28 | 15 |
| 回执 ok 图标 | `.icon-ok` | **20px**（固定 px） | 20 |

---

## 3. 间距与尺寸

### 3.1 【chat-box 专用】页面布局（chat-box.vue）

| 元素 | scss | 390px ≈ dp | 说明 |
|------|------|------------|------|
| `.chat-main-box` top | `$im-nav-bar-height` = **50px** | 50 | 非 APP |
| APP top | `50px + status-bar-height` | — | 见 chat 文档 §3.5 |
| `.chat-msg` background | `#f6f8fa` | — | flex:1 占满中间 |
| 滚动触底阈值 | JS `80px` | 80 | `onScroll` 判定 isInBottom |
| 键盘/面板默认高 | JS **290px** | 290 | `keyboardHeight` / `chatPanelHeight` |
| send-bar min-height | **80rpx** | 42 | |
| send-bar padding | **10rpx** | 5 | H5 底加 `env(safe-area-inset-bottom)` |
| send-bar 顶边框 | `$im-border` **1px** | — | |

#### locate-tip（浮于消息区右下）

| 属性 | scss | 390px ≈ dp |
|------|------|------------|
| right / bottom | **30rpx** | 16 |
| padding | **10rpx 30rpx** | 5 × 16 |
| border-radius | **25rpx** | 13 |
| font-weight | **600** | — |
| opacity | **0.85** | — |

#### send-bar 输入区

| 元素 | scss | 390px ≈ dp |
|------|------|------------|
| `.send-text` padding | **20rpx** | 10 |
| border-radius | **20rpx** | 10 |
| margin | **5rpx** | 3 |
| min-height | **72rpx** | 37 |
| `.send-text-area` min-height | **40rpx** | 21 |
| `.send-text-area` max-height | **200rpx** | 104 |
| `.btn-send` margin | **5rpx** | 3 |
| send-bar `.iconfont` margin | **0 10rpx** | 0 × 5 |
| 引用条 padding | **5rpx** | 3 |
| 引用条 radius | **10rpx** | 5 |

#### chat-at-bar（群 @ 预览，M2-4 可选）

| 元素 | scss | 390px ≈ dp |
|------|------|------------|
| padding | **0 10rpx** | 0 × 5 |
| 头像行高 | **70rpx** | 36 |
| 头像项 padding | **0 3rpx** | 0 × 2 |

#### chat-tab-bar 工具/表情（M2-4 文字批次可延后）

| 元素 | scss | 390px ≈ dp |
|------|------|------------|
| 工具区 padding | **20rpx 40rpx** | 10 × 21 |
| 工具项宽 | **25%**（4 列） | — |
| 工具项 padding | **6rpx 16rpx** | 3 × 8 |
| 工具图标 padding | **26rpx** | 14 |
| 工具图标 radius | **20%** | — |
| 工具名行高 | **60rpx** | 31 |
| 表情区 padding | **40rpx** | 21 |
| 面板高（computed） | `min(rows×178+40, chatPanelHeight)` rpx | — |

### 3.2 【chat-box 专用】消息行（chat-message-item.vue）

| 元素 | scss | 390px ≈ dp | 说明 |
|------|------|------------|------|
| `.chat-message-item` padding | **15rpx 20rpx** | 8 × 10 | 每条消息外间距 |
| `.chat-message-item` radius | **20rpx** | 10 | 高亮容器 |
| `.message-normal` padding-left | **105rpx** | 55 | 为头像留位 |
| `.message-normal` min-height | **80rpx** | 42 | |
| 头像 `size="small"` | **84rpx** | 44 | head-image.vue |
| 头像定位 | `top:0; left:0`（absolute） | — | 己方见 message-mine |
| `.bottom` margin-top | **10rpx** | 5 | 昵称与气泡间距 |
| `.bottom` padding-right | **80rpx** | 42 | 对方：为状态图标留空 |
| 己方 `.bottom` padding-left | **80rpx** | 42 | message-mine |

#### 文字气泡 `.message-text`

| 属性 | 对方 | 己方 (message-mine) |
|------|------|---------------------|
| padding | **16rpx 20rpx 16rpx 16rpx** | **16rpx 16rpx 16rpx 20rpx** |
| border-radius | **20rpx** | **20rpx** |
| margin-left / margin-right | margin-left **8rpx** | margin-left **10rpx**, margin-right **8rpx** |
| line-height | **1.6** | **1.6** |
| 三角 `:after` top | **20rpx** | **20rpx** |
| 三角水平偏移 | left **-10rpx** | right **-10rpx** |
| 三角 border-width | **12rpx 12rpx 12rpx 0** | **12rpx 0 12rpx 12rpx** |

#### 发送状态图标位置

| 状态 | 选择器 | 布局 | scss |
|------|--------|------|------|
| 发送中 | `.sending` | `.message-body` 内 **inline-flex**，文字/语音消息 | `margin: 0 20rpx`；loading size **40** |
| 发送失败 | `.send-fail` | 同上，可点击重发 | `margin: 0 5rpx`；font-size **50rpx** |
| 私聊已读/未读 | `.message-status` | 气泡 **下方**，仅 `selfSend && !groupId` | `margin-top: 5rpx` |
| 群回执 | `.chat-receipt` | 气泡下方 | font-weight **600** |

**布局要点**：`.message-body` 为 `display: inline-flex; align-items: center`。对方消息从左到右为「气泡 → sending/fail」；己方 `message-mine` 设 `flex-direction: row-reverse`，顺序为「fail/sending → 气泡」。

#### 时间 / 系统 tip `.message-tip`

| 属性 | scss | 390px ≈ dp |
|------|------|------------|
| line-height | **60rpx** | 31 |
| text-align | center | — |
| color | `$im-text-color-lighter` | #909399 |
| font-size | `$im-font-size-smaller-extra` | 26rpx |

---

## 4. 结构对照（DOM 层级）

```
chat-box.vue
├── nav-bar
├── chat-main-box (flex column, 高度 = 屏高 - nav - 键盘/面板)
│   ├── chat-top-message (群置顶, M2-4 可跳过)
│   ├── chat-msg (#f6f8fa)
│   │   ├── scroll-view → chat-message-item × N
│   │   └── locate-tip (条件显示)
│   ├── chat-at-bar (群 @ 预览)
│   ├── send-bar
│   └── chat-tab-bar (tools | emo)
└── 各类 selector / modal

chat-message-item.vue（文字消息路径）
├── message-tip          ← TIP_TIME / TIP_TEXT
└── message-normal[.message-mine]
    ├── head-image.avatar (small 84)
    └── content
        ├── top.name (+ 群主/管理员 tag, 群且非己发)
        └── bottom
            ├── message-body
            │   ├── message-text (+ 三角伪元素)
            │   ├── .sending | .send-fail
            ├── quote-message (M2-4 可跳过)
            ├── message-status (私聊已读/未读)
            └── chat-receipt (群回执, M2-4 可跳过)
```

---

## 5. Flutter 实现映射（规划）

```
lib/pages/chat/
  chat_box_page.dart       ← §3.1 布局、send-bar、locate-tip、scroll
lib/widgets/chat/
  chat_message_item.dart   ← §3.2 消息行
  bubbles/text_bubble.dart ← §1.3 / §3.2 文字气泡 + 三角
  send_bar.dart            ← §3.1 send-bar（可拆分）
lib/theme/
  im_colors.dart           ← §1 + design-tokens-chat §4
  rpx.dart
```

数值应能回溯至本文 scss 来源；**【chat-box 专用】** 色优先写入 `ChatBoxColors` 或扩展 `ImColors`。

---

## 6. ImColors 补充（相对 design-tokens-chat §4）

| scss / 用途 | 近似 hex | 建议 |
|-------------|----------|------|
| `$im-color-primary-light-2` | `#656adf` | `accentBubbleMine` |
| `$im-color-primary-light-9` | `#ececfb` | `messageHighlightBg` |
| `#f6f8fa` msgAreaBg | — | `chatMsgBg` |
| `#e60c0c` sendFail | — | `sendFail`（或复用 danger 微调） |
| `rgba(0,0,0,0.8)` sendBarIcon | — | `iconPrimary` |
| `#e8e8ef` inputBorder | — | `inputBorder` |

---

## 7. M2-4 第一批 Checklist（仅文字消息）

> 范围对齐 [task-breakdown.md M2-4](./task-breakdown.md)：文字 / 状态机 / 分页 / 时间分隔。  
> 图片、语音、文件、视频、名片、引用、@、表情面板、工具面板、群置顶、回执 **不在本批**。

### 7.1 页面骨架

- [ ] 全屏布局：`nav-bar`（50px）+ `chat-main-box` flex 列
- [ ] 消息区背景 **`#f6f8fa`**，占满剩余高度，`scroll-view` 可滚动
- [ ] 进入会话滚动到底部；上拉预加载历史（虚拟窗口 `showMinIdx` / `pageSize` 逻辑）
- [ ] 非底部时显示 **locate-tip**（「回到底部」/「N条新消息」），样式见 §3.1
- [ ] 点击消息区收起键盘/面板（`switchChatTabBox('none')` 等价行为）

### 7.2 send-bar（文字输入最小集）

- [ ] 白底顶部分割线 **`$im-border`**，min-height **80rpx**，padding **10rpx** + safe-area
- [ ] 左侧语音图标（可占位，本批可不实现录音）、中间 **`send-text`** 输入区、右侧表情/加号（可占位）
- [ ] 输入区：背景 **`$im-bg`**，radius **20rpx**，padding **20rpx**，min/max 高度 **72/200rpx**
- [ ] H5 输入框边框 **`#e8e8ef` 1px**
- [ ] 有内容时显示 **「发送」** 主色按钮（`type="primary"`）
- [ ] 禁言/退群/封禁时 **`chat-editer-mask`** 全覆盖（背景 `$im-bg`，文案 `$im-text-color-light`）

### 7.3 消息行 — 时间分隔（TIP_TIME）

- [ ] `MESSAGE_TYPE.TIP_TIME` 渲染 `.message-tip`：居中、**26rpx**、`$im-text-color-lighter`、行高 **60rpx**
- [ ] 时间格式化与 uniapp `$date.toTimeText` 一致

### 7.4 消息行 — 普通文字（TEXT）

- [ ] 外层 padding **15×20rpx**；定位高亮时背景 **`$im-bg-active-dark`**（≈ `#ececfb`）
- [ ] 头像 **`HeadImage` size=84**（small），绝对定位 left:0（己方 right:0）
- [ ] 群聊且非己发：昵称行 **28rpx** `$im-text-color-light`（群主/管理员 tag 本批可简化跳过）
- [ ] 对方气泡：白底、**20rpx** 圆角、padding **16/20/16/16rpx**、左下三角
- [ ] 己方气泡：背景 **`#656adf`**、白字、padding 左右镜像、右下三角
- [ ] 正文 **32rpx**，`line-height: 1.6`，`white-space: pre-line`，自动换行
- [ ] 左右布局：`message-normal` padding-left **105rpx**；`message-mine` padding-right **105rpx** + `row-reverse`

### 7.5 发送状态机（文字）

- [ ] `SENDING`：气泡旁 loading，**40** 尺寸，色 **`#656adf`**，margin **0 20rpx**
- [ ] `FAILED`：红色 **`#e60c0c`** 警告图标 **50rpx**，margin **0 5rpx**，点击重发（仅 TEXT）
- [ ] 私聊己发：气泡下 **已读/未读**（**26rpx**；已读 `#909399`，未读 `$im-color-danger`）
- [ ] 群聊不显示私聊已读条（`!groupId` 条件）

### 7.6 数据与行为（非 UI，M2-4 出口依赖）

- [ ] 发送文字：临时消息插入 → 队列发送 → 更新 id/status
- [ ] 收到新消息：在底部则滚底，否则 `newMessageSize++`
- [ ] 虚拟列表窗口：初始末尾 **pageSize(80)** 条，触顶 **preloadStep(40)** 扩展
- [ ] 会话已读上报（进入/ unreadCount 变化）

### 7.7 本批明确不做

- 引用消息（send-bar + 气泡内 quote）
- @ 成员栏 / 群 @
- 表情面板、工具面板、语音录制
- 长按菜单（复制/撤回/转发等）
- 群置顶条、群回执 UI
- 图片/文件/语音/视频/卡片/通话类消息 UI

---

## 8. 快速对照表（文字消息核心）

| 属性 | uniapp | Flutter |
|------|--------|---------|
| 消息区背景 | `#f6f8fa` | `ChatBoxColors.msgAreaBg` |
| 头像 | 84rpx small | `rpx(context, 84)` |
| 消息行左右 padding | 15/20rpx | `rpx(15)` / `rpx(20)` |
| 头像占位 | 105rpx | `rpx(105)` |
| 对方气泡背景 | `#fff` | `Colors.white` |
| 己方气泡背景 | `#656adf` | `ImColors.accentBubbleMine` |
| 气泡圆角 | 20rpx | `rpx(20)` |
| 气泡 padding（对方） | 16,20,16,16 | 对称 EdgeInsets |
| 字号 | 32rpx | `rpx(32)` |
| 时间 tip 字号 | 26rpx | `rpx(26)` |
| send-bar 最小高度 | 80rpx | `rpx(80)` |
| 输入区圆角 | 20rpx | `rpx(20)` |
