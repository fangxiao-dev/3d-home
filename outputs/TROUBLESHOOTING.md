---
status: active
doc_type: runbook
source_of_truth: godot/playroom.gd, Verify-Scene.gd, Verify-Playroom.gd, Build.ps1, README.md, PLAYROOM.md
last_verified_at: 2026-10-17
---

# 常见现象与排查入口

仅收录本阶段实际遇到、且已有实现或验收证据的问题。当前行为以 [PLAYROOM.md](PLAYROOM.md) 为准。

| 现象 | 先确认 | 已有恢复方式或证据 |
| --- | --- | --- |
| 网页仍显示旧家具、旧角度 | HTML 的 `GODOT_CONFIG.mainPack` 与浏览器实际请求的包名是否一致；服务是否来自当前项目 | [README 的资源指纹说明](README.md)；[Build.ps1](Build.ps1) 生成 `scene-<hash>.pck`。页面 `?v=` 改了不代表资源包更新；在用户实际使用的内置浏览器复核。不要以另一个新浏览器正常作为完成依据。 |
| 变回测试方块或只有观察视角 | `project.godot` 的 `run/main_scene`，当前服务目录与导出内容 | 当前游戏入口是 `playroom.tscn`，使用现有 Blender GLB；`main.tscn` 仅用于独立观察。两种验证器的范围见 [README](README.md)。 |
| 看起来像鸟瞰，远高于预期 | 角度相对哪个平面、当前基线、相机与目标的高度差 | [镜头公式与坐标约定](IMPLEMENTATION_NOTES.md)；用户接受的是低机位基础上增加约 10°，当前约 29°。 |
| F 提示缺字，但中文正常 | 字体子集是否含新增字符，也包括 F、Q/E、Esc 与数字 | [README 字体边界](README.md) 与 [PLAYROOM 验收](PLAYROOM.md)。不能从中文可读推断 ASCII 字符齐全；本轮没有形成可从全新检出复现的字体生成流程。 |
| 特写返回后继续转动、漂移或长按立即走动 | 是否复用了已有状态保存恢复，是否绕过 `transition_busy` 或 `awaiting_movement_release` | `_save_exploration_state` 保存当时显示的 yaw/zoom 并取消未完成目标；返回后等待移动键释放。已有回归入口在 [Verify-Playroom.gd](Verify-Playroom.gd)，状态合同见 [PLAYROOM](PLAYROOM.md)。 |

## 墙、顶或吊灯挡住镜头

这一问题分三层排查，入口在 [playroom.gd](godot/playroom.gd) 的 `_visibility_group_for` 和 `_update_visibility_for_camera`：

1. **导入分类。** 在 Godot 导入后的节点读取 `get_meta("extras", {}).get("category", "")`。历史问题是直接读取顶层 category，导致顶面未被识别；[初始化记录](VERIFICATION.md) 与 [Verify-Scene.gd](Verify-Scene.gd) 保留了证据和检查。
2. **组内附件。** 窗、窗帘和阳台开口属于 `rear_window`；壁灯、壁挂电视属于 `right_wall`；门、墙框与墙饰按左右墙分组。`Chandelier` 命名前缀归入 `ceiling_top`，避免只隐藏屋顶后仍剩吊灯挡住人物。独立家具与地板保持可见。
3. **当前机位。** 判断使用房间边界和相机位置；房间变宽后需同步边界。四个方向及缩放两端检查，不应为了某一个画面把所有墙和家具整类隐藏。

隐藏只改变渲染节点的可见性，不移除物理碰撞。用实际按键走向被隐藏的墙，确认仍不能穿出房间；进入、退出特写后复查遮挡恢复。当前宽房间的截图与实操记录统一从 [PLAYROOM.md](PLAYROOM.md) 查找。

## 排查时保留可对照的版本

先核对正在运行的场景、源脚本、GLB 和浏览器资源包，再决定是否重新构建。`work/` 内日志与临时检查脚本不进入 Git，名称相似也可能属于旧版本；历史记录中的 E 开灯、50° 镜头或旧家具数量不能覆盖当前合同。可重建入口是 [Build.ps1](Build.ps1)，最新验收入口是 [PLAYROOM.md](PLAYROOM.md)。
