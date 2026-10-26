# 当前游览控制验证

合同：[游览控制改造](../../design/navigation-v2.md)。本目录为 2026-10-25 新控制的测试入口；`../scene-v2/` 是旧版本历史证据。

最终保留包为 `scene-1a42f717cba2.pck`。当前包功能和独立真实焦点检查通过；1920 长测仍有 19/52 个滚动均值超过 40 ms，且主控实际 Chrome 界面检查为 `EVIDENCE_GAP`，因此 `summary.json` 的总验收为 false。

一次有边界的显隐缓存试验已回退，未留在产品代码或当前网页包中。[试验决策与 A-B-A 谱系](perf-trial/decision.json) 保存全部短窗：原包 37.71/40.79 ms、试验包 32.07/29.27 ms、恢复原包 28.14/30.70 ms（各为普通页/测试页）。无法确认整体帧率收益；336 个 Explore 状态等价和 20 个局部画面通过不等于试验包的新坐位或长测验收。当前源码、Web 索引、PCK 和构建收据已与回退基线逐 SHA 核对。

从项目根目录执行：

```powershell
./outputs/Build.ps1
./outputs/Start-Preview.ps1 # 已有服务时复用
```

R3 遮挡修复后的当前版本使用 `--fixed`，结果独立保存到 `fixed-*`，不覆盖旧包。每次运行先复制脚本到对应目录的 `runner.cjs`，再执行该快照，以便与报告中的启动 SHA256 核对：

```powershell
New-Item -ItemType Directory -Force outputs/verification/navigation-v2/fixed-1366 | Out-Null
Copy-Item outputs/verification/navigation-v2/browser-check.cjs outputs/verification/navigation-v2/fixed-1366/runner.cjs
node outputs/verification/navigation-v2/fixed-1366/runner.cjs 1366 768 --fixed
New-Item -ItemType Directory -Force outputs/verification/navigation-v2/fixed-1920 | Out-Null
Copy-Item outputs/verification/navigation-v2/browser-check.cjs outputs/verification/navigation-v2/fixed-1920/runner.cjs
node outputs/verification/navigation-v2/fixed-1920/runner.cjs 1920 1080 --fixed soak
```

其余当前包测试同样先复制 `browser-check.cjs` 到对应目录的 `runner.cjs`，再运行：

```powershell
node outputs/verification/navigation-v2/fixed-1366-occlusion/runner.cjs 1366 768 --fixed --occlusion-only
node outputs/verification/navigation-v2/fixed-1366-input-smoke/runner.cjs 1366 768 --fixed --input-smoke
node outputs/verification/navigation-v2/fixed-1366-performance/runner.cjs 1366 768 --fixed --perf-only
# 将 performance-comparison.cjs 冻结为 performance-comparison/runner.cjs
node outputs/verification/navigation-v2/performance-comparison/runner.cjs
# 同一脚本另冻结到 performance-comparison-study/runner.cjs，真实方向键走到书房
node outputs/verification/navigation-v2/performance-comparison-study/runner.cjs --study
# 将 focus-check.cjs 冻结为 focus-run/runner.cjs；使用独立 Chrome profile
node outputs/verification/navigation-v2/focus-run/runner.cjs
# 所有性能与焦点测量结束后才录制短演示
node outputs/verification/navigation-v2/fixed-1366-demo/runner.cjs 1366 768 --fixed --demo
node outputs/verification/navigation-v2/summarize.cjs
```

当前包命令统一带 `--fixed`。`1366-prefix/`、`1366/`、`1920/`、`1366-performance/` 是旧 C423 包的历史证据，不作为新测试输出目录。真实焦点可在主 campaign 之后补充，汇总按相同 PCK 合并；原 campaign 的 `focus_pending` 原样保留。

性能对照同时记录 rAF 与测试页真实游戏帧推进比例；普通页没有游戏快照，只能在此校准边界内讨论其 rAF。书房使用同一组真实按键时长，并保留两页截图、每段实际命令耗时及测试页最终坐标/角度/缩放；小机位差异和顺序测量不支持精确因果归因，短窗结果不替代长测门槛。

当前包另跑 `--fixed --occlusion-only`、`--fixed --input-smoke`，各自先冻结 runner。前者覆盖厨房冰箱显隐、阳台柜门与客厅落地感共 20 个近远视角；后者核验边缘深度对应转速、中央停止和 W/A/S/D 四键的实际正向移动。完整 campaign 的开头包含 controls/seam smoke，也可用 `--fixed --smoke` 单独运行。`--fixed` 保留七区域、八角度、近远缩放全部 112 组/分辨率，并检查物理与可见渲染三角形的头胸髋视线；五坐位每处一次/分辨率。旧包每处三次共 30 次的控制/坐起回归仅按 `r3-control-reuse.json` 中 19 个未变函数复用，旧厨房 45° 画面有遮挡，不作为当前模型视觉证据。

`verify-asset-semantics.py` 在重烘焙前检查稳定家具归属及 `camera_occluder ⇒ 非静态烘焙`。真实渲染三角形观测缓存几何、先筛包围盒，仅测试快照使用；按 surface 材质跳过实际 Alpha 透明表面，不跳过无碰撞的实心门板。普通试玩不增加这项逐帧观测。`versions/76edbca45168/` 原样保留中间包的功能结果、悬空门板与烘焙残影证据；其功能断言通过不代表视觉通过。

最终汇总入口为 `node outputs/verification/navigation-v2/summarize.cjs`，写入 `summary.json`。它区分旧包部件证据和当前包实际覆盖，并检查版本、runner 快照、几何不变性及新十分钟游览；性能或真实焦点/主控界面验收缺口会保留为未通过，不将其改写为完成。

浏览器测试串行运行，测试前暂离其他游戏页面以减少 GPU 竞争。当前脚本复用本机已有 Playwright 与 Chrome；失败返回非零退出码。

主功能使用 headless Chrome，等待至少 600 个预热帧后进行输入测试；`--demo` 单独录制原速控制与跨区短演示，避免全程录像干扰长测。Playwright 默认模拟所有页面始终有焦点，因此真实焦点另由 `focus-check.cjs` 启动隔离可见 Chrome profile，并以 `connectOverCDP({noDefaults:true})` 检查真实切换标签。它核验浏览器 `document.hidden/hasFocus()` 与恢复后的镜头状态；主报告只有在此证据通过且 PCK、运行哈希相同时才通过。隐藏页面暂停更新引擎快照，不能用隐藏页的旧快照判断焦点状态。隔离 profile 留在忽略的 `work/navigation-v2/`，测试 Chrome 退出后不影响用户日常浏览器。

- 构建运行资产、五坐位、六区与镜头四项引擎检查。
- 浏览器使用真实鼠标/键盘操作，只读 `?test` 观测状态。覆盖边缘激活、速度与停止、面板、离画布、失焦、重新激活、整圈、任意角度移动和窗口缩放。
- 五坐位每处三次；坐姿锁定使用鼠标边缘和滚轮，退出保持原角度并重新等待中央激活。
- 七个观察区域每 45°、近远缩放；六区通行、四类边界；仅按下/上方向键的客厅—走道—餐厅往返保存逐帧记录。
- `soak` 增加至少十分钟真实跨区与转向。当前性能标准为采样 600 帧滚动均值不超过 40 ms（至少 25 FPS），记录 p95 和实际 GPU；功能与性能结果分别报告。
- 性能窗口从最后一次截图之后计数至少 600 个真实游戏帧，再开始采样；`--perf-only` 从出生点实际走到书房固定位置单独测量。截图扫描后的旧窗口保留作原始数据，不自动当作干净的运行性能。
- 每次结果保存到分辨率子目录，含 `report.json`、`seam-frames.json` 和截图；`*-demo/` 保存原速 WebM。报告核对浏览器实际 PCK 与首尾构建收据。`progress.json` 提供实时阶段、坐起和区域计数。

UI 字体由 `prepare-font.py` 从 Google Fonts 的 Noto Sans SC 400 按所需字符生成，沿用原字体许可；已有字符一并保留。

本次 1366 验证分两段：`1366-prefix/` 原样冻结一次中断运行中已经通过的 9 次坐起、2 个完整区域扫描、控制专项和原路线；整个前段运行仍为失败，不改写成通过。续段以 `--resume=outputs/verification/navigation-v2/1366-prefix/report.json` 从出生点实际行走，重测失败角度并完成剩余 6 次坐起、5 区。报告记录前段哈希与独立 case，汇总去重；前段没有保存网络 PCK 回执，其版本归属仅由冻结收据和 runner 辅助，续段及 1920 保存实际网络 PCK 和首尾收据。

`functional_pass` 表示当前功能组的结果；缺少可用的独立焦点报告时 `focus_pending=true`、总 `pass=false`。主控实际界面验收和最终 acceptance 另行记录，不能从功能结果推导。

当前 canonical 完整 campaign 的总 `pass` 同时要求功能、同包真实焦点和性能窗口全部通过。局部 `--occlusion-only`、`--input-smoke`、`--demo` 的 `pass` 仅覆盖各自声明的范围，不能推导未测性能。已冻结矩阵 runner 保持原文：其旧总 gate 曾漏纳性能，但本轮原 `pass=false` 没有重写；最终汇总单独要求两分辨率性能均达标，后补焦点或普通页对照不会覆盖 1920 长测中已有的失败窗口。

当前证据是否通过以各报告和主控验收为准，脚本存在不代表测试已完成。
