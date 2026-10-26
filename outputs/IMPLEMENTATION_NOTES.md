---
status: active
doc_type: implementation-pattern
source_of_truth: blender/scene-v2-spec.json, blender/environment_v2.py, blender/build_character.py, godot/playroom.gd, Build.ps1, Verify-Camera.gd, verification/fixed-scene-transition-20261025/Verify-Transition.gd, verification/fixed-scene-transition-20261025/browser-check.cjs, verification/fixed-scene-transition-20261025/focus-check.cjs, verification/fixed-scene-transition-20261025/refusal-check.cjs
last_verified_at: 2026-10-25
---

# 继续制作的实现入口

当前目标与资产合同见 [成品场景 V2](design/scene-v2.md)，实际验收与资源版本见 [HOUSE.md](HOUSE.md)。本页记录已落地的实现方式；原型机位和坐姿证据保留在 [PLAYROOM 历史](PLAYROOM.md)。

## 源资产与生成边界

环境源由 `blender/build_living_room.py`、房间模块与 `environment_v2.py` 管理，人物由独立 `build_character.py` 管理。分别生成房屋与人物的 Blender/GLB，环境生成器不覆盖人物。新建手工资产应有自己的源文件并由环境构建引用，避免落入生成器清空重建的场景。

公共尺度以 `scene-v2-spec.json` 为设计基准；部分造型尺寸仍由各自生成器确定，修改基准后必须同步源几何、角色合同与接触验证，不能假设所有网格会自动按参数调整。家具尺寸、坐位和元数据在源侧产生；运行时读取 `scene-v2-data.json`，不另写一套坐标。坐位用 Godot 坐标，Blender `(x,y,z)` 转为 `(x,z,-y)`。角色 Blender 朝 -Y、Godot 朝 +Z，整体缩放为1。

网格 extras 提供 room_id、furniture_id、collision、cutaway、camera_occluder、bake_static；视觉、物理和烘焙归属分别表达。建筑地面、盆底和桌面按生成语义区分，避免把名字中的共同词当成同一资产类别。

合并几何前先保留可见性边界。相同材质不代表上柜、下柜和附件可以共用一个家具 ID；否则运行层只能整组隐藏，且静态烘焙仍留下阴影。可隐藏单元及其派生门板/把手/饰条应继承一致 ID、cutaway 与烘焙属性，沿既有合并键形成独立单元。相关症状见 [残影排查](TROUBLESHOOTING.md#物件隐藏后地面仍有-u-形或家具轮廓黑影)。

家具所属组应在房间源创建时明确，承托物和派生装饰继承该组。阳台上柜曾因主体、门板、把手分别按名字兜底而分裂；只隐藏有碰撞主体会留下悬空门板。物理视线无阻不能证明渲染视线无阻，验证需区分两者，不为测试给装饰增加玩法碰撞。

## 坐下与起身必须一起验证

角色五个真实骨骼动画来自独立GLB，root平移归运行时控制。SitDown/StandUp的脚部局部位移由角色合同提供，运行时根位移用一致插值补偿；不能只检查动画起止的截图。

坐位定义接近点、根位置、出口和镜头。接近和离座使用实际物理移动，目标座椅的碰撞例外仅在必要阶段启用；其他家具与墙继续阻挡。失败处理应恢复可操作状态，离座受阻可回坐后重试。关键回归在 [Verify-Playroom.gd](Verify-Playroom.gd)：到点/超时同帧、接近被挡、退出被挡和移障重试、次数与碰撞例外清理。

姿态接触分两类证据：实际网格采样确认臀部得到座面支撑、小腿和鞋不穿座体；浏览器连续动作确认过渡、转向和桌沿净空。自动行走速度与 Walk 参考速度相同，避免只在自主接近时滑步。

## 光照和共享构建

[Build.ps1](Build.ps1) 的 `-RebuildAll` 从两套源资产重建、导入、烘焙、验证并导出。`-BakeLighting` 使用 [Prepare-Bake.gd](Prepare-Bake.gd) 生成编辑器烘焙场景，再由独立隐藏编辑器执行原生LightmapGI烘焙。导入、烘焙和网页导出串行执行。

Blender 调用在 `--python` 前传入 `--python-exit-code 1`，脚本异常立即停止构建，避免旧 GLB 掩盖制作失败。生成器、材质制作与正式资产均位于 `outputs/`；`work/` 只承载安装配置、工具、日志和草稿，不是美术资产的权威来源。

固定结构在烘焙阶段投影，运行时使用 lightmap 与 shadowmask。按家具组内碰撞几何推导的 `camera_occluder` 全组不进入静态 GI，改为动态接收 LightmapGI 探针；实体主体与人物使用原 WarmSun 实时投影，墙体和轻细装饰沿用各自投影语义。可见性变化因此不会把家具阴影留在固定地面上。`scene_environment.gd` 与 `playroom.gd` 的运行设置必须一致，不能在集成时再次覆盖投影开关。

用真实 Compatibility/Web 核对探针与贴图；Dummy 渲染器不提供可靠探针查询。构建检查环境模型和灯光源哈希与 bake manifest 一致，过期数据必须重烘焙。阴影归属变化后重新比较家具落地感与性能，不能沿用旧包性能结论。

## 证据与回归

GLB、角色、坐位、运行代码和实际浏览器PCK请求必须属于同一收据版本。`?test`的snapshot只供观测，游玩验证使用真实键盘/滚轮输入。正常页面不展示测试数据。

控制方式变更后，输入隔离测试必须改用仍有效的新输入。已取消的快捷键即使完全没有输入锁也不会产生动作，继续用它测试会假通过。当前 [镜头回归](Verify-Camera.gd) 和 [浏览器检查](verification/fixed-scene-transition-20261025/browser-check.cjs)覆盖相对鼠标与真实捕获；坐姿返回的镜头插值窗口也要发按键，不能只等稳定后检查。旧边缘 runner 保留为历史证据，现役测试入口随机制更新。

鼠标捕获与角色动作分别管理。网页实际锁定成功后才开放探索输入；程序为互动释放光标保留返场意图，用户退出或失焦取消该意图。捕获是异步操作，取消后晚到的成功通知也必须核对当前意图和焦点，并实际释放未获授权的锁定。相对环绕读取 `screen_relative.x`，不再按光标位置或帧时间积分。

固定场景的进入构图与游览来向分开：走近对齐完成后淡出，完全遮黑时直接使用坐位定义的机位并同步遮挡，淡入结束再播放 SitDown。原生 Tween 与一帧同步即可完成，不需要通用转场框架。[转场回归](verification/fixed-scene-transition-20261025/Verify-Transition.gd)核对不同来向/缩放下同一构图；绘制前状态采样只能说明提交前状态，实际连续画面中的完整黑帧另作像素证据。

Esc 的消费边界是一次按下到松开，不是某一帧的 mode：互动内开始起身后，同一次按键的 echo 或重复事件不能在返场时再触发外层暂停。失焦可能丢失 key-up，需要清理按键闩锁。正常返场保持游览；失焦和权限拒绝按既有规则手动继续。

纯引擎测试可以模拟外部锁定状态边界，但必须明确标注；实际网页权限证明使用真实点击／按键和 DOM 锁定状态。权限敏感的状态读取采用 CDP `userGesture: false`，避免自动化执行脚本本身制造用户激活。拒绝测试精确区分预期浏览器权限错误与其他脚本错误，并断言确实发生拒绝。

权限前提应在最后一次读取后仍成立：即使先确认瞬时激活已过期，随后用 `page.evaluate` 读取时间戳也可能重新赋予激活。时间戳与最终激活读值均用 CDP `userGesture:false`，之后直接发送真实 Esc；旧报告中更早的 `activation=false` 不等于发送按键前的最终状态。

用实际游戏帧或状态判定操控是否完成，固定墙钟等待不能保证游戏已经推进足够帧。首次加载、截图和高系统负载会使二者脱节。测性能时在最后截图后等待至少新增 600 个游戏帧，清除滚动窗口中的采集开销；保留原始窗口与独立补测，不以补测覆盖失败数据。

### 完整通过与局部通过

完整测试的总通过条件须同时包含功能、同版本焦点证据和性能门槛，退出码与汇总状态也要反映全部条件。功能通过或后补焦点通过，不能覆盖已有性能失败；主控人工验收缺口单独记录。局部输入检查、演示和性能专项只报告各自实际覆盖的范围。现役 [浏览器检查](verification/fixed-scene-transition-20261025/browser-check.cjs)、[焦点检查](verification/fixed-scene-transition-20261025/focus-check.cjs)和[拒绝检查](verification/fixed-scene-transition-20261025/refusal-check.cjs)各自记录覆盖范围，本轮控制专项汇总见 [fixed-scene-transition](verification/fixed-scene-transition-20261025/)；上一轮 [汇总器](verification/navigation-v2/summarize.cjs)仅判定原版本。

### 每轮证据独立归档

运行前冻结实际执行的 runner 并记录哈希，运行中记录浏览器实际请求的 PCK，结束时核对首尾构建收据。失败分支也保存已获得的版本、错误和状态证据，不能只在成功时写报告；实际做法见 [浏览器检查](verification/fixed-scene-transition-20261025/browser-check.cjs)和[焦点检查](verification/fixed-scene-transition-20261025/focus-check.cjs)的收尾路径。

成功原件及时归档，失败尝试使用独立输出，避免覆盖已有 PASS。后续说明、补测和证据索引更新另存版本，保留冻结的 runner、原始报告及其清单；不能重造遗失报告，或用后来的脚本冒充当时执行的版本。

### 差分回归的复用边界

先用代码、资产与数据对比证明未变范围，再决定复用哪些证据。旧控制用例只能支持未变控制组件，不能代替新资产或光照的视觉检查；同时标明原运行版本、原始次数与复用范围，不把旧轮次计成新包实际运行次数。

对比器的覆盖范围也需要审查：仅探索状态下的静态显隐相同，不能证明坐下、起身或不同 seat_id 下的行为相同。相关动态状态需要实际回归；没有收益证据而回退的试验不写成已采用的优化模式。

按 [README](README.md) 重建；Chrome分别检查两种分辨率、五坐位、六区通路、连续环绕和中间角度、缩放、跨区跟随和持续游玩。当前控制合同见 [相对鼠标游览与分层 Esc](design/mouse-look.md)，现役浏览器测试入口为 [fixed-scene-transition](verification/fixed-scene-transition-20261025/)，实际通过范围与剩余缺口见 [HOUSE](HOUSE.md)。测性能时记录实际GPU、viewport、canvas buffer、DPR、页面可见性与前后台条件，避免多个游戏页竞争GPU。若代码或资产在验收期间变化，先明确受影响范围再补相应证据。
