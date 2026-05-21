# Fringer Icon Prompts

本文件夹包含 Fringer 应用所需的所有自定义图标的 AI 生成 Prompt。

每个文件包含：用途说明、技术要求（尺寸/格式）、中英文 Prompt。

## 图标清单

| # | 文件 | 图标 | 优先级 | 说明 |
|---|------|------|--------|------|
| 01 | AppIcon | 应用主图标 | **必须** | 1024x1024 主图，缩放为 10 个尺寸 |
| 02 | MenuBarIcon | 菜单栏图标（常态） | **必须** | 18x18 pt，纯黑 template，透明背景 |
| 03 | MenuBarIcon_Active | 菜单栏图标（激活态） | **必须** | 同上，Fringer Bar 展开时显示 |
| 04 | DMG_Background | DMG 安装背景图 | 推荐 | 600x400，分发安装包用 |
| 05 | PermissionsIllustration | 权限引导插图 | 推荐 | 128x128 pt，首次启动引导 |
| 06 | EmptyState_Presets | 预设空状态插图 | 可选 | 96x96 pt，无预设时显示 |
| 07 | EmptyState_Triggers | 触发器空状态插图 | 可选 | 96x96 pt，无触发器时显示 |

## 品牌色参考
- 主色：深靛蓝 → 紫色/青色渐变
- 前景：白色/浅色
- 强调色：青色 (teal) 或亮紫色
- 风格：现代、极简、高端

## 注意
- 01-03 是 **必须** 的，没有它们应用看起来不完整
- SF Symbols（齿轮、键盘、放大镜等 22 个系统图标）不需要生成，macOS 自带
- 生成后的图标放入 `Fringer/Resources/Assets.xcassets/` 对应的 imageset 中
