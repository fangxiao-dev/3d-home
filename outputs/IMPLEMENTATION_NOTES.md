---
status: active
doc_type: implementation-pattern
source_of_truth: blender/build_living_room.py, godot/playroom.gd, Verify-Playroom.gd, Verify-Scene.gd, Build.ps1
last_verified_at: 2026-10-17
---

# 接着做之前：实现入口与已验证的方法

当前基础视图、操作和风格已获用户认可。后续在现有客厅上增量实现；产品选择看 [PROJECT.md](PROJECT.md)，玩法合同与最新验收看 [PLAYROOM.md](PLAYROOM.md)。本文记录修改方法，参数变化时以源代码为准。

## 新会话的最短接续路径

1. 按 [AGENTS.md](../AGENTS.md) 读项目总览和背景入口，区分已确认创意与尚未确定的故事。
2. 确认正在实际项目根目录工作，先看 Git 状态，保留其他会话改动。当前接受的版本尚在工作树中，不能仅凭初始化提交恢复。
3. 按下表定位已有实现；构建与预览命令统一用 [README.md](README.md)。只改玩法通常不需重建 Blender；改生成脚本则使用 `-RebuildModel` 同步源模型、GLB 与网页。
4. 用 [PLAYROOM.md](PLAYROOM.md) 的验收步骤检查修改范围，在用户使用的浏览器查看结果。`work/` 中的旧脚本和日志可辅助定位，但可能包含旧按键、旧坐标与旧角度，不能直接当当前验收标准。

| 要改什么 | 先看哪里 | 需要一起检查 |
| --- | --- | --- |
| 家具、布局、材质 | [建模源脚本](blender/build_living_room.py) | 节点名与分类、碰撞、互动点、固定镜头 |
| 人物、镜头、互动 | [playroom.gd](godot/playroom.gd) | 状态保存恢复、遮挡组、UI 字符、实际按键 |
| 游戏启动场景 | [project.godot](godot/project.godot) | 当前是 `playroom.tscn`；`main.tscn` 是独立观察场景 |
| 构建与导出 | [Build.ps1](Build.ps1) | 两个验证器、资源内容指纹、实际浏览器加载 |
| 逻辑回归 | [Verify-Playroom.gd](Verify-Playroom.gd) | 数值断言与浏览器视觉互补 |

## 模型如何接到游戏

**节点名与 `extras.category` 是已有接口。** Blender 的生成函数写入 category，导出开启 `export_extras`；Godot 从节点的 `extras` 字典读分类，再结合名称前缀分组。改名字或分类可能同时影响碰撞、屋顶隐藏和互动识别。修改后检查实际导入节点；[Verify-Scene.gd](Verify-Scene.gd) 保留了分类导入检查，不能只检查 Blender 内的对象。

**家具碰撞跟随网格，房间尺寸仍需两边同步。** `playroom.gd` 的 `_bounds`、`_solid_furniture` 用导入网格的全局 AABB 建简单家具碰撞。地面与水平边界使用 `ROOM_WIDTH/ROOM_DEPTH`，入口和阳台边界的碰撞高度仍是固定值；`ROOM_HEIGHT` 参与顶面可见性阈值，左右墙体高度来自导入模型。Blender 的 `W/D/H` 改动不会自动更新这些常量。扩房间时一起检查墙、地砖、顶面、窗、墙饰和两侧家具组；不要把家具也按房宽比例拉伸。[建模说明](LIVING_ROOM.md) 记录当前布局选择。

**目标与特写部分依附家具，并非所有坐标自动跟随。** `_build_room` 从软墩 bounds 计算查看点；长沙发目标与坐位的 X 来自 bounds，但高度和纵向 Z 仍是固定值。`_register_closeup_presets` 再相对目标或坐位设置机位。本次横向平移可沿用这条计算链；以后改变沙发纵向位置、座高或尺度，必须重新核对固定值。检查触发点、标记、坐位和特写构图，而不仅是物件是否移动。

## 镜头调整先明确角度的含义

`_camera_position_for` 中，俯角是**相机视线相对水平面向下的角度**；水平距离不等于人物到相机的斜线距离。

```text
水平距离 = CAMERA_DISTANCE × zoom
相机与观察目标的高度差 = 水平距离 × tan(俯角)
```

水平距离与高度差一起缩放，才能保持俯角。原低机位约 19°，“再抬高 10°”对应约 29°；此前直接使用 50° 导致视角过高。之后若用户说“再抬一点”，先基于当前角度解释增量，再用同机位画面对比。数值检查覆盖缩放两端，视觉检查覆盖人物附近家具与顶面遮挡。

Godot 水平面使用 X/Z，阳台在 -Z。当前偏移为 `(sin(yaw), cos(yaw))`：初始相机在人物 +Z 侧，Q 增加 `PI/2` 后到 +X 侧，E 相反。这是从房顶向下看的旋转约定。验证时等待约 0.3 秒旋转结束，再检查位置和方向；同时验证按上是否沿画面深处移动，避免仅看 yaw 正负判断正确性。

## 互动的遮挡验证可复用

`_nearest_interaction_target` 先过滤距离与射线可达性，再选最近目标；射线允许命中目标自身的碰撞体。新增互动可沿用 [Verify-Playroom.gd](Verify-Playroom.gd) 的负例：

1. 把人物放在目标前的可达位置，确认唯一可用目标正确。
2. 在人物与目标之间加入临时阻挡物，确认提示消失，F 无效。
3. 移除阻挡物，确认原目标重新可用。

碰撞检查选家具主体的中间位置，避开圆角；从角上绕过不等于穿过。头顶、眼睛、腿部与坐垫的视觉关系仍需实际截图检查。

固定镜头已有保存、输入锁定和恢复机制，见 [PLAYROOM.md](PLAYROOM.md) 与 `_save_exploration_state`、`_restore_exploration_state`；新增彩蛋复用已有 preset。坐姿只移动人物视觉节点，探索碰撞体留在进入位置。不要另造平行的镜头或互动系统来承载下一个彩蛋。

## 证据应回答不同问题

Blender 渲染回答模型与离线画面的效果；Godot 检查回答导入和行为是否满足断言；浏览器实操回答交付页面是否加载新版本、看得清且能操作。三者不可互相代替。代码版本、GLB 与实际请求的资源包需对应同一次构建；当前实操证据入口保留在 [PLAYROOM.md](PLAYROOM.md)。出现异常时用 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) 定位。
