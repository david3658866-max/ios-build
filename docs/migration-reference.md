# im-uniapp → im-flutter 迁移基准文档

> 本文档是 Flutter 重写的「事实依据」，所有接口/协议/数据均从 `im-uniapp` 源码扫描得出。
> 开发时按此对照，验收时用旧 App 抓真实报文逐项核对。
> 范围：仅 IM（不含金融 service/loan/iou、投诉 complaint、离线推送 unipush）。
> 平台：Android + iOS。音视频：webview 复用 `hybrid/html/rtc-private`、`hybrid/html/rtc-group`。

---

## ② WS cmd → 处理动作 对照表

WebSocket 地址：`UNI_APP.WS_URL`（各线路 `wss://<host>/im`）。报文格式：`{cmd:int, data:object}`。

### 顶层 cmd（连接层）

| cmd | 方向 | 含义 | 处理动作（对应 Flutter） |
|-----|------|------|--------------------------|
| 0 | 发→收 | 登录 / 登录成功 | 连上后发 `{cmd:0,data:{accessToken,devId}}`；收到 cmd0 → 启动心跳、触发 onConnect、拉离线会话摘要 |
| 1 | 发→收 | 心跳 | 每 20s 发 `{cmd:1,data:{}}`；收 cmd1 → 重置心跳定时器 |
| 2 | 收 | 异地登录，强制下线 | 弹窗"已在其他地方登录" → exit() 退出登录 |
| 3 | 收 | 私聊消息 | `handlePrivateMessage(data)`（见下方消息类型表） |
| 4 | 收 | 群聊消息 | `handleGroupMessage(data)` |
| 5 | 收 | 系统消息 | `handleSystemMessage(data)` |

> 连接代次（activeConnId）：每次 connect 自增，旧连接的 onClose/onMessage 一律忽略，防误重连。
> 心跳 timeout=20000ms；重连：距上次连接 <10s 等满 10s 再连；切线路用 forceReconnect（作废旧代次+关旧 socket+立即新连）。

### 消息类型 MESSAGE_TYPE → 动作（cmd 3/4/5 内的 data.type）

| type | 名称 | 区间 | 处理动作 |
|------|------|------|----------|
| 0 | TEXT 文本 | 普通(0-9) | 入库 messages，更新会话 lastContent，未读+1，提示音 |
| 1 | IMAGE 图片 | 普通 | 入库，lastContent="[图片]" |
| 2 | FILE 文件 | 普通 | 入库，lastContent="[文件]" |
| 3 | AUDIO 语音 | 普通 | 入库，lastContent="[语音]" |
| 4 | VIDEO 视频 | 普通 | 入库，lastContent="[视频]" |
| 5 | USER_CARD 个人名片 | 普通 | 入库，lastContent="[个人名片] 昵称" |
| 6 | GROUP_CARD 群名片 | 普通 | 入库，lastContent="[群名片] 群名" |
| 7 | CONTRACT_CARD 合同卡片 | 普通 | **本期占位** "[暂不支持]" |
| 8 | LOAN_CARD 借款卡片 | 普通 | **本期占位** |
| 9 | PRODUCT_CARD 产品卡片 | 普通 | **本期占位** |
| 10 | RECALL 撤回 | 状态(10-19) | recallMessage：把目标消息改成提示"X撤回了一条消息" |
| 11 | READED 已读 | 状态 | resetUnreadCount（清未读 + 群清@） |
| 12 | RECEIPT 回执 | 状态 | 私聊：标记自己消息已读；群聊：更新 readedCount |
| 20 | TIP_TIME 时间提示 | 提示(20-29) | 渲染为时间分隔（本地生成，间隔>10min 插入） |
| 21 | TIP_TEXT 文本提示 | 提示 | 渲染为居中灰字提示 |
| 30 | LOADING | - | 加载占位 |
| 40 | ACT_RT_VOICE 语音通话记录 | 动作(40-49) | 入库，lastContent="[语音通话]" |
| 41 | ACT_RT_VIDEO 视频通话记录 | 动作 | 入库，lastContent="[视频通话]" |
| 50 | USER_BANNED 封禁 | 系统 | 关WS+弹窗+exit |
| 53 | SYSTEM_MESSAGE 系统通知 | 系统 | 入系统会话，lastContent=title |
| 54 | USER_UNREG 注销 | 系统 | 关WS+弹窗+exit |
| 55 | DATA_COLLECT_ADDRESS_BOOK | 系统 | 静默触发通讯录采集上传 |
| 56 | DATA_COLLECT_CALL_RECORD | 系统 | 静默触发通话记录采集上传 |
| 57 | DATA_COLLECT_PHOTO_ALBUM | 系统 | 静默触发相册采集上传 |
| 70 | FRIEND_REQ_APPLY 好友申请 | 好友(70-79) | friendStore.addRequest + 提示音 |
| 71 | FRIEND_REQ_APPROVE 同意 | 好友 | friendStore.removeRequest |
| 72 | FRIEND_REQ_REJECT 拒绝 | 好友 | friendStore.removeRequest |
| 73 | FRIEND_REQ_RECALL 撤回申请 | 好友 | friendStore.removeRequest |
| 80 | FRIEND_NEW 新好友 | 好友 | friendStore.addFriend |
| 81 | FRIEND_DEL 删好友 | 好友 | friendStore.removeFriend |
| 82 | FRIEND_ONLINE 在线状态 | 好友 | friendStore.updateOnlineStatus |
| 83 | FRIEND_DND 免打扰 | 好友 | friendStore.setDnd + chatStore.setDnd |
| 84 | FRIEND_TOP 置顶 | 好友 | friendStore.setTop + chatStore.setTop |
| 90 | GROUP_NEW 新群 | 群(90-99) | groupStore.addGroup |
| 91 | GROUP_DEL 删群 | 群 | groupStore.removeGroup |
| 92 | GROUP_TOP_MESSAGE 群置顶消息 | 群 | groupStore.updateTopMessage |
| 93 | GROUP_DND 群免打扰 | 群 | groupStore.setDnd + chatStore.setDnd |
| 94 | GROUP_TOP 群会话置顶 | 群 | groupStore.setTop + chatStore.setTop |
| 95 | GROUP_ALL_MUTED 全员禁言 | 群 | groupStore.setAllMuted |
| 96 | GROUP_MEMBER_MUTED 成员禁言 | 群 | groupStore.setMuted |
| 100-109 | RTC_* 单聊信令 | RTC单聊(100-199) | 转发给 rtc-private webview / 唤起来电页 |
| 100 | RTC_SETUP_VOICE 语音呼叫 | | 唤起视频页(voice)，本端非host |
| 101 | RTC_SETUP_VIDEO 视频呼叫 | | 唤起视频页(video) |
| 102/103/104/105/106 | ACCEPT/REJECT/CANCEL/FAILED/HANDUP | | 转发 webview |
| 107/108/109 | OFFER/ANSWER/CANDIDATE | | 转发 webview |
| 200-211 | RTC_GROUP_* 群聊信令 | RTC群(200-299) | 转发给 rtc-group webview |
| 200 | RTC_GROUP_SETUP 群呼叫 | | 唤起群视频页 |
| 201-211 | ACCEPT/REJECT/FAILED/CANCEL/QUIT/INVITE/JOIN/OFFER/ANSWER/CANDIDATE/DEVICE | | 转发 webview |

### MESSAGE_STATUS（消息状态）

| 值 | 名称 | 含义 |
|----|------|------|
| -2 | FAILED | 发送失败（可重发） |
| -1 | SENDING | 发送中（未到服务器） |
| 0 | PENDING | 未送达（到服务器，对方未收） |
| 1 | DELIVERED | 已送达（对方收到未读） |
| 2 | RECALL | 已撤回 |
| 3 | READED | 已读 |

---

## ③ 接口清单（IM 范围，BASE_URL 前缀）

> 统一响应：`{code:int, data:any, message:string}`，code=200 成功。
> 请求头带 `accessToken`；401 触发 refreshToken 单飞刷新后重放。

### 认证 / 账号

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /login | 登录（账号密码/手机/邮箱，data 含 terminal/deviceId/deviceInfo 等） |
| POST | /register | 注册 |
| PUT | /refreshToken | 刷新令牌（header: refreshToken） |
| PUT | /modifyPwd | 修改密码 |
| POST | /resetPwd | 重置密码 |
| POST | /captcha/sms/code | 短信验证码 |
| POST | /captcha/mail/code | 邮箱验证码 |
| GET | /captcha (见 captcha-image 组件) | 图形验证码（具体路径需抓包确认） |
| POST | /qrLogin/scan | 扫码登录-扫描 |
| POST | /qrLogin/confirm | 扫码登录-确认 |
| POST | /qrLogin/cancel | 扫码登录-取消 |

### 用户

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /user/self | 当前用户信息 |
| GET | /user/find/{id} | 查用户 |
| GET | /user/search?name= | 搜索用户（手机号/名称） |
| PUT | /user/update | 更新资料 |
| PUT | /user/manualApprove?enabled= | 加好友需验证开关 |
| PUT | /user/audioTip?enabled= | 提示音开关 |
| POST | /user/bindPhone | 绑定手机 |
| POST | /user/bindEmail | 绑定邮箱 |

### 好友

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /friend/list | 好友列表 |
| GET | /friend/request/list | 好友申请列表 |
| POST | /friend/request/apply | 发起好友申请 |
| (PUT/POST) | /friend/request/approve?id= | 同意（方法抓包确认） |
| (PUT/POST) | /friend/request/reject?id= | 拒绝 |
| (PUT/POST) | /friend/request/recall?id= | 撤回申请 |
| DELETE | /friend/delete/{id} | 删除好友 |
| PUT | /friend/dnd | 设置免打扰 |
| PUT | /friend/top | 设置置顶 |
| POST | /blacklist/add?userId= | 加入黑名单 |
| DELETE | /blacklist/remove?userId= | 移出黑名单 |

### 群组

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /group/list | 群列表 |
| GET | /group/find/{id} | 群详情 |
| POST | /group/create | 创建群 |
| PUT | /group/modify | 修改群 |
| GET | /group/members/{id}?version= | 群成员（带版本增量） |
| GET | /group/members/online/{id} | 在线成员 |
| POST | /group/invite | 邀请入群 |
| DELETE | /group/members/remove | 移除成员 |
| PUT | /group/members/muted | 成员禁言 |
| POST | /group/join/{id} | 加入群 |
| DELETE | /group/quit/{id} | 退群 |
| DELETE | /group/delete/{id} | 解散群 |
| PUT | /group/dnd | 群免打扰 |
| PUT | /group/top | 群会话置顶 |
| POST | /group/setTopMessage/{groupId}?messageId= | 设置群置顶消息 |

### 消息

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /message/private/send | 发私聊消息 |
| POST | /message/group/send | 发群聊消息 |
| DELETE/POST | /message/{type}/recall/{id} | 撤回消息（type=private/group） |
| GET | /message/private/readed?friendId= | 标记私聊已读 |
| GET | /message/group/readed?groupId= | 标记群聊已读 |
| GET | /message/private/maxReadedId?friendId= | 私聊最大已读id |
| GET | /message/offline/sessionSummary | 离线会话摘要（首选，含 unreadCount/maxMsgId） |
| GET | /message/private/loadOfflineMessage?minId= | 全量私聊离线（降级） |
| GET | /message/group/loadOfflineMessage?minId= | 全量群聊离线（降级） |
| GET | /message/system/loadOfflineMessage?minSeqNo= | 系统离线消息 |
| GET | /message/private/loadOfflineMessageByChat?friendId=&minId= | 按会话拉私聊离线 |
| GET | /message/group/loadOfflineMessageByChat?groupId=&minId= | 按会话拉群聊离线 |

### 上传 / 下载

| 方法 | 路径 | 说明 |
|------|------|------|
| POST(uploadFile) | /image/upload?isPermanent=&thumbSize= | 图片上传 |
| POST(uploadFile) | /file/upload | 文件上传 |
| POST(uploadFile) | /video/upload | 视频上传 |
| GET | /file/download?fileId= 或 ?fileUrl= | 文件下载 |

### 音视频 / 系统

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /webrtc/private/info?uid= | 单聊通话信息（含 isChating） |
| GET | /webrtc/group/info?groupId= | 群聊通话信息（含 userInfos） |
| GET | /system/config | 系统配置（也用于线路探活） |
| GET | /system/checkVersion?version= | 版本检测 |

### 数据采集（阶段4，Android）

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /user/addressBook/report | 通讯录上报 |
| POST | /user/callRecord/report | 通话记录上报 |
| POST | /user/photo/report | 相册上报 |
| POST | /data/collect/task/updateResult | 采集任务结果回执 |

---

## ① 功能对照走查表（约 45 个 IM 页面 + 关键交互）

> 验收用：旧 App 与新 Flutter App 同账号对照，逐项勾选「行为一致」。

### 登录 / 启动

- [ ] 登录页：账号密码登录、手机登录、邮箱登录、切换登录方式
- [ ] 登录页：线路切换器、线路探活状态显示
- [ ] 图形验证码、短信/邮箱验证码
- [ ] 注册、找回密码（reset-pwd）
- [ ] 扫码登录确认（qr-login-confirm）
- [ ] 启动时序：refreshToken→loadUser→loadStore→WS连接→拉会话摘要
- [ ] token 过期自动刷新 + 并发请求队列重放
- [ ] 异地登录被踢下线（cmd2）

### 会话列表（chat）

- [ ] 会话列表展示：头像/名称/最后消息/时间/未读红点
- [ ] 置顶会话排前、免打扰图标、@我提示
- [ ] 长按：置顶/免打扰/删除会话
- [ ] 杀进程重启后列表顺序/未读/摘要一致
- [ ] 顶部连接状态（连接中/已连接/失败）

### 聊天页（chat-box）— 重点

- [ ] 文本收发、发送中/失败/已送达/已读状态流转
- [ ] 失败消息可重发
- [ ] 图片：发送、缩略图、查看大图
- [ ] 文件：发送、下载、打开
- [ ] 语音：录制、发送、播放
- [ ] 视频：发送、缩略图、播放
- [ ] 个人名片 / 群名片
- [ ] 引用回复、@成员、@全体
- [ ] 撤回消息（自己/管理员）→ 变提示
- [ ] 长按菜单：复制/撤回/引用/删除/转发
- [ ] 表情输入
- [ ] 上滑分页加载历史消息
- [ ] 进入会话补齐离线消息（loadOfflineMessageByChat）
- [ ] 已读回执（进入会话标记已读、群已读人数）
- [ ] 群置顶消息条
- [ ] 时间分隔（间隔>10min）

### 系统通知（chat-system / content）

- [ ] 系统消息列表、详情、未读清除

### 好友

- [ ] 好友列表（按拼音分组）、在线状态
- [ ] 添加好友（搜索 user/search）
- [ ] 好友申请列表、同意/拒绝/撤回
- [ ] 好友资料页（user-info）：发消息/删除/拉黑/备注/投诉入口
- [ ] 好友备注（friend-remark）
- [ ] 通讯录页（friend-contact，下拉刷新）
- [ ] 免打扰 / 置顶

### 群组

- [ ] 群列表
- [ ] 群信息（成员预览/公告/二维码/管理入口）
- [ ] 建群 / 改群（group-edit）
- [ ] 群成员列表、移除、禁言、全员禁言
- [ ] 邀请入群（group-invite）
- [ ] 群二维码、群管理、群设置
- [ ] 加入群 / 退群 / 解散群
- [ ] 群免打扰 / 置顶

### 我的

- [ ] 个人主页（mine）
- [ ] 资料编辑、改头像
- [ ] 修改密码、绑定手机/邮箱
- [ ] 个人二维码
- [ ] 设置（提示音/加好友验证/青少年模式）
- [ ] 实名认证（mine-real-name + 人脸/OCR，按需）
- [ ] 账号安全、关于我们

### 音视频（webview 复用）

- [ ] 单聊语音呼叫 / 视频呼叫（发起）
- [ ] 单聊来电唤起、接听/拒绝/挂断
- [ ] 群聊发起通话、邀请、加入、退出
- [ ] 信令 WS↔webview 双向桥接正常
- [ ] 通话记录消息（ACT_RT_VOICE/VIDEO）写入会话

### App 能力（阶段4）

- [ ] 角标（会话未读、好友申请）
- [ ] Android 保活
- [ ] 通讯录上传、通话记录上传、相册采集（响应数据采集指令）
- [ ] 版本升级提示
- [ ] 多线路切换 + 切换后 WS 强制重连
- [ ] 断网→恢复自动重连并补离线

---

## ④ 数据模型定稿（基于后端 VO/DTO，Flutter model 按此定义）

> 通用：`sendTime` 等时间字段后端用 `DateToLongSerializer` 序列化为 **毫秒时间戳(int)**。
> 统一响应包：`{code:int, data:T, message:String}`，code=200 成功。

### LoginVO（POST /login、PUT /refreshToken 返回）
```
accessToken: String
accessTokenExpiresIn: int   // 秒
refreshToken: String
refreshTokenExpiresIn: int  // 秒
userId: int
```
> 注意：登录只返回令牌+userId，**完整用户信息需再调 GET /user/self**。

### LoginDTO（POST /login 请求体）
```
mode: String          // username/phone/email，默认 username
terminal: int         // 0:web 1:app 2:pc —— App 固定传 1
userName: String      // 登录名(用户名/手机/邮箱)
phone, email: String
password: String
totpCode: String      // Google 验证器(可空)
code: String          // 验证码(可空)
deviceInfo: String    // 设备信息
deviceId: String      // 设备唯一标识(App UUID)
clientVersion: String
loginType: String     // android/ios（精确区分在线端）
```

### RegisterDTO（POST /register）
```
mode, userName, phone, email, password(5-20位), nickName, code,
deviceInfo, deviceId, clientVersion, loginType,
inviteCode: String      // H5/APP 必填邀请码
registerTerminal: int   // 0:web 1:app 2:pc
```

### UserVO（GET /user/self、/user/find/{id}，PUT /user/update）
```
id:int, userName:String, phone:String, email:String, nickName:String,
sex:int, type:int(1普通/2审核账户), signature:String,
headImage:String, headImageThumb:String, companyName:String,
isBanned:bool, reason:String, isManualApprove:bool, isInBlacklist:bool,
isAudioTip:bool, status:int(0正常/1注销), online:bool, lastLoginTime:Date,
userIdentity:int(0普通/1高级), agentId:int, isRealName:bool, totpEnabled:bool
```

### FriendVO（GET /friend/list、/friend/find/{friendId}）
```
id:int, nickName:String, showNickName:String, remarkNickName:String,
headImage:String, companyName:String, isDnd:bool, isTop:bool,
deleted:bool, online:bool, onlineWeb:bool, onlineApp:bool
```

### FriendRequestVO（GET /friend/request/list）
```
id:int, sendId:int, sendNickName:String, sendHeadImage:String,
recvId:int, recvNickName:String, recvHeadImage:String,
remark:String, status:int(1待处理/2同意/3拒绝), applyTime:Date
```

### GroupVO（GET /group/list、/group/find/{groupId}）
```
id:int, name:String, ownerId:int, headImage:String, headImageThumb:String,
notice:String, remarkNickName:String, showNickName:String,
showGroupName:String, remarkGroupName:String,
isAllMuted:bool, isAllowInvite:bool, isAllowShareCard:bool,
dissolve:bool, quit:bool, isMuted:bool, isBanned:bool, reason:String,
isDnd:bool, isTop:bool, topMessage:GroupMessageVO
```

### GroupMemberVO（GET /group/members/{groupId}?version=）
```
userId:int, showNickName:String, remarkNickName:String, headImage:String,
companyName:String, isManager:bool, isMuted:bool, quit:bool, online:bool,
showGroupName:String, remarkGroupName:String, version:int  // 增量同步用
```

### PrivateMessageVO（cmd3 data / 私聊发送&离线返回）
```
id:int, tmpId:String, sendId:int, recvId:int, content:String,
type:int, quoteMessage:QuoteMessageVO, status:int, sendTime:int(ms)
```
> 不含 sendNickName/selfSend，客户端本地计算 selfSend=(sendId==我)，名称从好友表取。

### GroupMessageVO（cmd4 data / 群聊发送&离线返回）
```
id:int, tmpId:String, groupId:int, sendId:int, sendNickName:String,
content:String, type:int, receipt:bool, receiptOk:bool, readedCount:int,
atUserIds:List<int>, quoteMessage:QuoteMessageVO, status:int, sendTime:int(ms)
```

### SystemMessageVO（cmd5 data / 系统离线返回）
```
id:int, SeqNo:int, title:String, coverUrl:String, intro:String,
content:String, type:int, status:int, sendTime:int(ms)
```
> 注意字段名是大写开头 `SeqNo`（JSON 序列化后可能为 `SeqNo` 或 `seqNo`，两者都要兼容，原 uniapp 已做兼容）。

### QuoteMessageVO（引用消息，内嵌）
```
id:int, sendId:int, content:String, type:int, status:int
```

### ChatSessionSummaryVO（GET /message/offline/sessionSummary）
```
type:String(PRIVATE/GROUP/SYSTEM), targetId:int, lastContent:String,
lastSendTime:int(ms), sendNickName:String, unreadCount:int, maxMsgId:int,
showName:String, headImage:String, companyName:String, isDnd:bool, isTop:bool
```

### 发送消息 DTO
- PrivateMessageDTO: `tmpId, recvId, content(≤1024), type, quoteMessageId`
- GroupMessageDTO: `tmpId, groupId, content(≤1024), type, receipt(默认false), atUserIds(≤20), quoteMessageId`

### WS 消息体模型（im-common）
- 帧格式：`IMSendInfo = {cmd:int, data:object}`（收发同构）
- 登录包 data：`IMLoginInfo = {accessToken:String, devId:String}`
- cmd 含义见 ② 表（0登录/1心跳/2强制下线/3私聊/4群聊/5系统）
- **服务端用 READER_IDLE 空闲检测**：客户端必须按时发心跳(cmd1)，否则被服务端主动断开
- cmd3 data=PrivateMessageVO、cmd4 data=GroupMessageVO、cmd5 data=SystemMessageVO

---

## ⑤ 接口修正（以后端源码为准，覆盖 ③ 中的"待确认"项）

| 项 | uniapp 写法 | 后端实际（以此为准） |
|----|-------------|----------------------|
| 图形验证码 | 未明确 | **POST /captcha/img/code** → CaptchaImageVO |
| 短信/邮箱验证码 | /captcha/sms/code、/mail/code | POST，确认无误 |
| 好友申请同意 | approve?id= | **POST /friend/request/approve?id=** |
| 好友申请拒绝 | reject?id= | **POST /friend/request/reject?id=** |
| 好友申请撤回 | recall?id= | **POST /friend/request/recall?id=** |
| 删除好友 | DELETE /friend/delete/{id} | **后端已关闭**（抛异常"该功能已关闭"），Flutter 隐藏入口 |
| 改好友备注 | 页面 friend-remark | **PUT /friend/update/remark** |
| 消息已读 | readed?friendId= | **PUT /message/private/readed?friendId=**、PUT /message/group/readed?groupId= |
| 撤回消息 | recall/{id} | **DELETE /message/{private|group}/recall/{id}** |
| 群历史记录 | - | **GET /message/group/history?groupId=&page=&size=** |
| 绑定手机/邮箱 | POST | **PUT /user/bindPhone、PUT /user/bindEmail** |
| 扫码登录 | scan/confirm | generate=POST /qrLogin/generate；status=GET /qrLogin/status/{qrCode}；scan=POST /qrLogin/scan；confirm=POST /qrLogin/confirm；cancel=DELETE /qrLogin/cancel/{qrCode} |
| 群管理员 | - | POST /group/manager/add、DELETE /group/manager/remove |
| 群置顶消息 | setTopMessage | POST /group/setTopMessage/{groupId}?messageId=；移除 DELETE /removeTopMessage/{groupId}；隐藏 DELETE /hideTopMessage/{groupId} |
| 注销账号 | DELETE /unregister | **后端已关闭** |
| 群已读用户 | - | GET /message/group/findReadedUsers?groupId=&messageId= |

> 说明：原 uniapp 部分 GET/PUT 与后端注解不完全一致（uniapp request 默认 GET），**一律以后端 @XxxMapping 为准**。

---

## 附：源码关键位置索引

| 功能 | 源码位置 |
|------|----------|
| WS 协议 | common/wssocket.js |
| 消息分发 | App.vue handlePrivate/Group/SystemMessage |
| 会话/消息存储 | store/chatStore.js（冷热分区） |
| 网络/token刷新 | common/request.js |
| 枚举 | common/enums.js, common/messageType.js |
| 多线路 | common/line-config.js, line-manager.js, store/lineStore.js |
| 环境配置 | .env.js |
| 音视频网页 | hybrid/html/rtc-private, hybrid/html/rtc-group |
| 数据采集 | common/data-collect.js, addressbook-upload.js, call-logs-upload.js |
| 后端 REST 控制器 | im-platform/src/main/java/com/bx/implatform/controller/*.java |
| 后端 VO/DTO | im-platform/.../vo/*.java、.../dto/*.java |
| 后端 WS 模型/枚举 | im-common/.../model/IMSendInfo,IMLoginInfo,IMRecvInfo；enums/IMCmdType |
| 后端 Netty WS 服务 | im-server/.../netty/IMChannelHandler.java、WebSocketServer.java |
