# Auth 页设计 Token（从 im-uniapp scss 提取）

> 来源文件：
> - `im-uniapp/common/auth-page.scss`（登录/注册共用）
> - `im-uniapp/im-var.scss`（全局变量）
> - `im-uniapp/pages/common/reset-pwd.vue` scoped scss（找回密码独立样式）
> - `im-uniapp/components/line-switcher/line-switcher.vue` scoped scss
> - `im-uniapp/components/nav-bar/nav-bar.vue` scoped scss
>
> **rpx → Flutter 逻辑像素换算**：`dp = rpx × screenWidth / 750`
> 以 iPhone 12/13 宽度 390px 为参考：`dp ≈ rpx × 0.52`
> Flutter 实现建议封装 `Rpx.of(context, rpx)` 按屏宽动态换算。

---

## 1. 色板

### 1.1 Auth 专用（auth-page.scss）

| Token | 值 | 用途 |
|-------|-----|------|
| `authHeroStart` | `#262a8f` | Hero 渐变起点 |
| `authHeroMid` | `#3e45d7` | Hero 渐变中点 / 主色 |
| `authHeroEnd` | `#6e73e1` | Hero 渐变终点 |
| `authAccent` | `#3e45d7` | 主色、链接、聚焦边框 |
| `authAccentDeep` | `#2f35b5` | 聚焦态图标色 |
| `authAccentSoft` | `#e7e8fb` | 浮层顶部横条渐变 |
| `authSheetBg` | `#f5f5fd` | 浮层渐变起点 |
| `authSheetBgEnd` | `#eeeefb` | 浮层渐变终点 |
| `authPageBg` | `#e8e8f6` | 页面底色 |
| `authText` | `#1f2937` | 输入文字 |
| `authTextMuted` | `#6b7280` | 次要文字 |
| `authPlaceholder` | `#9ca3af` | placeholder |
| `authInputBg` | `#ffffff` | 输入框背景 |
| `authInputBorder` | `#dcddf4` | 输入框边框 |
| `authInputFocus` | `#3e45d7` | 聚焦边框 |

### 1.2 全局（im-var.scss）

| Token | 值 | 用途 |
|-------|-----|------|
| `imColorPrimary` | `#3e45d7` | TabBar 选中色、全局主色 |
| `imTextColorLight` | `#6a6a6a` | 次要文字 |
| `imBg` | `#eef0f5` | 普通页面背景 |
| `imNavBarBg` | `#ffffff` | 导航栏背景 |
| `imBgActive` | `#f7f8fc` | 图标底座背景（找回密码页） |
| `imBorderLight` | `#EDEDED` | 导航栏底边 |

---

## 2. Auth Hero 区（登录/注册）

| 属性 | scss 值 | 390px 参考 dp |
|------|---------|---------------|
| min-height | 640rpx | 333 |
| padding-top | 150rpx (+ statusBar APP) | 78 |
| padding-left/right | 56rpx | 29 |
| padding-bottom | 170rpx | 88 |
| background | `linear-gradient(152deg, #262a8f 0%, #3e45d7 50%, #6e73e1 100%)` | — |
| 装饰圆 ::before | 400×400rpx, top:-100, right:-80, radial white 12% | — |
| 装饰圆 ::after | 340×340rpx, bottom:-140, left:-100, radial purple 22% | — |

### 文字

| 元素 | font-size | weight | color | letter-spacing | margin-bottom |
|------|-----------|--------|-------|----------------|---------------|
| `.brand-name` | 72rpx → 37dp | 700 | `#fff` | 10rpx → 5 | 28rpx → 15 |
| `.hero-title` | 40rpx → 21dp | 500 | `rgba(255,255,255,0.96)` | 2rpx | 16rpx → 8 |
| `.hero-sub` | 26rpx → 14dp | normal | `rgba(224,235,255,0.92)` | 1rpx | — |

---

## 3. Auth Sheet 浮层

| 属性 | scss 值 | 390px 参考 dp |
|------|---------|---------------|
| margin-top | -64rpx | -33（上移盖住 Hero） |
| border-radius | 48rpx 48rpx 0 0 | 25 25 0 0 |
| padding | 56rpx 48rpx 64rpx | 29 25 33 |
| background | `linear-gradient(180deg, #f5f5fd, #eeeefb)` | — |
| box-shadow | `0 -12rpx 48rpx rgba(43,47,156,0.08)` | — |
| 顶部横条 ::before | 64×6rpx, top:20, 居中, 渐变 `#e7e8fb→#3e45d7→#e7e8fb`, opacity 0.85 | 33×3 |

---

## 4. Auth 输入框 `.form-item`

| 属性 | scss 值 | 390px 参考 dp |
|------|---------|---------------|
| height | 108rpx | 56 |
| padding | 0 24rpx 0 20rpx | 0 12 0 10 |
| margin-bottom | 28rpx | 15 |
| border-radius | 20rpx | 10 |
| border | 2rpx solid `#dcddf4` | 1 |
| background | `#ffffff` | — |
| **聚焦** border | `#3e45d7` | — |
| **聚焦** box-shadow | `0 0 0 6rpx rgba(62,69,215,0.1)` | 0 0 0 3 |

### 图标底座 `.icon-wrapper`

| 属性 | 值 |
|------|-----|
| size | 56×56rpx → 29dp |
| margin-right | 18rpx → 9 |
| border-radius | 50% |
| background | `linear-gradient(135deg, rgba(62,69,215,0.1), rgba(110,115,225,0.06))` |
| icon font-size | 34rpx → 18 |
| icon color | `#3e45d7` |

### 输入文字

| 属性 | 值 |
|------|-----|
| font-size | 32rpx → 17 |
| color | `#1f2937` |
| placeholder size | 30rpx → 16 |
| placeholder color | `#9ca3af` |

### 密码可见切换 `.icon-suffix`

| 属性 | 值 |
|------|-----|
| font-size | 36rpx → 19 |
| padding | 8rpx → 4 |
| color | `#9ca3af` |

---

## 5. Auth 主按钮 `.submit-btn`

| 属性 | scss 值 | 390px 参考 dp |
|------|---------|---------------|
| margin-top | 48rpx | 25 |
| height | 100rpx | 52 |
| border-radius | 50rpx | 26（胶囊） |
| background | `linear-gradient(135deg, #3e45d7 0%, #3e45d7 55%, #6e73e1 100%)` | — |
| box-shadow | `0 12rpx 32rpx rgba(62,69,215,0.35)` | — |
| active scale | 0.985 | — |
| 文字 size | 34rpx → 18 | weight 600, color `#fff`, letter-spacing 4rpx |

---

## 6. Auth 底部链接 `.nav-tool-bar`

| 属性 | 值 |
|------|-----|
| margin-top | 40rpx → 21 |
| highlight font-size | 30rpx → 16 |
| highlight color | `#3e45d7` |
| highlight weight | 600 |

---

## 7. 线路切换 chip（line-switcher.vue）

| 状态 | background | border | dot/status color |
|------|------------|--------|------------------|
| 默认 | `#f5f6f8` | `rgba(0,0,0,0.06)` | dot connected `#3e45d7` |
| open | `#ececfb` | `rgba(62,69,215,0.2)` | — |
| connecting | `#fff8ed` | `rgba(243,167,63,0.25)` | spinner `#f3a73f`, text `#c8872b` |
| failed | `#fff5f5` | `rgba(228,61,51,0.2)` | dot `#e43d33`, text `#e43d33` |

| 属性 | 值 |
|------|-----|
| padding | 4rpx 16rpx |
| border-radius | 100rpx（胶囊） |
| line-name font-size | 24rpx, color `#333` |
| line-status font-size | 22rpx |
| dot size | 12×12rpx |

---

## 8. 找回密码页（reset-pwd.vue，**独立样式，非 auth-page**）

| 属性 | scss 值 | 说明 |
|------|---------|------|
| content margin-top | 60rpx | nav-bar 下方 |
| content padding | 0 60rpx | 左右 |
| form-item height | 100rpx | 比 auth 略矮 |
| form-item border-radius | 25rpx | 比 auth 更圆 |
| form-item background | `rgba(255,255,255,0.9)` | 半透明白 |
| form-item border | 2rpx transparent → focused `#3e45d7` | — |
| form-item shadow | `0 4rpx 20rpx rgba(0,0,0,0.05)` | — |
| focused shadow | `0 8rpx 32rpx rgba(62,69,215,0.15)` + translateY(-2rpx) | — |
| icon-wrapper | 60×60rpx, bg `$im-bg-active` (#f7f8fc) | — |
| captcha-btn | 28rpx, color primary, padding 8×16, radius 20, bg rgba(primary,0.1) | — |
| submit-btn | height 100rpx, radius 50rpx, shadow rgba(primary,0.3) | 用 im.scss 全局 primary 渐变 |
| subtitle | 28rpx, `$im-text-color-light`, opacity 0.8 | 按钮下方 |

---

## 9. 导航栏 nav-bar.vue

| 属性 | 值 |
|------|-----|
| height | `$im-nav-bar-height` = **50px**（固定 px，非 rpx） |
| background | `#ffffff` |
| border-bottom | 1rpx `#EDEDED` |
| title font-size | `$im-font-size-large` = 34rpx → 18 |
| back padding | 0 12px |

---

## 10. TabBar（pages.json）

| 属性 | 值 |
|------|-----|
| color | `#000000` |
| selectedColor | `#3e45d7` |
| 图标 | `static/tabbar/chat.png` / `friend.png` / `mine.png` + `*_active.png` |
| 文案 | 消息 / 通讯录 / 我的 |

---

## 11. Flutter 实现映射建议

```
lib/theme/
  auth_colors.dart      ← §1 色板常量
  rpx.dart              ← rpx→dp 换算工具
lib/widgets/auth/
  auth_hero.dart        ← §2 Hero + 装饰圆
  auth_sheet.dart       ← §3 浮层 + 顶部横条
  auth_field.dart       ← §4 输入框（聚焦态、图标底座）
  gradient_button.dart  ← §5 渐变胶囊按钮
  line_switcher_chip.dart← §7 线路 chip
  im_nav_bar.dart       ← §9 自定义导航栏
```

每页 DoD：Flutter 组件使用的数值必须能在此文档找到对应 scss 来源行。
