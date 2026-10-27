# 现役验证入口

从项目根目录运行，Godot 的项目路径为 `godot/`。本机可执行路径读取 `work/godot-setup.json`。

| 脚本 | 关注范围 |
| --- | --- |
| `Verify-Scene.gd` | 导入场景、正式角色与动画资源 |
| `Verify-Playroom.gd` | 坐起、互动状态与输入隔离 |
| `Verify-House.gd` | 房间、碰撞和全屋连通约束 |
| `Verify-Camera.gd` | 镜头、相对鼠标位移映射与行走方向 |
| `Verify-Seat-Recovery.gd` | 自动走近／对齐受阻后恢复操控与重试 |
| `Verify-Letters.gd` | 文集分页、字形、图片、领取幂等、穿戴与输入隔离；引擎检查不替代网页视觉验收 |
| `Verify-LettersContent.ps1` | 15 篇正文、7 图、来源展示文本一致性与目录完整性；独立 PowerShell 检查 |
| `Verify-Study-Access.gd` | 书边与椅子周边（含贴椅背）6 个合法站位的 F 目标、阅读与坐起；B 返回的鼠标授权边界为引擎模拟 |
| `Verify-Birthday.gd` | 蛋糕状态、条件组合、两种准备顺序、重复输入、仪式暂停／结束／重播、F 入口与餐厅合法站位；鼠标授权和按钮激活仅为引擎证据 |
| `Verify-2048.gd` | 四方向与单次合并、得分、90/10 随机生成、无效步、胜负、合法茶几站位、邻近目标、输入隔离、重开与本次进度；鼠标授权为引擎模拟 |

```powershell
$godotInfo = Get-Content work/godot-setup.json -Raw | ConvertFrom-Json
$godotExe = Join-Path $PWD $godotInfo.release.console_executable
& $godotExe --headless --fixed-fps 60 --path godot --script "$PWD/tests/Verify-Seat-Recovery.gd"
```

默认 `scripts/Build.ps1` 执行前四项、`Verify-Letters.gd`、`Verify-Study-Access.gd`、`Verify-Birthday.gd` 与 `Verify-2048.gd`；可用 `-SkipChecks` 只导入导出。按根 AGENTS 的轻量规则选问题路径及相邻正常流程，不要求每次执行整表。变更交互机制时维护对应现役测试，失效用例及时增删改。

历史网页 runner 和冻结结果见[历史档案](../docs/archive/README.md)，不自动视为当前可执行套件。网页检查使用真实操作，不通过测试脚本伪造产品状态。
