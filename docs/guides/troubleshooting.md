---
status: active
doc_type: runbook
source_of_truth: godot/playroom.gd, godot/scene_environment.gd, godot/addons/scene_baker/plugin.gd, Prepare-Bake.gd, Bake.ps1, Build.ps1, verification/fixed-scene-transition-20261025/focus-check.cjs, verification/fixed-scene-transition-20261025/refusal-check.cjs
last_verified_at: 2026-10-25
---

# 常见现象与排查入口

当前操作看 [PLAYROOM](controls.md)，成品目标看 [V2](../design/scene-v2.md)，验收版本看 [HOUSE](../status.md)。以下经验来自当前实现与实际验证。

## 页面仍然显示旧版本

核对HTML的GODOT_CONFIG.mainPack、浏览器实际请求的PCK和 [Build.ps1](../../scripts/Build.ps1) 的收据。查询参数变化不代表资源更新。刷新用户实际使用的页面，不能以另一个新浏览器正常代替。

## 墙或顶梁悬在画面中

检查导入mesh的extras.room_id/cutaway以及 [playroom.gd](../../godot/playroom.gd) 的 `_update_visibility`。墙体附件应与所属墙同步，顶梁和吊灯有明确顶面分类。所有观察方向检查；隐藏视觉不改变碰撞。

## 物件隐藏后，地面仍有 U 形或家具轮廓黑影

先区分实时阴影和已烘焙进地面的光照。运行时隐藏 Mesh 不能撤销已有烘焙；上下柜若用相同家具 ID 和静态属性合并，整组退出后会同时留下空地与残影。检查 [厨房生成](../../blender/rooms/kitchen.py)、[派生装饰](../../blender/environment_v2.py) 和 [合并/光照属性](../../blender/environment_lightmap.py) 的 furniture_id、cutaway、wall_mounted、bake_static。

检查所有可能动态隐藏的家具，不能只修截图中的一个柜子。可隐藏组自身的遮蔽不能写入始终显示的地板 lightmap；家具接收探针间接光与随显隐变化的实时影时，应分别验证落地感和成本。上柜及其门板、把手、饰条必须在源创建时继承真实所属组；后置名称推断会把一件家具拆散，派生门芯也会继承错误归属。

模型导出后重算必要的烘焙，再比较相同机位的角色可见性、阴影、承托附件与反向恢复。投影在屏内、物理射线无阻挡或构建成功，都不能单独证明修复：无玩法碰撞的门板也能遮住人物，需要可见渲染几何或实际图片复核。三角形检查按实际 surface 材质过滤透明玻璃，不能把所有网格都当不透明，也不能按物件名字放行。本轮实例与当前修正进度见 [游览控制记录](../design/navigation-v2.md)。

## 行走过门口时镜头横移或突然改变构图

同时记录人物位置、当前房间、探索观察点和实际镜头姿态。房间 ID 的离散切换如果直接参与观察点计算，会让只向前走也产生横向拉动；单纯调慢插值可能只会延长漂移。当前观察点统一跟随角色，[镜头回归](../../tests/Verify-Camera.gd)及 [网页检查](../archive/verification/fixed-scene-transition-20261025/browser-check.cjs)检查跨区连续性；旧原路线证据保留在 navigation-v2。

## 已经取消游览，鼠标却又被锁定

区分捕获请求与实际授权。浏览器尚未完成请求时，释放当前光标并不保证旧请求被撤销；较晚到达的成功通知必须再次检查玩家意图和焦点。已取消或失焦时调用实际释放，不能只改缓存字段，也不能因重新获得焦点就恢复游览。[镜头回归](../../tests/Verify-Camera.gd)覆盖请求、取消、晚到授权的边界；该模拟不等于浏览器权限验证。

## 一次 Esc 起身后，又进入了暂停

先区分一次按键的重复事件与松开后的新按键。坐姿 Esc 发起起身后，mode 会回到 EXPLORE；若同一按下过程被再次路由，就可能触发外层暂停。当前运行代码按下至松开只消费一次，失焦时清理可能缺失 key-up 的闩锁；[转场回归](../archive/verification/fixed-scene-transition-20261025/Verify-Transition.gd)覆盖重复 echo/非 echo 事件，[中断回归](../archive/verification/fixed-scene-transition-20261025/Verify-Interruption.gd)明确模拟失焦丢 key-up。若浏览器实际拒绝捕获或发生失焦，显示继续按钮仍属于对应恢复流程，需核对真实 DOM 及捕获意图。

## 自动化重新捕获后，第一笔鼠标移动没有转动

先读取该次真实 DOM `mousemove.movementX`，再比较游戏转角。锁定模式下，自动化工具的绝对坐标差不一定等于浏览器送出的相对位移。本轮 [主控检查](../archive/verification/mouse-look-20261025/owner-check-v3/report.json)保留第一笔 trusted `movementX=0`，下一笔 `movementX=100` 对应 12°；运行包没有改变。首笔归零的 Chromium 内部原因尚未确认，最小 HTML fixture 也未复现该归零，不能把它写成产品已修复或浏览器根因已证实。

## 切换标签后，测试快照仍显示有焦点

隐藏页可能暂停游戏帧与 JavaScriptBridge 的观测状态更新，旧 snapshot 不能证明失焦事件没有处理。用浏览器真实 `document.hidden` / `document.hasFocus()` 判断切换前提并等待状态变化；返回后再等新 snapshot，核验镜头未漂移、游览输入已暂停且鼠标已释放。不要等待隐藏游戏页主动刷新快照，也不要在切换请求后立即断言焦点已完成变化。

若等待真实 DOM 可见性仍超时，检查 `waitForFunction` 是否依赖默认 rAF 轮询：隐藏页暂停 rAF 时，条件已经成立也可能不再被执行。当前[焦点检查](../archive/verification/fixed-scene-transition-20261025/focus-check.cjs)用 `polling: 100` 定时读取真实 DOM，保留实际失焦、返回条件和超时；返回后再等待新的游戏快照，检查停止与手动继续。该等待机制问题本身不能证明游戏没有处理失焦。

如果多个测试标签同时报告可见且有焦点，先检查自动化工具的焦点模拟。本机 Playwright 的 Chromium 初始化默认启用 `Emulation.setFocusEmulationEnabled`；焦点回归应只对测试页关闭该模拟，再检查真实事件。不能通过在页面内伪造 blur/focus 或放宽断言替代浏览器失焦验证。

锁定权限的验证还要避免脚本读取制造用户激活：采用 CDP `userGesture: false` 读取真实状态，不能用执行脚本请求捕获代替玩家点击。Sandbox 拒绝与正常新文档恢复属于不同上下文，[拒绝检查](../archive/verification/fixed-scene-transition-20261025/refusal-check.cjs)保留实际拒绝及该恢复边界。

## 中文或按键提示缺字

新文案与字体子集必须同步，中文、ASCII和数字都应检查。当前字体位于 `godot/assets/NotoSansSC-Play.ttf`，生成后重新导入和导出，再实际查看提示。不能从旧文案正常推断新字齐全。

## 烘焙自动化报重入或弹出保存对话框

原生烘焙进度会泵编辑器事件循环。从SceneTree timer或正在flush的deferred队列调用可能发生重入。当前 [scene_baker](../../godot/addons/scene_baker/plugin.gd) 用一次性Timer节点触发原生烘焙动作。

[Prepare-Bake.gd](../../scripts/Prepare-Bake.gd) 先保存LightmapGIData并take_over_path，再打包场景；否则数据可能被内嵌并触发原生保存对话框。导入模型扁平化前清scene_file_path，再设置owner，避免实例与节点重复。

烘焙需实际生成数据并验证users；记录原始stderr和阶段标记。当前已观察到编辑器退出阶段的get_node诊断，仅出现在saved_and_verified_before_editor_shutdown之后；若发生在保存验证之前，应按真实失败处理，不能一概忽略。

## Web光照、阴影或探针与编辑器不一致

离线用支持烘焙的渲染器，运行保持Compatibility。shadowmask生成使用动态烘焙模式的方向光，运行采用overlay。桌面BC4/RGTC格式可在WebGL产生逐层转换警告；当前shadowmask用无损导入。此安装版本Compatibility明确拒绝FXAA，当前采用2xMSAA。

headless Dummy渲染器曾对已有探针资源返回空数组；同一资源在真实Compatibility中可读取有效points/SH/tetrahedra。用实际渲染器或网页snapshot的probe_points确认，不因Dummy空结果盲目添加探针。

## 帧率低或不同测试结果不一致

记录WebGL实际renderer。此混合显卡电脑的默认Chrome选择Intel UHD，即使WebGL请求high-performance；独立测试进程的force-high-performance-gpu可选择RTX，但不能将该结果当用户默认浏览器表现，也不应改用户系统配置来隐藏问题。

优化试验先冻结完整可回退版本，保留实际机位、按键路线和采样窗口。对照普通页与测试页时，rAF 先与实际游戏帧校准；函数微基准不能替代整帧耗时。单次顺序 A/B 可能受负载和时序波动影响；本轮静态数据缓存试验经一次 A-B-A 后，恢复版也变快，因此回退，未确认缓存收益。原长测失败不因短窗变快而改写。

先关闭其他测试游戏页，再预热、记录墙钟帧间隔、p95、draw calls、三角面和页面可见性。CUA尺寸覆盖可能受DPI影响，需同时核对canvas buffer、CSS、innerWidth/Height、DPR，截图外围黑区不一定来自游戏布局。

本轮实际减少了重复实时补光阴影、静态投影、级联次数和同类绘制批次；每次优化都要在同一画面复测，保留材质和造型品质。

## 地砖出现逐块重复的暗边或棋盘明暗

先看烘焙 EXR 是否已包含暗带。本次问题来自每块倒角砖独立的小 UV2 图块，边缘、侧面和底面在低分辨率烘焙与过滤时相互污染。移除地基投影、下移地基或调整法线都未消除；对照实验中，连续顶面与单一矩形 UV2 消除了暗带。

当前每个房间使用连续地面，UV0 表现砖纹与细缝，UV2 服务烘焙。地面通过 `floor_role` 标记识别，不能用名称末尾 `floor` 批量下移：洗手盆内底也可能包含这个词。修改后核对实际 GLB 高度，再烘焙，并在网页同时检查大面积地板和洗手盆。
