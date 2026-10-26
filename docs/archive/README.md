# 历史档案

本目录保存旧阶段说明、冻结验证报告和对应 runner。它们用于追溯，不是当前状态、操作或测试命令的权威入口。原件保留旧版本路径、结论及失败记录；其中相对链接、绝对路径和本地截图可能不再适用于当前目录，也不保证可在 GitHub 打开。

## 阶段记录

- [项目历程](project-history.md)、[全屋交付与验收历史](house-history.md)
- [操作与原型验收历史](playroom-history.md)、[旧客厅观察与建模](living-room.md)
- [阶段复盘](retrospective.md)、[初始验证](initial-verification.md)
- [场景 V2 原始规格与执行快照](scene-v2-history.md)

## 验证原件

`verification/` 按阶段和调查名称保存报告、数据与 runner；大体积截图、录像和资源包只留本地。

- [场景 V2](verification/scene-v2/browser-check-README.md)
- [边缘控制历史](verification/navigation-v2/README.md)
- [相对鼠标游览](verification/mouse-look-20261025/README.md)
- [固定场景转场](verification/fixed-scene-transition-20261025/README.md)
- [性能调查](verification/perf-diagnosis-20261025/report.md)
- [纯色表面调整](verification/solid-surfaces-20261025/README.md)

旧 `outputs/godot/`、`outputs/blender/` 分别迁到根目录 `godot/`、`blender/`；构建启动脚本迁到 `scripts/`，现役 `Verify-*` 迁到 `tests/`。需要再次执行历史 runner 时先核对它针对的资产版本与路径，不批量改写历史原件冒充当前测试。

当前入口：[状态](../status.md) · [现役测试](../../tests/README.md)。
