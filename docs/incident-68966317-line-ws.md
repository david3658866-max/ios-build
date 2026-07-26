# 68966317 线路/WS 排查结论（2026-07-25）

> 只读排查产出；未改业务代码。原始查询脚本：
> - my-im-admin/deploy/xingyu/_probe-68966317-line-events.js
> - my-im-admin/deploy/xingyu/_probe-68966317-after-switch.js
> - my-im-admin/deploy/xingyu/_probe-line1-http-wss-prod.js

## 1. 结论摘要

| 项 | 结论 |
|---|---|
| 探活只见线路1 | **设计如此**：1.0.1 已登录仅 current_line_check 探当前线 |
| WS 反复断 | 1.0.1 Android 卡在 line1=zenty.bgznp.com，**81 条 ws_state 全失败，从未 connected** |
| 手切是否恢复 | **未验证成功**：手切发生在另一台 1.0.3，且该端未进入有效登录 WS 会话 |
| 源站/CDN 线路 | 生产侧 HTTP ping 与 WSS Upgrade 均正常（各线 200 / 101） |

## 2. 设备拆分（同一 userId）

| 版本 | 平台 | 行为 |
|---|---|---|
| **1.0.1** | Android | 全部 ws_state + 绝大多数 current_line_check；**问题主体** |
| 1.0.3 | Android | 登录页全量探活、注册/登录失败、**手动切到 line2** |
| 1.0.3 | iOS | 全量探活 + auth 失败，无 WS |

事件总量 224（09:03–11:04）。地区含山西移动/晋城 WiFi 等。

## 3. 手切验证

- 10:49:24 auth_request_failover → line2 castle.scnjrm.com（1.0.3）
- 10:58:57 manual_switch → line2 castle.scnjrm.com（1.0.3）

切线后没有 line2 的 ws_state；11:04 仍是 1.0.1 在 line1 上 connecting→authing→disconnected。

客服话术（针对卡死设备 1.0.1）：
1. 升级到 >=1.0.3（更好当前最新包）
2. 打开线路面板，手动切到备用线（castle / muvin / nuvor）
3. 观察消息是否恢复

## 4. 后台日志对照

- ws_state：81 条，全部 line1 / zenty.bgznp.com / success=0；connecting×27 + authing×27 + disconnected×27；0 次 connected
- line_probe_result：line1 current_line_check 成功 28 次（1.0.1）；auth_probe_all 覆盖 line1–12（1.0.3）
- line_switch：仅 2 次，均到 line2，且来自 1.0.3
- 含义：HTTPS 探活通 ≠ WS 可用；WS 失败不触发切线（与代码一致）
- 补充：能进入 authing 说明 WSS 升级多数已成功，更像 WS 登录鉴权未完成（8s 超时），而非纯线路全阻断。1.0.1 仍上报过程态，会放大失败观感。

## 5. 运维探测

从生产源站探测（非山西移动出口）：

| 线路 host | HTTPS /api/line/ping | WSS /im Upgrade |
|---|---|---|
| zenty.bgznp.com | 200 ~0.4s | 101 |
| castle.bgznp.com | 200 | 101 |
| muvin.bgznp.com | 200 | 101 |
| nuvor.bgznp.com | 200 | 101 |

- im-platform / im-server：active；27418 ping OK；27893 监听中
- DNS：zenty→206.119.118.65；其余→206.119.118.67（CDN）
- 运维判断：源站与 CDN 入口健康；优先推动用户升包 + 手切备用线。

## 6. 产品排期

见 ws-failover-plan.md。
