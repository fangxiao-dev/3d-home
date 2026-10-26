# 成品场景 V2 独立审查记录

日期：2026-10-18；最近追加：2026-10-19。审查者：独立 model-reviewer（Astra / medium）。

**当前审查结论：PASSED（最终8f68包的实现正确性、规定功能与已观测视觉范围；性能目标未达）。** 五项原有P2与厨房烟机P2均已关闭；双分辨率功能、1920连续探索10分30秒、1366完整流程5分22秒通过。主控前台五座坐起、六区实走及动作过程观察已补齐，此前后台限速不再构成交付阻塞。reviewer独立检查的是源/日志/截图/动作抽帧，主控提供前台操作观察，未声称逐帧审看全部视频或遮挡部位。60 FPS目标未达且存在882 ms处理尖峰，不能宣称绝无卡顿；最终验收与交付由主控负责。

本记录是只读审查的结果记录，按主控明确授权新建。审查期间未修改源代码、模型、基准或网页，未运行共享 Build、导入、烘焙或 GPU 实例；独立读取代码、资产二进制、哈希、既有日志及截图。执行者测试日志属于已检查的运行证据，不表述为 reviewer 亲自重跑。

## 范围与比较点

- 验收依据：`AGENTS.md`、`outputs/design/scene-v2.md`、项目/背景/设计/参考入口及客厅资料。范围为 7 个可见区域、6 区可达、厨房仅展示、完整通用角色、5 坐位；不含 V1 彩蛋、私人内容或公开发布。
- 旧基线：`main` HEAD `cbbdf2bb97767fec1c465c7431921c2ea53dce25`；实际修改前工作树见 `work/checkpoints/scene-v2-before-20261018-210127/baseline.zip` 与 manifest。HEAD 本身不代表该粗版工作树。
- 第一轮代码与接触比较点：runtime `614bb99db74ec704ef8b57879f8b89b4892884cc781cb31091557a0f894d3554`；character `b48319f3e1c9b393c6f1019b80ef1c257c06a5b8a50a3b4009d6cebc943b697e`；model `828d1427f3d0a3a1cb4b55e0e0d1c7c8906f9d35831eae17a5101ae0cfa55871`；seats `287d155da60b31f25c59673e90b9f826a165fd6257af74c95ac4adc43496fbc9`；pack `8825c269eef33f8090abb4c94773430990a0da024bfd9d7d4ad1bd606c64fd4b`。
- 地面修复比较点：model `3001f6bbeb52dce3d42820ace2f058b43018ccf9721353ba8a414d6f84ed0dbd`；Blend `fe7a91d137b30dc6fd5b6de077ae6237c4142899e5b5500087318ac73915a8be`；runtime、character、seats 不变；网页包 `scene-1df4613e2169.pck`，完整 SHA256 `1df4613e2169bcd19a21fd9419ae42b09bb4c6ad2622724585d6a05bbfe48d95`。
- 本轮未重新审查角色原始蒙皮、17 骨骼及五动画全资产；上一轮角色结论由主控提供，不计为本 reviewer 本轮独立验证。

## 已命名问题闭合

| 问题 | 结论 | 已检查依据与边界 |
| --- | --- | --- |
| P2 软墩坐姿 root 过深、沙发接触 | PASSED：关闭指定问题 | 软墩 root.x 从旧值 −1.465 调到 −1.335，沙发额外向前 15 mm。读取 `work/seat-contact-check.py` 和 `result.json`，核对输入 Blend/seat 哈希。五座各 98/98 臀部支撑采样，小腿/鞋选定顶点在关联家具内为零，前移 0.38 m 后站立检查无侵入。旧包软墩/沙发网页静态图与结果吻合。新地面 Blend 的同项报告也已核对。此检查是 SitIdle 帧 0 与起身终点，不涵盖全程动作。 |
| P2 APPROACH 到点与 timeout 同帧清空 seat_id | PASSED：关闭 | `outputs/godot/playroom.gd` 调用 `_align_and_sit()` 后立即 return，不再继续超时取消。`Verify-Playroom.gd` 到点首轮将 `transition_clock=4.0`，下一物理帧覆盖原竞争边界。已检查执行日志的五座各三轮零失败。 |
| P2 `_walk_stage` 失败仅 assert、状态恢复不完整 | PASSED：关闭 | 函数返回 bool；对齐失败回走并恢复探索，退出失败回走再坐稳。测试 SHA256 `512fc096db65a91954739777d96995ced4de0857f14d635f79539c1bdf9cd09d` 在软墩坐稳后加入真实 StaticBody 出口阻挡，明确等待 EXITING 再等待 SEATED，检查根定位、SitIdle、auto_moving=false、cycles=0；移障后 Esc 成功退出，cycles=1，物理和记录碰撞例外均清零，松键后解锁。`work/v2-exit-retry-headless.log` 有 EXIT_RETRY_READY、EXIT_RETRY_OK 和五座各三轮 failures=[]。运行代码哈希未变。 |
| P2 自动移动 1.3 与 Walk 参考 1.65 不一致 | PASSED：关闭 | 手动移动、APPROACH、自动移动三条路径均读取 `walk_reference_speed`，不再固定用 1.3。此结论是速度合同一致，不代表视频中的步态观感已经验收。 |
| P2 网页地砖逐砖重复暗边/亮心 | PASSED：指定缺陷关闭 | 初次在 `work/v2-chrome-1366-entry.png`、餐厅/书房截图确认重复条带。检查四组隔离对照 `work/floor-repro-top-comparison.png` 及诊断报告：原方案、关闭基础 GI/阴影、基础下移均保留条带，连续顶面及连续 UV2 消除条带。源代码改为每房间连续饰面；独立解析最终 GLB 验证七个饰面均四顶点、UV2 完整矩形、y=+0.001 且无碰撞；七个基础世界顶面 y=0 且有碰撞。最终 1df 包四张 Chrome 图未再出现原条带。 |

## 源资产与构建检查

- `work/floor-fix-hashes.json` 所列 9 项源文件/Blend/GLB/座位数据/贴图均现场核对一致。GLB 包含 floor-finish 图像及七区 floor_role 语义，地面修复未改变坐位数据。
- 显式 `floor_role` 代替广泛的名称后缀判定，避免误移动 `wash basin hollow floor`。已检查当前盆底几何报告与洗漱离线图；最终网页洗漱图仍可见盆底，远景不足以验收排水口细节。
- 已检查 `Build.ps1`：房屋和角色有分开的重建入口；模型或环境光照配置哈希与 bake manifest 不符时拒绝导出旧烘焙。未发现该检查范围内新增可行动 P1/P2。
- 离线预览、引擎日志、网页截图分别作为不同证据，不互相替代。

## 1df 包网页截图复核

证据：`work/scene-v2-refresh.json`，起止时间 2026-10-18 14:49:21Z–14:50:52Z，记录实际加载 `scene-1df4613e2169.pck`、errors=[]。已独立核对本地包完整哈希。截图均为 1920×1080：

- `work/v2-refresh-entry.png`：客厅与阳台地面连续，砖缝保留，原重复暗带消失，人物站立脚底无明显悬空。
- `work/v2-refresh-dining-seat.png`：臀部落在坐垫，鞋底贴地，手腿与桌椅无可见穿插。
- `work/v2-refresh-dining.png`：地面条带消失，人物与冰箱同框比例合理。
- `work/v2-refresh-wash.png`：盆底可见，人物与洗漱柜比例合理，地面没有原条带。

**本批截图范围 PASSED，未发现新的明确 P1/P2；不等于整体成品品质 PASSED。** 对照 `outputs/design/references/scene-v2-quality-reference.jpg`，网页仍更偏黄、反差更强，人物投影较硬，白色柜台亮部层次较弱。主控已决定最后校正灯光，这部分整体美术结论待新包截图。参考图不作为照搬家具布局的要求。

## 尚待验证与性能边界

1. 最后灯光版本的 receipt、实际加载包、七区截图与客厅/餐厅/书房近景；整体视觉需主控验收。
2. 最终包五座位连续 SitDown/StandUp 动作，含接触、穿模、输入隔离和不同接近方向。当前静态/BVH/状态测试不替代全程视觉。
3. 最终包 Chrome 1920×1080 与 1366×768 的完整操作及连续探索 10 分钟证据。Edge 已由用户取消。早期 1366 报告缺加载包及起止时间，不能据此完成最终版本关联。
4. 1080p 60 FPS 目标尚未证明达到。1df refresh 使用 Intel UHD，洗漱截图状态记录最近 600 帧 mean=70.6035 ms、p95=60.6 ms；其他快照包含明显启动/停顿影响，因此不将这次短程、可能受同时运行影响的记录当作干净性能基准，但它显然不能支持 60 FPS 达标结论。需要独占、明确 GPU 与版本的稳态/长测帧耗时证据；功能 pass 不能掩盖性能未达标。
5. 目标电脑实测仍独立于开发机测试；没有公开发布或上线验收。

后续追加最终证据时保留各版本边界；仅在相关证据充分后更新对应结论，不追认本记录未审查的运行或画面。

## 追加：98276ac01c26 灯光版与构建失败传播

本节追加于 2026-10-18；此前 1df 包结论保留为历史。`work/v2-refresh-*.png` 和 `work/scene-v2-refresh.json` 已由执行者刷新为新版本；1df 四张图片固定副本位于 `outputs/previews/scene-v2-final/before-lighting/`，旧报告位于 `outputs/verification/scene-v2/before-lighting/`。引用证据必须同时核对包版本。本审查记录随归档被移入 before-lighting 后，已按主控授权移回根路径，保持唯一权威文件。

新包：`scene-98276ac01c26.pck`，SHA256 `98276ac01c26af1602d6da2097a17e9d8c019f9a6684cb8ae65543cd5d8ecf13`。已现场核对包哈希；receipt 中 model、character、seats、runtime 与 1df 比较点一致。新 refresh 时间为 14:57:34Z–14:59:05Z，实际加载包为 98276ac01c26，errors=[]。当前环境脚本 SHA256 `1f0cfa9da1f28d0c6c495ed4c4152144dd6d22527e688981ed95de0ec1f4cb21` 与 bake manifest 匹配。

检查 `scene_environment.gd` 与 `Prepare-Bake.gd` 相对于前次读取内容的变化：

- 环境色 `fff1dc` → `fffaf2`，环境能量 0.22 → 0.26。
- 主光色 `ffebcd` → `fff8ee`，主光能量 0.38 → 0.22；新增 shadow_opacity=0.65，投影方向和 shadow_blur=2 保持。
- 房间烘焙补光色 `ffedd8` → `fff8ee`，能量 0.16 → 0.12。
- Lightmap 自定义环境色 `fff1dc` → `fffaf2`，能量 0.25 → 0.27；其余已读烘焙质量、反弹和 probe 配置保持。

**同机位截图增量结论：PASSED。** 已查看新入口、餐椅、餐厅、洗漱四图，并与前轮已查看的 1df 同机位图比较：整体黄染降低，地面更接近中性暖灰；人物投影和家具落地阴影仍可辨认，但黑度下降；入口软墩的布纹和坐垫亮部较前版更容易分辨。餐椅近景保留臀部、鞋底接触，洗手盆底仍可见，地板重复暗带没有复发。本批未发现新增明确 P1/P2。

改善主要是色偏和明暗反差，并非投影边缘几何变柔；人物轮廓影仍清楚。白色台面部分区域仍很亮，本批不能据此声称已经完全达到参考图的整体柔和度。书房近景、其余座位与全程动画不在本批截图范围。

**构建失败传播修复：PASSED（限定脚本异常退出码路径）。** 已检查 `outputs/Build.ps1` 的房屋和角色两处 Blender 调用，均在 `--python` 前加入 `--python-exit-code 1`，其后的 `$LASTEXITCODE` 非零检查会 throw。`work/blender-exit-probe.log` 记录故意抛出 RuntimeError 的脚本、Blender 报 script failed 及 `EXIT_CODE=1`。此证据足以确认该选项将 Python 脚本异常传播为失败，阻止异常后继续导出旧资产；未重复运行探针或完整构建。

整体仍为 EVIDENCE_GAP：等待此包最终长测、连续动作视频、双分辨率操作及独占性能证据；本节不更新 60 FPS 达标状态。

## 追加：982 包 Chrome 1366×768 完整短程检查

独立核对 `work/v2-chrome-1366-verification.json`：文件于本地 23:05:21 新写出，记录 2026-10-18 15:00:16Z–15:05:21Z，实际 loaded_packs 含 `scene-98276ac01c26.pck`；本节没有使用旧 1366 报告。GPU 为 Intel UHD / ANGLE D3D11。记录 pass=true、errors=[]，soak 未运行。

已检查 15 条座位记录，五座各三次，cycles 依次增加为 1/2/3，各次退出 transition_collisions 为空。六区实际记录包含 living、balcony、hallway、dining、wash、study。结合已读浏览器测试脚本，报告覆盖 WASD/方向键、坐姿输入隔离、阳台/厨房/洗漱后门/走道边界、Q 四向、E 长按只转一次及缩放上下限。上述是脚本操作和状态证据，不当作 reviewer 现场操控。

已通过 view_image 独立目视全部 16 张 `work/v2-chrome-1366-*.png`：entry、balcony、hallway、dining、wash、kitchen、study 七区图；entry_stool、sofa_middle、window_seat、dining_chair、study_chair 五坐位图；study-angle-0 至 3 四向图。

**限定结论：PASSED（本版 1366 短程功能记录与静态截图范围）。** 地板重复暗带未复发，家具、布木材质和地面接触明暗可辨；五坐位可见部分未发现明确穿插或人物比例回退。书房四向图均保留可辨人物，未见墙体完全遮住角色；关闭房门后的内部未被展示。没有发现新增明确 P1/P2。

边界：沙发中位的鞋部被茶几、书房坐姿的腿脚被桌面自然遮挡，因此这些静态机位不能单独证实被挡处接触；仍以已有几何接触检查配合待审连续视频判断。高亮白色桌面及较硬的角色轮廓影仍是前述整体美术差异，不因功能 pass 消失。四向截图仅实际覆盖书房，不能写成七区各四向目视通过。

**性能未达到 60 FPS。** 尾段 30 个 600 帧滚动均值为 27.2188–28.7042 ms（约 35–37 FPS），均值采样的平均值 27.8967 ms；第一份尾段状态 p95=33.5 ms。这些重叠滚动窗口不是整段原始帧分布，但已足以否定本次运行达成 16.667 ms/60 FPS。整体仍为 EVIDENCE_GAP，等待 1920 长测和连续动作视频；功能验收通过与性能目标未达分别保留。

## 追加发现：厨房抽油烟机在切墙视角下悬浮（P2，OPEN）

主控指出 `work/v2-chrome-1366-kitchen.png` 约 (470,575) 的白色横板后，reviewer 独立回查源代码与当前 GLB extras，确认是抽油烟机，不是门楣。此前“本批未发现新增明确 P1/P2”是初看记录，现由本项具体证据更新；不能再将该厨房静态画面列为无发现通过。

- 位置：`outputs/blender/rooms/kitchen.py:223–226`，`kitchen range hood` 与 `kitchen range hood underside`。
- 资产证据：主件为 1.18×0.42×0.16 m，Godot 中心约 (-0.92,1.83,8.84)，与灶台同 x/z；当前 GLB 主件 extras 为 cutaway=""、collision=true、bake_static=true，底板同样 cutaway=""。模型未提供烟道或连接背板；主件后沿 z≈9.05，与南墙 z=9.2 还有约 0.15 m 间隔。
- 呈现原因：`playroom.gd` 的 `_update_visibility` 对空 cutaway 直接跳过；南墙/窗随近侧机位隐藏后，油烟机仍可见。截图因此把它呈现为灶台上方没有连接关系的白色悬浮横板，影响成品结构可信度。
- 最小修复建议：将主件和底板统一纳入南侧 cutaway，并同步退出静态烘焙以免隐藏后遗留阴影；或由 builder 制作可信连接结构再一致管理遮挡。具体实现由主控/执行者决定。
- 验证要求：新包同机位厨房截图确认不再有孤立横板或残留悬空阴影，同时保留灶台/水槽识别性；从相反机位检查该物件与所属墙体的显示一致性。不要求 reviewer 重跑共享 GPU。

## 追加：烟机修复静态复核

**PASSED（源资产与合同范围）；烟机 P2 尚待新网页两机位闭合。** 当前冻结 GLB `dbc32350082c450d69feeb9cc21443c527b427fd1e3b0a2a94c7961250599ca9`、Blend `ad4defa2fe23bb13d80b9194e62ee0d432ec6dfc4cfa561edf2e5d9de385d1d7`、data `69ad391c4d484b6255cc0d86f81027459ca909c629e73dc9d903476fada1c73b`。`work/hood-fix-hashes.json` 六项哈希现场核对匹配。

已读厨房源代码：实际为主件、底板、后壳、烟道四个生成部件，均有 kitchen_range_hood ID、wall_mounted=true、south cutaway。后壳连接主件与墙面，烟道上延至 2.45 m；wall_mounted 避免被建筑层高归一化再次缩放。合批后导出为两个 mesh（白色主体含后壳/烟道，黑色底板），因此不是必须存在四个导出节点。

独立读取 GLB 确认两个节点均 cutaway=south、bake_static=false，主件保留碰撞。已检查 `hood-fix-check.py` 与对应 JSON：检查当前 Blend 实际顶点边界，并在高度 2.2 m 对南墙实际三角网格发射射线，命中实体墙而非玻璃。源代码、检查结果与导出语义相符；本 reviewer 未重跑 Blender。

另将 `work/hood-fix-data-before.json` 与新 data 独立比较：五座位 JSON 完全相同，原有 34 项家具合同完全相同，仅新增 kitchen_range_hood 为第 35 项。data 哈希改变不代表坐位移动。尚未读取新网页证据，静态结论不替代切墙后的视觉与残影检查。

## 追加：2389 包烟机网页闭合

**PASSED：烟机悬浮 P2 关闭于 2389 包。** 已独立查看 `work/v2-refresh-kitchen-front.png` 和 `work/v2-refresh-kitchen-reverse.png`。正向切墙图中孤立白横板消失，其原位置没有对应悬空残影，灶台和水槽仍可辨；反向图可见烟机主体及向上延伸的烟道，不再是独立无连接薄板。反向机位有入口过梁遮挡且烟道上端接近画面顶部，其完整连接关系由前节源几何/实体墙射线检查补充，本截图不是无死角结构展示。

本次实际加载包由 `work/scene-v2-refresh.json` 记录为 `scene-2389c410014a.pck`，时间 15:21:28Z–15:23:12Z、errors=[]；已现场核对该包 SHA256 `2389c410014affa579a573c2b74a391c122af58464420e0b65fa51ae132bdaca`。其模型 dbc32350…0599ca9、座位合同69ad391c…da1c73b 对应前节静态审查。

读取时最新 build receipt 已进一步变为 `scene-8f68e808fcb8.pck`、runtime `2e1835def12354d6cf12f8990858f6a36e1578bff0d555e4ac81bd4a035a6382`；因此本次仅归属 2389 证据，不把两张旧版图写成新 runtime 的验证。快速连按转向、最终双分辨率长测与动作视频仍待审，总体不 closed。

## 追加：8f68 最终候选静态一致性与快速转向覆盖

已现场核对 receipt 所列 runtime、model、character、seats 和 pack 五项完整哈希，全部一致。候选包 SHA256 `8f68e808fcb83304db3189fb3533b9f53a5437e29f78077f451d11390478ed2c`。

**PASSED（只读观测字段增量）。** 当前 runtime `2e1835de…a6382` 在 snapshot 内新增屏幕投影计算及 player_screen/viewport/camera_facing_dot 输出。独立在内存中删除这两行再计算 SHA256，精确恢复旧 runtime `614bb99d…d3554`，证明本次没有顺带修改镜头或移动行为。未写回文件。

已检查 campaign 脚本：三轮分别快速 QQ 与 EE，共六组，每组等待 3 秒后断言 camera_facing_dot>0.999，人物躯干投影点位于视口内。该检查能够发现转向结束后仍失焦或人物仍出屏；不逐帧采样转向过程，不能独立排除短暂出屏、人物全身边缘裁切或遮挡。后续视频可补充过程观察。

快速双 Q 的偶发异常按主控提供的复测信息记录为“未复现”；本轮没有行为修复，因此不能写成“已修复”。最终 campaign 的实际结果尚待读取；不轮询或复用旧报告，不以新增断言本身作为运行通过证据。

## 追加：8f68 包 1920×1080 完整功能与长测

**PASSED（本次 1920 功能、持续运行和所提供静态画面范围）；60 FPS 未达标。** 已独立读取 `work/v2-chrome-1920-verification.json`，并确认与 `outputs/verification/scene-v2/v2-chrome-1920-verification.json` 副本哈希相同。记录时间 15:28:17Z–15:44:20Z，viewport=1920×1080，实际加载 `scene-8f68e808fcb8.pck`，关联源哈希与冻结 receipt 一致，pass=true、errors=[]。

- 五坐位各三次，共 15 次；逐条退出 transition_collisions 为空，最终五个 cycles 均为 3。六个可进入区域均有状态记录。
- 脚本完成 WASD/方向键、四处边界、坐姿输入隔离、Q 四向、E 长按一次和缩放 0.85/1.15 检查；不是七区各四向的完整目视测试。
- 六组快速双键在等待 3 秒后的 camera_facing_dot 均约 1，人物投影点均在引擎逻辑 viewport 1280×720 内。浏览器输出1920×1080与引擎逻辑坐标属于不同空间，此断言使用的是相配的引擎坐标，不构成分辨率错误。仍不证明转动中每一帧都在屏内。
- 持续探索阶段 elapsed_ms=630021（10 分 30 秒），15 圈实际跨区路线，超过 10 分钟。未记录脚本错误、路线失败或状态失控。
- 已通过 view_image 独立查看本次全部 17 张 1920 图：七区、五坐位、书房四向与 soak-finish。原地砖暗带和厨房孤立烟机未复发，人物可辨、静态接触没有新增明确穿插；厨房同机位灶台/水槽保留。此前说明的部分腿脚被家具遮挡、白桌面较亮等边界继续保留。未发现新增明确 P1/P2。

性能：Intel UHD / ANGLE D3D11，90 个滚动均值窗口范围 16.7703–34.04 ms，窗口均值的平均值27.2843 ms；performance_target_met=false。长测同区域最早3与最后3窗口均值分别为：阳台28.66→28.04 ms、餐厅28.21→28.79 ms、书房28.27→29.51 ms、洗漱28.07→28.65 ms。采样未显示显著累积恶化，但这是重叠窗口和有限路线的比较，不是原始逐帧分布或长期稳定性保证。**本开发机此次 1080p 60 FPS 目标明确未达；不能以功能 pass 覆盖。**

待补：最终同包1366报告、连续动作视频及主控整体美术验收。因此总体仍为 EVIDENCE_GAP，本节不宣称完整交付 closed。

## 追加：8f68 包最终 1366 报告与性能边界

**PASSED（双分辨率规定功能与已审静态范围）；最终连续动作和整体交付仍待。** 已读取归档 `outputs/verification/scene-v2/v2-chrome-1366-verification.json` 与 `summary.json`，确认时间15:44:26Z–15:49:48Z，实际加载8f68包，源哈希一致，pass=true、errors=[]。五座各三次、六区、四类边界、键盘/缩放/输入隔离检查齐全；六组快速双键采样朝向dot=1且投影在逻辑视口内。此为同最终包的新报告，不继承982报告。

抽查最终1366入口、书房坐姿、厨房图：帮助栏及坐姿提示没有文字裁切；角色、家具、地面和烟机切墙状态与最终1920画面一致。结合本轮已逐张审查的最终1920全套图及前次1366完整图，未发现新的分辨率相关明确P1/P2。本次未重复声称逐张检查所有最终1366图。

1366尾段30个滚动均值为26.205–27.1257 ms，平均26.7224 ms，60 FPS仍未达。1920原报告保留一个书房采样process_ms=882 ms，同时该状态frame_mean_ms=24.5842、p95=30.4；这是单点处理尖峰，不能被滚动均值或功能pass抹去。不能宣称“绝无卡顿”。summary明确desktop_load_isolated=false，测试浏览器串行，但用户标签页/系统负载未隔离；不能据此把全部性能归因于场景，也不能据此宣布目标达标。

持续运行覆盖准确表述：1920有630021 ms/15圈探索长测；1366本轮约5分22秒，soak=null，未做独立10分钟长测。双分辨率功能记录齐全不等于两种分辨率各自均有10分钟记录。如最终验收要求每分辨率分别10分钟，1366长测仍是证据缺口。连续动作视频与主控实际浏览器/整体美术验收尚待追加。

## 追加：最终视频、动作中途帧与验收口径

主控已明确原验收口径为“两种分辨率均检查，同一版本连续探索至少10分钟”，不要求每种分辨率分别10分钟。依此口径，1920长测与1366全流程合并满足规定运行覆盖；不再将1366独立soak列为缺口。对外仍准确区分各自时长。

已读 `video-README.md`、`video-timeline.json`、`video-keyframes.json` 并独立核对 `video-hashes.json` 所列原WebM、MP4和时间线三个哈希。时间线记录实际加载8f68、errors=[]、五座final_cycles各1。原视频保留；README说明MP4仅移除42.012秒加载头、时长94.04秒且不加速，该剪辑说明未作为reviewer亲自逐帧验证结论。

已独立目视全部10张动作中途帧，每座各SitDown/StandUp一张。**PASSED（中途抽帧可见范围）**：软墩、窗边、餐椅的腿脚与家具没有可见穿插，臀部到起身前移的姿态合理；沙发中位上身/膝部、书房上身/臀部可见部分无明确穿插。沙发中位鞋部及书房腿脚受桌面遮挡，不能由这些帧确认遮挡处全程接触。

本 reviewer 的直接视觉输入限于静态图，未连续观看原视频，故不将10个动作中途帧写成全部过渡逐帧验收。时间线证实五座各有完整动作过程记录，不能独自证明过程观感；主控可直接播放现有原视频或实操观察坐下早段、站起早段及镜头转场，无需重新录制。收到主控观察结果后单独注明证据来源。

另外独立重算 `source-manifest.json` 中104个文件的SHA256，changed=0，视频关联版本与冻结源清单保持一致。功能/静态/中途抽帧已完成，连续动作全程目视与主控整体验收未由本 reviewer 追认；性能限制保持。

## 追加：主控真实 Chrome 实操的限定确认

2026-10-19 已读取 `owner-check.json`，configured_pack=scene-8f68e808fcb8.pck、status=limited_background_rate、logs=[]。主控报告通过真实按键绕茶几移动，并完成入口软墩、窗边坐位各一次坐起；记录末态两项cycles均为1。reviewer另行查看 `owner-stool.png`、`owner-window.png`，可见人物与对应坐面关系合理，未出现原软墩过深问题。

该连接页面即使报告visibility=visible，墙钟帧耗时仍约854 ms、p95约1020 ms，无法据此判断常速连续动画。主控已请求用户激活小屋前台或选择保持后台先交付；该请求及待回复状态由主控管理。本记录不把低速实操表述为常速动作验收通过，也不将此次后台限速等同于此前串行测试约27 ms的稳态性能结果。

总体仍为EVIDENCE_GAP：实现、双分辨率功能、所审静态、动作抽帧与有限主控实操已有证据；最后的常速连续动作/主控最终确认尚未通过。60 FPS目标未达及882 ms单点处理尖峰继续作为独立性能限制保留。

## 追加：前台实操缺口关闭及最终范围结论

2026-10-19已独立读取 `owner-foreground-check.json`：status=foreground_interaction_pass、configured_pack=scene-8f68e808fcb8.pck、logs=[]。记录包含五座坐稳/起身阶段及退出，末态五个cycles均为1；六个可进入区域均有状态，厨房快速QQ/EE返回和缩放0.85/1.15有记录。主控说明使用真实Cua按键完成WASD/方向键操作并观察进入、坐稳、起身过程，无新增可见穿插。

激活前的几个状态仍保留约271–309 ms滚动均值，不能删除或混为前台稳态；激活后从软墩STAND_UP开始的观察记录恢复约24–29 ms，先前约一秒一帧的状态不再持续。此次是正常前台运行条件下的交互确认，**并非60 FPS达标证据**。

reviewer另行目视 `foreground-sofa.png`、`foreground-dining.png`、`foreground-study.png`：人物坐姿与已审静态结果一致，未见新穿插或资产回退。书房腿脚及沙发部分鞋部仍有家具遮挡。综合此前独立代码/几何/截图/十张动作中途帧、双分辨率脚本记录，以及主控提供的前台动作观察，功能与已观测视觉范围可交付；不再把浏览器active标签能力或旧后台限速写成继续阻塞。

本次关闭的是实际前台操作和可观察动作验收缺口，不把主控观察冒充reviewer亲自操作，不追加“逐帧看完原视频”或“遮挡处每帧均无穿模”等未经验证断言。性能60 FPS未达、1920单点882 ms处理尖峰、实际桌面负载未隔离及目标电脑未实测作为交付限制保留。上方历史EVIDENCE_GAP段落用于追溯，以本节和文首当前结论为准。
