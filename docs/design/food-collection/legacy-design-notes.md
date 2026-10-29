# 历史记录：16 款游戏预览与一屏原型迭代

本页保留2026-10-29整理前的设计与验证记录，包含已被替代的中间决定；当前18款设计与编辑入口以[README](README.md)为准。

---

# 莹仔的美食收藏图鉴

2026-10-29 更新。当前规则以本页最新用户确认为准；[v2 原稿](source-v2.md)与[原始 16 款合辑](sticker-atlas.png)保留原样，供追溯。

## 已确认的体验

- 贴纸集中为一个美食图鉴，发现第一张贴纸时激活。场景食物的具体位置待定。
- 原 C02 百醇并入图鉴，取消独立故事和独立彩蛋流程。本次用户提供牛奶味百奇包装，并确认图鉴名称为 **Pocky 百奇**；包装图内保留参考上的 **Pocky** 品牌拼写。
- 当前共 **16 款**：在原合辑基础上加入 Pocky 百奇、扣肉替换为牛蛙，千层面暂不纳入。好欢螺、椰香卷、芝士蛋糕仍是候选，不自动加入。
- 图鉴独立于情书、王冠、蛋糕与生日仪式条件，不以收集数量控制主体验。
- 本轮采用集中图鉴，不向时间画册或情书书页添加贴纸。现实食物、兑换券与二维码仍是可选方向。

## 已制作的独立贴纸

另有[一屏拼贴与点击详情原型](gallery-single-page.html)：当前 **18 款**。保留自由拼贴的高低错位、不等间距与实物体量关系。上方依次为打抛饭、赛百味、牛蛙、排骨、街边小吃（火腿肠与豆腐）；第二行大致为热干面、Fufu、冰可乐、麦辣鸡翅、汉堡、榴莲。下方麦芬与饼干夹心冰淇淋相邻，仍是小体量。

三文鱼已按用户最新决定暂移出一屏原型，由[街边小吃](../../../godot/content/food-collection/images/street-snack-v1.png)替代，原三文鱼图片保留；小吃依据[实拍](references/street-snack.png)适度提亮，采用奶油色与金棕色，不使用鲜红油亮表现。排骨放大10%、生椰拿铁放大34%，拿铁主体高度114.3与Pocky114.1接近。巧克力熔岩宽135、汉堡132.25、椰子卷105.8的既有大小保持。新增[麦辣鸡翅](../../../godot/content/food-collection/images/spicy-wings-v1.png)为翅中与翅根一对，组合宽105.8约为汉堡80%，支持同样的悬停名称与背景模糊详情，介绍标为示意文案。

原型独立引用 [新版榴莲](../../../godot/content/food-collection/images/durian-selected-v2.png)与[椰子卷](../../../godot/content/food-collection/images/coconut-rolls-v1.png)，不修改共享 16 款清单、旧 HTML 或游戏；游戏仍为原 16 款，椰子卷尚未迁入。18 项唯一、旋转后的主体范围无重叠、本地引用检查通过；实际浏览器视觉与点击仍待验证。

游戏接入已批准，见下方“游戏内图鉴：已收齐预览版”；实现与验证进度以[当前状态](../../status.md)为准。

**当前 16/16 款独立 PNG 已齐。** [打开 HTML 贴纸图鉴](gallery.html)查看全套；HTML 中点击贴纸可打开原图，游戏内仅供欣赏。

页面按用户提供的旅行手账合辑改为暖纸底、彩色名称纸条、错落大小与轻微倾斜，并点缀少量手绘花草和星星；取消素材目录式编号、分隔线及等高卡片。

图片唯一存放在 godot/content/food-collection/images/；[当前素材清单](../../../godot/content/food-collection/catalog.json)是本版 16 款映射。扣肉与千层面旧图片保留为历史素材，不在当前清单或图鉴中。

| 条目 | 当前图片 |
| --- | --- |
| 泰国打抛饭 | [pad-krapao-v1-clean.png](../../../godot/content/food-collection/images/pad-krapao-v1-clean.png) |
| 赛百味 | [subway-v1-clean.png](../../../godot/content/food-collection/images/subway-v1-clean.png) |
| 牛蛙 | [bullfrog-v2.png](../../../godot/content/food-collection/images/bullfrog-v2.png) |
| 热干面 | [hot-dry-noodles-v1-clean.png](../../../godot/content/food-collection/images/hot-dry-noodles-v1-clean.png) |
| 糖醋排骨 | [sweet-sour-ribs-v1-clean.png](../../../godot/content/food-collection/images/sweet-sour-ribs-v1-clean.png) |
| 非洲 Fufu | [fufu-v3-clean.png](../../../godot/content/food-collection/images/fufu-v3-clean.png) |
| 三文鱼 | [salmon-v1-clean.png](../../../godot/content/food-collection/images/salmon-v1-clean.png) |
| 麦辣鸡腿堡 | [mcspicy-burger-v1-clean.png](../../../godot/content/food-collection/images/mcspicy-burger-v1-clean.png) |
| 榴莲 | [durian-v1-clean.png](../../../godot/content/food-collection/images/durian-v1-clean.png) |
| 巧克力熔岩 | [lava-cake-v1-clean.png](../../../godot/content/food-collection/images/lava-cake-v1-clean.png) |
| 星巴克巧克力麦芬 | [chocolate-muffin-v1-clean.png](../../../godot/content/food-collection/images/chocolate-muffin-v1-clean.png) |
| 菠萝油 | [pineapple-bun-v1-clean.png](../../../godot/content/food-collection/images/pineapple-bun-v1-clean.png) |
| 饼干夹心冰淇淋 | [ice-cream-sandwich-v1-clean.png](../../../godot/content/food-collection/images/ice-cream-sandwich-v1-clean.png) |
| 瑞幸生椰拿铁 | [coconut-latte-v1-clean.png](../../../godot/content/food-collection/images/coconut-latte-v1-clean.png) |
| 冰可乐 | [iced-cola-v1.png](../../../godot/content/food-collection/images/iced-cola-v1.png) |
| Pocky 百奇 | [pocky-baiqi-v1-clean.png](../../../godot/content/food-collection/images/pocky-baiqi-v1-clean.png) |

牛蛙按用户实拍制作，只保留少量肉块、细长蛙腿与少量椒圈，酱汁之间留出空隙，不复刻密集堆满的配料。Fufu 保持米黄色不规则团块与橙黄糊状酱汁。贴纸白边是保留的视觉风格；此前已按用户授权用本地脚本清除明显游离白点，主体像素保持不变。

名称、图片与本地链接已核对。新版页面尚无浏览器视觉验收证据（此前 file:// 打开受浏览器工具策略限制）；牛蛙和整体排版待用户查看，印刷与游戏显示尚未验证。

## 冰可乐与主体比例（2026-10-29 已批准并实施）

小瓶可乐命名为“冰可乐”，保留瓶型、红色标签和清晰品牌，瓶外增加薄霜、冷凝水、瓶肩淡寒气；不加入冰块。新图为 iced-cola-v1.png，旧可乐保留追溯，其余 15 张图未改。

桌面采用五排 3＋3＋3＋4＋3，按下表从左到右排列。窄屏按相同阅读顺序转两列，保持共同缩放基准。

| 排 | 顺序 | 主体宽度单位（汉堡=100） |
| --- | --- | --- |
| 1 | 泰国打抛饭、赛百味、牛蛙 | 140、135、145 |
| 2 | 热干面、糖醋排骨、非洲 Fufu | 140、125、140 |
| 3 | 三文鱼、麦辣鸡腿堡、榴莲 | 120、100、115 |
| 4 | 巧克力熔岩、星巴克巧克力麦芬、菠萝油、饼干夹心冰淇淋 | 75、62、80、65 |
| 5 | 瑞幸生椰拿铁、冰可乐、Pocky 百奇 | 65、44、60 |

可乐为窄高小瓶，整体视觉体量与麦芬、冰淇淋同档；这是一组直觉比例，不是实物严格等比例。名称标签保持独立字号并靠近主体，不随食物一起缩小。

清单各条目的 display 保存排次、主体宽度单位、可见主体边界、倾斜与标签色。主体边界按 alpha≥128 的最大连通区域计算，CSS 定位整张原图，不裁切 PNG，不因透明留白多而缩小主体；低透明寒气仍保留可见。页面取消依赖第几个元素的尺寸规则，尺寸跟随食物条目。

静态核对通过：16 项与顺序正确、链接存在、15 张非可乐图逐字节未变。主控已查看冰可乐生成图；独立只读复核确认顺序、分组、主体尺寸与图片保真符合计划，未发现 P1/P2。页面实际比例仍待真实浏览器视觉确认，未绕过此前的 file:// 工具限制。

## 素材依据

- [牛蛙实拍参考](references/bullfrog.png)：用户提供，取食物辨识特征，减少肉块与配料密度。

- [牛奶味百奇包装](references/pocky-milk-package.png)：用户本轮附件，供品牌、颜色与造型参考。
- Fufu 实物参考：[图 1](references/fufu-01.png)、[图 2](references/fufu-02.png)、[图 3](references/fufu-03.png)。只参考食物形态，不用于游戏展示照片中的人物。
- 用户最新修正：少深绿菜、酱汁更像糊糊、主食偏米黄、整体不规则，不仅是边缘撕扯，也不做精致摆盘。此要求覆盖 v2 原稿对应的旧表达。
- 原方案和合辑来源分别为下载目录中的《莹仔美食收藏图鉴_游戏彩蛋方案_v2.md》和《旅遊美食貼紙图鉴.png》，复制内容未改。

## 游戏内图鉴：已收齐预览版

2026-10-29 用户批准实施。使用 Godot 原生界面复现当前 HTML，共用清单和贴纸资源；本轮不制作场景食物和发现动画。

- 右下角新增贴纸册造型的“美食图鉴 G”入口，与背包同级，避开现有提示和按钮。普通游览可按 Esc 释放鼠标后点击，或按 G 直接打开。
- 默认开发预览开关开启：初始化 16 款全收齐，入口直接可见，不写正式收集存档。关闭开关时从零收藏开始；发现任意第一种有效食物激活，重复发现不重复增加。
- 打开居中大幅手账面板，周围仍可看到小屋。保留暖纸底、彩色不规则名称贴、装饰、轻微倾斜、五排顺序与主体比例。
- 面板纵向滚动，滚轮与可拖动滚动条均可操作；关闭按钮和 Esc 返回，重入保留本次滚动位置，刷新回顶部。食物不提供外链或详情弹窗。
- 打开时显示光标并暂停角色和镜头输入，滚轮只滚图鉴。背包、阅读及其他互动面板、仪式与图鉴互斥；这些界面或仪式活动时隐藏图鉴入口。
- 关闭后恢复打开前的游览或坐姿状态；鼠标恢复沿用既有浏览器授权机制，不叠加第二层暂停。失焦遵守已有暂停与明确继续规则。

### 本轮验收

| ID | 完成条件 |
| --- | --- |
| FC-01 | 正常开局可见图鉴入口；鼠标点击与 G 均能打开，位置不遮挡既有 HUD |
| FC-02 | 16 款、名称、五排顺序及主体比例与当前清单一致；冰可乐和小甜点可辨 |
| FC-03 | 滚轮和拖动滚动条可达最后一排，文字与图片不被裁掉；图内不触发移动、镜头或场景缩放 |
| FC-04 | 关闭按钮与 Esc 正确退出；重入保留滚动位置，刷新后回顶部且恢复本轮全收集预览 |
| FC-05 | 游览／坐姿打开后各自恢复原状态；不多消费一层 Esc，不留下鼠标输入锁死 |
| FC-06 | 背包、阅读、其他互动与仪式互斥；相邻背包操作和坐起流程正常 |
| FC-07 | 内部检查：关闭预览时零收藏隐藏、任意第一种食物激活、重复发现幂等；不写正式存档 |
| FC-08 | 真实网页 1366×768 和 1920×1080 下检查自然入口、可读性、滚动、退出重入；引擎模拟不替代网页证据 |

执行者完成实现与自验，独立 model-reviewer 复核改动与证据，主控基于画面和操作结果交付。实现成功、网页验收与正式收集玩法完成分别记录。

## 接入审阅与待定项

方向与生日体验兼容：以具体口味表达个人记忆，图鉴提供发现后的回看。原 C02 的独立故事已按用户决定取消。

后续正式收集玩法仍需确定：首批可发现食物与位置、发现的具体动作、未发现条目的显示方式及跨刷新收藏保存。图鉴打开方式、本次滚动记忆与全收集预览已按上节确定。

落点须遵守当前空间分级：主要空间可互动，厨房仅展示。餐厅冰箱和桌面已有蛋糕入口，新增食物不得造成误触或挡住仪式操作。记忆文字须有真实出处；现实惊喜确认后再写入可兑现的承诺。

正式食物发现流程的阶段归属尚未确定；图鉴已收齐预览已接入原生游戏。默认 10 项引擎检查、最终定向复测及独立代码复核通过，双尺寸 HTTP 网页已检查图标／G、滚动、关闭重入、背包互斥和刷新顶部；真实捕获恢复与自然坐姿链受 WrongDocumentError 阻断，保留证据缺口。详见当前状态与 work/food-collection/delivery.md。

一屏原型最新微调：街边小吃缩小10%；牛蛙主体放大15%，改用 [自然堆叠版本](../../../godot/content/food-collection/images/bullfrog-piled-v4.png)，蛙肉与腿段交叠，只露出少量腿部轮廓，不再将完整腿形摊开排列。其余位置与图片保持不变，游戏及共享清单未同步。
