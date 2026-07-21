# 验收自动化总览

> 不可能 100% 替代真机（相机、铃声、RTC、手势、双机协作仍需人眼）。  
> 目标：**你验收前，主机一条命令把能自动查的都查完**；你只测 [human-only-acceptance.md](./human-only-acceptance.md) 里列的项。

## 四层能力

| 层 | 做什么 | 能抓到的例子 |
|----|--------|----------------|
| **L1 逻辑/Store** | 单测 dispatcher、离线、发送队列、鉴权 | 撤回未入库、tmpId 过长、未读未清 |
| **L2 Widget 契约** | 泵页面/组件测行为与布局 | 路由串页、工具栏四列、长按菜单项 |
| **L3 API 真链路** | 登录后 GET/POST 真实接口 | JSON 解析炸、发送 500、离线接口 404 |
| **L4 真机日志** | adb 冷启动审计 | 白屏、bootstrap 卡住、WS 未连 |

另加：**静态版面扫描**（`tool/parity_layout_scan.dart`）防整屏分列等陷阱。

## 功能注册表（防漏项）

`tool/feature_registry.dart` 登记 **50+ 功能点**（对照 uniapp），每项标明：

- 优先级 P0/P1
- 自动化类型 + 对应测试文件
- 是否 **须真人验收** 及原因

`test/feature_coverage_test.dart` 保证：**每个 P0 要么有自动化，要么已登记真人项**。

报告自动生成：

```powershell
dart run tool/generate_acceptance_report.dart
```

产出 `docs/acceptance-matrix.md`、`docs/human-only-acceptance.md`。

## 一条命令（主机，约 1～3min）

```powershell
cd im-flutter
powershell -File tool/run_host_verify.ps1
```

顺序：功能覆盖率 → 全量 `flutter test` → 版面扫描 → m4 只读 API → 发送探测 → 生成验收报告。

## 真机一条命令（约 40s，勿用 flutter install）

```powershell
powershell -File tool/quick_device_verify.ps1 -SkipBuild
```

## 本地真机调试运行

```powershell
powershell -File scripts/run-device.ps1 -DeviceId <设备ID>
```

该入口会先恢复 `adb reverse`，包含 API、WS、Web/H5 与媒体端口 `9001`。本地调试图片或头像不显示时，先检查这个入口是否被绕过。

## 你验收时怎么做

1. 先跑 `run_host_verify.ps1`，全绿再装包
2. 打开 **`docs/human-only-acceptance.md`**，只勾里面列的真人项（约 20 项）
3. 细项对照仍可用 [m3-device-checklist.md](./m3-device-checklist.md) 10 章

## 新增功能时

1. 在 `tool/feature_registry.dart` 登记功能
2. 能单测/契约测/API 测的补测试；不能的标 `manualOnly` + 原因
3. 版面类反模式加到 `tool/parity_layout_scanner.dart`

## 相关文件

| 文件 | 用途 |
|------|------|
| `tool/feature_registry.dart` | 功能点总表 |
| `test/feature_coverage_test.dart` | P0 不得漏登 |
| `test/m4_api_readonly_test.dart` | 只读 API 扩展 |
| `tool/generate_acceptance_report.dart` | 生成矩阵与真人清单 |
| `docs/acceptance-matrix.md` | 模块×自动化对照（自动生成） |
| `docs/human-only-acceptance.md` | 须真人项（自动生成） |
| `tool/run_host_verify.ps1` | 主机总入口 |
| `tool/quick_device_verify.ps1` | 真机总入口 |
