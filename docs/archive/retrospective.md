# 基础客厅阶段复盘 · 2026-10-17

用户已认可基本视图、操作与风格。本轮复盘完成知识补缺：以后从 [PROJECT.md](PROJECT.md) 接续产品背景，从 [实现经验](IMPLEMENTATION_NOTES.md) 定位改动入口，遇到异常查 [排障说明](TROUBLESHOOTING.md)。完整生日礼物的剧情、角色与彩蛋仍由后续设计推进。

最重要的结论是：照片提供辨识元素与相对关系，空间比例服务于舒服的卡通画面；已有模型、控制和固定镜头机制应继续复用。审美结果最终以用户看到的实际浏览器画面为准。

## 来源快照

- 仓库与工作树：`D:\vibe-code-life\3d-home`；branch：`main`。
- Source HEAD：`45aef745459b89603a79ac12ef67ef0a00d92517`。
- dirty：`true`；采集时 17 个 tracked changes、95 个 untracked files。接受的玩法版本包含工作树改动，HEAD 仅是初始化基线。
- sources=12。两个只读审计与主控共用此快照；本轮只写知识文档。

| # | 来源 | 用途 |
| --- | --- | --- |
| 1 | 当前原生会话 `codex://threads/01a13ed8-80be-75e1-9c6e-a37847bb2a58` | 用户选择、修改经过、实际故障与验收边界 |
| 2 | [PROJECT.md](PROJECT.md) | 当前目标与确认事项 |
| 3 | [LIVING_ROOM.md](LIVING_ROOM.md) | 照片解读、建模取舍 |
| 4 | [PLAYROOM.md](PLAYROOM.md) | 当前操作与验收 |
| 5 | [README.md](README.md) | 软件、运行和构建 |
| 6 | [build_living_room.py](blender/build_living_room.py) | 模型生成事实 |
| 7 | [playroom.gd](godot/playroom.gd) | 游戏实现事实 |
| 8 | [Build.ps1](Build.ps1) | 构建与内容指纹 |
| 9 | [Verify-Playroom.gd](Verify-Playroom.gd) | 游戏回归检查 |
| 10 | [Verify-Scene.gd](Verify-Scene.gd) | 观察场景导入检查 |
| 11 | `work/wide-model-comparison.json` | 本地宽房间模型对比证据 |
| 12 | `work/wide-iab-verification.json` | 本地内置浏览器实操证据 |

`work/` 证据被 Git 忽略，不能作为新检出的唯一接续资料；持久验收入口是 PLAYROOM。AGENTS、agent profiles、历史验证和字体临时脚本仅用于治理与事实校准，不另立来源包或新配置。

## 审计与落地统计

model-builder 负责实现经验的只读审计，model-reviewer 负责稳定约定的只读审计，主控校准、去重并唯一写入。没有 stable-docs 配置，采用显式来源兼容分支；没有创建 Gate、package 或额外索引。

| 知识 lane | status | candidates | applied | already-covered | no-delta | source-insufficient | pending | conflict |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 实现与排障 | ran | 7 | 7 | 5 | 1 | 1 | 0 | 0 |
| 稳定约定 | ran | 2 | 2 | 8 | 1 | 0 | 0 | 0 |

实现审计原提案为 8 个候选；主控将“取消灯互动后保留静态碰撞”归为已覆盖的稳定行为，不另写实现模式。因此最终候选为 7、已覆盖为 5；没有静默丢弃条目。链接到已有恢复机制和缓存说明属于导航，不重复建立合同。

| 环境 lane | status | recommendations | owner-gap | already-covered | no-delta | source-insufficient |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 主控七类扫描 | ran | 2 | 0 | 3 | 2 | 0 |

跨 lane considered=32（14 个实现审计项、11 个稳定语义项、7 个环境扫描项），merged=5，split=1。计数保留审计原始粒度；合并表示共享唯一沉淀处，不是额外应用次数。

### 实现审计逐项归宿

| item ID | 最终处理 | primary destination |
| --- | --- | --- |
| `outputs/godot/playroom.gd::yaw-sign-QE` | applied | IMPLEMENTATION_NOTES：镜头坐标与旋转检查 |
| `outputs/godot/playroom.gd::pitch-preserving-zoom` | applied | IMPLEMENTATION_NOTES：俯角公式与增量解释 |
| `outputs/blender/build_living_room.py::glb-extras-runtime-contract` | applied | IMPLEMENTATION_NOTES：名称、extras 接口 |
| `outputs/godot/playroom.gd::bounds-derived-collision-and-room-extents` | applied | IMPLEMENTATION_NOTES：碰撞与尺寸同步 |
| `outputs/godot/playroom.gd::target-closeup-relative-binding` | applied | IMPLEMENTATION_NOTES：目标与相对机位 |
| `outputs/godot/playroom.gd::cutaway-render-groups` | applied | TROUBLESHOOTING：遮挡组排查 |
| `outputs/Verify-Playroom.gd::los-blocker-fixture` | applied | IMPLEMENTATION_NOTES：遮挡负例 |
| `outputs/godot/playroom.gd::static-lamp-collider-after-action-removal` | already-covered，合并 1 | PLAYROOM：现有互动合同 |
| `outputs/godot/playroom.gd::fixed-state-capture-lock-restore` | already-covered，合并 2 | PLAYROOM：状态恢复合同 |
| `outputs/Build.ps1::hash-pack-IAB-cache` | already-covered，合并 3 | README：资源指纹；排障页仅链接 |
| `outputs/README.md::Blender-Godot-coordinate-transform` | already-covered，合并 4 | README：源与运行时轴向 |
| `work/wide-model-comparison.json::real-IAB-acceptance` | already-covered，合并 5 | PLAYROOM：当前验收证据 |
| `outputs/README.md::font-subset-ASCII-coverage` | source-insufficient，拆分 1 | 本报告证据缺口：完整字体复现流程未沉淀 |
| `outputs/blender/build_living_room.py::material-assignment` | no-delta | 无新增目的地：没有足够故障证据支持另写材质排障 |

### 稳定语义逐项归宿

| item ID | 最终处理 | primary destination |
| --- | --- | --- |
| `outputs/README.md::historical-verification-entry` | applied | README：初始化历史与当前验收分流 |
| `outputs/README.md::verification-script-targets` | applied | README：两个验证器的检查范围 |
| `outputs/PROJECT.md::room-vs-gift-scope` | no-delta | PROJECT：现有阶段范围足够清楚 |
| `codex://threads/01a13ed8-80be-75e1-9c6e-a37847bb2a58::milestone-scope` | already-covered | PROJECT：已完成与后续设计 |
| `outputs/LIVING_ROOM.md::cartoon-photo-led-model-boundary` | already-covered | LIVING_ROOM：风格与照片边界 |
| `outputs/blender/build_living_room.py::wide-room-generation-boundary` | already-covered | LIVING_ROOM：当前建模选择 |
| `outputs/PLAYROOM.md::input-interaction-contract` | already-covered；接合并 1 | PLAYROOM |
| `outputs/godot/playroom.gd::runtime-state-camera-collision-contract` | already-covered；接合并 2 | PLAYROOM |
| `outputs/Verify-Playroom.gd::playroom-verification-contract` | already-covered | PLAYROOM |
| `outputs/README.md::tool-resource-cache-font-boundary` | already-covered；接合并 3、4 | README |
| `work/wide-model-comparison.json::wide-room-acceptance-evidence` | already-covered；接合并 5 | PLAYROOM |

## 环境改进：仅建议，未实施

| 类别 / item ID | 证据与判断 | 处理与 primary destination |
| --- | --- | --- |
| Navigation / `environment::navigation` | 项目已迁移，宿主上下文仍可能指向旧目录；现有 AGENTS、PROJECT 和 README 已提供接续入口 | already-covered → 现有项目入口 |
| Automated checks / `environment::font-coverage` | 曾出现中文正常但 F 提示缺字；本地 `work/prepare_play_font.py` 手工列字符且未进入 Git，当前构建不检查 UI 字符覆盖 | recommendation → 本报告：下次新增文案时，由项目 model-builder 将字体生成入口纳入版本控制并校验实际 UI 字符覆盖。与完整排障配方证据不足分属两种干预（拆分 1） |
| Coding standards / `environment::coding-standards` | 现有生成脚本、Godot 状态和验证入口足以继续增量实现 | no-delta → 不新增框架或规则 |
| Instruction placement / `environment::instruction-placement` | AGENTS 已定义入口，仓库两个 profile 已划分实现与只读审查责任 | already-covered → 现有 AGENTS 与 profiles |
| Tool economy / `environment::bounded-generated-search` | 排查缓存时整行读取压缩后的 `index.js` 产生大量无关输出；截取目标配置才获得有效证据 | recommendation → 本报告：由 agent-workbench 工具维护者在文件检索入口增加超长行截断和命中附近片段输出，减少生成资源挤占上下文 |
| No-ops / `environment::no-ops` | 本轮知识更新无需重新导出游戏；没有证据支持引入清理或构建调度系统 | no-delta → 无新增目的地 |
| Information access / `environment::information-access` | 背景与照片已有入口，外部素材 junction 与网页资源边界已说明 | already-covered → PROJECT、README |

## 修改与验证边界

本轮修改 5 个文件：根目录 `README.md`、`outputs/README.md`、`outputs/IMPLEMENTATION_NOTES.md`、`outputs/TROUBLESHOOTING.md`、`outputs/RETROSPECTIVE.md`。保留原有文档分工，没有另建 CONTEXT、词汇表或全局记忆。

未解决 owner decision=0；知识写入 pending=0、conflict=0。证据缺口=1：字体子集的完整可复现生成流程；本轮没有把本地临时脚本包装成已验证的通用配方，不阻塞其余知识交付。环境建议=2，留待相应维护工作时决定是否实施。

residue/cleanup=0：本轮没有删除或迁移旧文件，没有生成临时来源包。原有工作树改动、未跟踪背景资料与截图全部保留；没有提交 Git 或修改代码、模型、配置、权限、agent instructions。

验证：使用 stable-docs 验证器的只读路径与链接检查函数，对显式列出的 5 个文档检查通过，64 个本地链接均可解析；两份维护型文档的 metadata 与 source_of_truth 路径有效。采用兼容分支，没有运行依赖配置与 package inventory 的完整 CLI 验证。

两份 README 无实际盘符路径；5 份文档空白检查与 `git diff --check` 通过。模型生成脚本、玩法脚本、构建脚本、两个验证器及 GLB 共 6 份文件的 SHA256 与本轮写文档前完全一致。本轮未重跑游戏验收，游戏现状依据既有 PLAYROOM 记录。

model-reviewer 独立复核 PASSED：首轮发现的尺寸常量职责、遮挡附件归组、来源路径统一共 3 项均已修正并增量确认关闭，残留问题=0。
