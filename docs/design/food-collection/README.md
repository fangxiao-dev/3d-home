# 莹仔的美食收藏图鉴

2026-10-29 用户确认当前 **18 款一屏设计**。名称与介绍维护在[内容JSON](../../../godot/content/food-collection/content.json)，排布维护在[布局JSON](../../../godot/content/food-collection/layout-single-page.json)。HTML与游戏已共用18款内容并接入一屏详情；验证范围见[当前状态](../../status.md)。

## 改名字和介绍

1. 从项目根目录运行 `./scripts/Start-FoodCollectionPreview.ps1`。
2. 打开脚本输出的本地链接，默认 http://127.0.0.1:8769/ ，与8767游戏试玩分开。
3. 编辑 [content.json](../../../godot/content/food-collection/content.json)，保存后刷新网页，无需重新生成HTML。

日常只改 `title`、`subtitle`，以及条目的 `name`、`description`、`draft`。例如条目中的三个字段：

```json
{
  "name": "冰可乐",
  "description": "这里写你想展示的介绍。",
  "draft": false
}
```

这是字段示例，不要用它覆盖整个文件或完整条目。保留原有 `id` 和 `image`；JSON使用双引号，最后一项不加逗号。

| 字段 | 作用 |
| --- | --- |
| title / subtitle | 图鉴标题与副标题 |
| id | 稳定食物标识，与布局关联；改文案时不改它 |
| name | 贴纸提示与详情共用的名称 |
| description | 详情介绍，可直接修改；不必再编辑HTML |
| image | images/中的图片文件名；替换不同构图需同步布局主体边界 |
| draft | true显示示意文案标记，false隐藏标记和非聊天原话说明 |

初始18款介绍全部沿用原型示意文案。将draft改为false表示你确认用于展示，不代表系统核实过原话；真实引文需核对说话人和上下文。名字、介绍或draft变化不会改变位置、体量和提示方向。

页面通过HTTP读取JSON，不能依赖双击file://文件自动加载。JSON格式错误或图片缺失会显示具体错误，不静默回退旧文案。预览服务只绑定本机，限定提供图鉴页面、两份JSON和内容引用图片，不提供私人参考或项目目录列表。

## 当前18款与选图

以下是本次确认时的清单；之后显示名称以content.json为准。

| ID | 食物 | 当前图片 |
| --- | --- | --- |
| pad-krapao | 泰国打抛饭 | [pad-krapao-v1-clean.png](../../../godot/content/food-collection/images/pad-krapao-v1-clean.png) |
| subway | 赛百味 | [subway-v1-clean.png](../../../godot/content/food-collection/images/subway-v1-clean.png) |
| bullfrog | 牛蛙 | [bullfrog-piled-v4.png](../../../godot/content/food-collection/images/bullfrog-piled-v4.png) |
| sweet-sour-ribs | 糖醋排骨 | [sweet-sour-ribs-v1-clean.png](../../../godot/content/food-collection/images/sweet-sour-ribs-v1-clean.png) |
| street-snack | 街边小吃 | [street-snack-v1.png](../../../godot/content/food-collection/images/street-snack-v1.png) |
| hot-dry-noodles | 热干面 | [hot-dry-noodles-v1-clean.png](../../../godot/content/food-collection/images/hot-dry-noodles-v1-clean.png) |
| fufu | 非洲 Fufu | [fufu-v3-clean.png](../../../godot/content/food-collection/images/fufu-v3-clean.png) |
| iced-cola | 冰可乐 | [iced-cola-v1.png](../../../godot/content/food-collection/images/iced-cola-v1.png) |
| spicy-wings | 麦辣鸡翅 | [spicy-wings-v1.png](../../../godot/content/food-collection/images/spicy-wings-v1.png) |
| mcspicy-burger | 麦辣鸡腿堡 | [mcspicy-burger-v1-clean.png](../../../godot/content/food-collection/images/mcspicy-burger-v1-clean.png) |
| durian | 榴莲 | [durian-selected-v2.png](../../../godot/content/food-collection/images/durian-selected-v2.png) |
| lava-cake | 巧克力熔岩 | [lava-cake-v1-clean.png](../../../godot/content/food-collection/images/lava-cake-v1-clean.png) |
| chocolate-muffin | 星巴克巧克力麦芬 | [chocolate-muffin-v1-clean.png](../../../godot/content/food-collection/images/chocolate-muffin-v1-clean.png) |
| ice-cream-sandwich | 饼干夹心冰淇淋 | [ice-cream-sandwich-v1-clean.png](../../../godot/content/food-collection/images/ice-cream-sandwich-v1-clean.png) |
| pineapple-bun | 菠萝油 | [pineapple-bun-v1-clean.png](../../../godot/content/food-collection/images/pineapple-bun-v1-clean.png) |
| coconut-rolls | 椰子卷 | [coconut-rolls-v1.png](../../../godot/content/food-collection/images/coconut-rolls-v1.png) |
| coconut-latte | 瑞幸生椰拿铁 | [coconut-latte-v1-clean.png](../../../godot/content/food-collection/images/coconut-latte-v1-clean.png) |
| pocky | Pocky 百奇 | [pocky-baiqi-v1-clean.png](../../../godot/content/food-collection/images/pocky-baiqi-v1-clean.png) |

椰子卷、麦辣鸡翅已入选；三文鱼、扣肉、千层面暂不纳入，旧图保留。好欢螺和芝士蛋糕仍是候选。原C02取消独立故事，以Pocky百奇条目呈现。

## 已确认的画面和操作

- 一屏展示18款，三条大致行带，高低错位、不等间距、大小穿插；不是等高卡片或均匀网格。上方打抛饭、赛百味、牛蛙、排骨、街边小吃；中间热干面、Fufu、可乐、辣翅、汉堡、榴莲；下方甜点、椰子卷、拿铁与百奇。
- 蛋糕与汉堡视觉体量接近，麦芬和夹心冰淇淋明显小且相邻；拿铁与百奇高度接近。椰子卷已放大15%、街边小吃缩小10%、牛蛙放大15%。精确位置与体量以layout-single-page.json为准。
- 牛蛙采用自然堆叠的肉和腿段，不摊开排列完整腿形；Fufu是米黄色不规则团块配糊状酱汁；榴莲使用用户选定的多瓣图；冰可乐只有瓶外薄霜、水珠和淡寒气；街边小吃是纸碗中的火腿肠与豆腐，适度提亮而不鲜红油亮。
- 平时只显示食物，悬停／聚焦显示名称。点击或Enter打开居中详情，图鉴背景模糊，左图右文；窄屏上下排列。
- 关闭按钮、Esc或背景遮罩返回原贴纸焦点；详情保持焦点。暖纸底、白边、轻微倾斜保留。1366×768与1920×1080的目标是完整一屏。

## HTML与游戏的版本边界

| 对象 | 当前职责 |
| --- | --- |
| [content.json](../../../godot/content/food-collection/content.json) | 18款共用内容源，HTML与Godot均按id读取 |
| [layout-single-page.json](../../../godot/content/food-collection/layout-single-page.json) | 一屏布局，按id关联内容，改名字不改布局 |
| [一屏HTML](gallery-single-page.html) | 当前设计与详情交互预览，通过本地HTTP打开 |
| [catalog.json](../../../godot/content/food-collection/catalog.json)、[旧纵向HTML](gallery.html) | 旧16款版本，本轮保持原样 |
| Godot游戏 | 已迁移18款一屏与详情；当前导出和抽查边界以项目状态为准 |

本轮不重做素材。用户追加要求游戏同步最新设计：Godot读取同一content.json与layout-single-page.json，重新生成必要字形并导出。文件存在不代表运行验证通过，交付证据维护在项目状态。

## 游戏同步：18款一屏与详情

用户于本轮明确追加批准并已完成，替代旧16款纵向滚动呈现：

- 继续使用右下图鉴图标／G，开发预览默认18款全收齐，不写正式存档；正式发现按稳定id处理，零收藏隐藏、首个有效食物激活、重复发现幂等。
- 原生Godot按当前HTML的1000×620画布等比缩放，一屏容纳全部18款；保留自由穿插和相对体量，不重新排成网格。图鉴不再滚动。
- 默认只看食物，悬停／键盘聚焦显示名称；点击或Enter开左图右文详情。详情居中，背景图鉴模糊压暗，小屋上下文仍保留。
- 内容与布局按id关联，名称、介绍、图片、draft直接来自共享JSON。draft为false时隐藏示意标记；游戏更新资源后运行 `python scripts/Prepare-ReadingFont.py` 和 `./scripts/Build.ps1`，即可使用改过的文案，不在GDScript复制一份文案。
- 详情关闭按钮、背景点击或Esc只返回图鉴并恢复原食物焦点；图鉴关闭按钮或下一次Esc再返回小屋。保留游览／坐姿原状态、现有鼠标授权机制、失焦安全关闭和背包等面板互斥。
- 验证18项与布局保真、首次发现／幂等、两层Esc、键盘／点击、示意开关、改名位置稳定、输入隔离；检查双桌面尺寸实际网页画面和可执行路径。未走通的真实鼠标捕获／自然坐姿路径继续如实记录，不以引擎模拟代替。

## 正式玩法与待定项

发现任意第一种食物后激活图鉴，零收藏时隐藏入口，重复发现不重复累计；图鉴独立于王冠、蛋糕和生日仪式条件。当前游戏全收集只是开发预览，不写正式存档。

后续仍需确定场景食物位置、发现动作、未发现项显示及正式收藏跨刷新保存。主要空间可互动，厨房仅展示；新增入口不能挡住冰箱与餐桌的蛋糕操作。现实食物、兑换券和二维码仍属可选方向。

## 原稿、参考与历史

- [v2原稿](source-v2.md)、[原始合辑](sticker-atlas.png)、[旧设计与验证记录](legacy-design-notes.md)只供追溯，当前规则以本页为准。
- [牛蛙](references/bullfrog.png)、[街边小吃](references/street-snack.png)、[百奇包装](references/pocky-milk-package.png)、Fufu [图1](references/fufu-01.png)／[图2](references/fufu-02.png)／[图3](references/fufu-03.png)为用户参考，不由预览服务对外提供。
- 旧游戏检查及鼠标捕获缺口继续记录在当前状态，不能由本轮HTML检查代替。
