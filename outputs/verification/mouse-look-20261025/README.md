# 相对鼠标游览验证

本目录验证批准的 `outputs/design/mouse-look.md`。运行代码使用原生 Godot capture，测试只以真实键鼠请求网页权限；引擎中的外部锁定通知模拟不算网页证明。

## 当前命令

在项目根目录串行运行，保留 8767 预览服务；不要同时打开多个游戏测试页：

```powershell
./outputs/Build.ps1
node outputs/verification/mouse-look-20261025/browser-check.cjs 1366
node outputs/verification/mouse-look-20261025/browser-check.cjs 1920
node outputs/verification/mouse-look-20261025/refusal-check.cjs 1366
node outputs/verification/mouse-look-20261025/refusal-check.cjs 1920
node outputs/verification/mouse-look-20261025/focus-check.cjs 1366
node outputs/verification/mouse-look-20261025/focus-check.cjs 1920
```

每次执行前将已存在的同名结果目录另行归档，避免覆盖原件。每个 run 保存实际执行 runner、网络 PCK 和首尾构建收据。完整 campaign 功能与性能分别记录；退出码只有本次功能和已测性能均通过才为零。拒绝/失焦专项不宣称性能达标。1920 campaign 包含至少 180 秒实际键鼠连续游览。

`prepare-font.py` 保留基线字形并补当前提示，`font-receipt.json` 记录字体来源与字形覆盖。`engine-extra` 与 `Verify-Capture-Failure.gd` 补测晚到授权的真实 native mode 释放、拒绝捕获仍起身、失焦后退出不自动恢复；这些是明确标注的引擎边界模拟。

历史首候选 smoke 保留在 `smoke-1`、`seat-smoke-1366`，不算最终包完整覆盖。候选快照在 `work/mouse-look-20261025/candidate-*`；中止/路线载体失败在同 work 目录独立保存。保护基线覆盖资产、烘焙和之前冻结证据；本轮只改控制、必要字体、现役测试与网页导出。

## 本轮结果

最终候选 `scene-2a4b1894705b.pck`。四项构建检查通过；1366×768、1920×1080 共 10 次真实五座坐起、32 个重点角度/缩放视图通过，另一次重复 F/Esc 事件专项坐起通过。1920 连续游览 205.159 秒、5 圈。两尺寸真实 sandbox 拒绝/重试与新正常文档进入、真实切标签失焦/点击恢复均通过。

截图后至少 600 个新游戏帧的滚动均值：1366 的 6 个样本 11.580–11.774 ms；1920 的 21 个样本 16.052–19.154 ms。本轮使用 headless Chrome / Intel UHD / `?test`，不据此替代用户可见浏览器的精确 FPS，也不修改旧长测失败。早期路线载体失败及 421.63 ms 慢帧原件保留，未做性能优化或因果归因。

额外回归命令：

```powershell
node outputs/verification/mouse-look-20261025/browser-check.cjs 1366 --repeat-smoke
& work/tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path outputs/godot --script D:/vibe-code-life/3d-home/outputs/verification/mouse-look-20261025/Verify-Capture-Failure.gd
python outputs/verification/mouse-look-20261025/summarize.py
```

汇总入口为 `summary.json`；文件指纹为 `source-manifest.json`。后者不包含主控独占的 `review.md` 和 `owner-*` 证据，以免将主控后续验收误记为执行者原始文件。
