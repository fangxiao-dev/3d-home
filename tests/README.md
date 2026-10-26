# 现役验证入口

从项目根目录运行，Godot 的项目路径为 `godot/`。本机可执行路径读取 `work/godot-setup.json`。

| 脚本 | 关注范围 |
| --- | --- |
| `Verify-Scene.gd` | 导入场景、正式角色与动画资源 |
| `Verify-Playroom.gd` | 坐起、互动状态与输入隔离 |
| `Verify-House.gd` | 房间、碰撞和全屋连通约束 |
| `Verify-Camera.gd` | 镜头、相对鼠标位移映射与行走方向 |
| `Verify-Seat-Recovery.gd` | 自动走近／对齐受阻后恢复操控与重试 |

```powershell
$godotInfo = Get-Content work/godot-setup.json -Raw | ConvertFrom-Json
$godotExe = Join-Path $PWD $godotInfo.release.console_executable
& $godotExe --headless --fixed-fps 60 --path godot --script "$PWD/tests/Verify-Seat-Recovery.gd"
```

默认 `scripts/Build.ps1` 执行前四项；可用 `-SkipChecks` 只导入导出。按根 AGENTS 的轻量规则选问题路径及相邻正常流程，不要求每次执行整表。变更交互机制时维护对应现役测试，失效用例及时增删改。

历史网页 runner 和冻结结果见[历史档案](../docs/archive/README.md)，不自动视为当前可执行套件。网页检查使用真实操作，不通过测试脚本伪造产品状态。
