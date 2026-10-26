# 固定场景转场验证

基线为相对鼠标版 `scene-2a4b1894705b.pck`；本轮只改运行脚本、必要测试与网页导出。批准合同为 `outputs/design/fixed-scene-transition.md`。实际源差分和首候选位于 `work/fixed-scene-transition-20261025/candidate-1/`，不以 Git HEAD 的旧 dirty 差分代替本轮基线。

## 复现

在项目根目录串行执行，复用 8767 预览。已有同名结果目录应先另行归档，避免覆盖原件。

```powershell
./outputs/Build.ps1
& work/tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path outputs/godot --script (Resolve-Path outputs/verification/fixed-scene-transition-20261025/Verify-Transition.gd).Path
& work/tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path outputs/godot --script (Resolve-Path outputs/verification/fixed-scene-transition-20261025/Verify-Interruption.gd).Path
& work/tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path outputs/godot --script (Resolve-Path outputs/verification/fixed-scene-transition-20261025/Verify-Capture-Failure.gd).Path
node outputs/verification/fixed-scene-transition-20261025/browser-check.cjs 1366
node outputs/verification/fixed-scene-transition-20261025/browser-check.cjs 1920
node outputs/verification/fixed-scene-transition-20261025/browser-check.cjs 1366 --permission-smoke
node outputs/verification/fixed-scene-transition-20261025/browser-check.cjs 1920 --permission-smoke
node outputs/verification/fixed-scene-transition-20261025/focus-check.cjs 1366
node outputs/verification/fixed-scene-transition-20261025/focus-check.cjs 1920
node outputs/verification/fixed-scene-transition-20261025/refusal-check.cjs 1366
node outputs/verification/fixed-scene-transition-20261025/refusal-check.cjs 1920
python outputs/verification/fixed-scene-transition-20261025/measure-transitions.py
python outputs/verification/fixed-scene-transition-20261025/summarize.py
```

## 证据口径

- 核心矩阵最低14次：1366原段6次加同包书房补段1次，1920完整7次；入口软墩各含0/120/240度和近远缩放。原1366报告仍为失败，原因是其书房即时向右走路断言未达到120mm；修正载体往通道左行，保持时长、位移阈值和碰撞。补段从出生真实走到书房，不改写原报告。
- `*-frames` 是 Chrome 连续 screencast 实际 JPEG 帧与原始时间戳；`*-trace.json` 是 `frame_pre_draw` 提交状态。两类证据共同验证全黑切机位，不把内存 alpha1 当作已显示黑屏。`transition-metrics.json` 将转场窗口帧耗时与坐姿截图开销分开，不宣称新的长测性能结论。
- 首轮矩阵的 `activation_before_escape` 后还有一个 Playwright evaluate，不能用作最终过期激活权限证明；原件保留。独立 `permission-smoke-*` 修正为所有末尾读取均 CDP `userGesture:false`，6.5秒后最后读到false即真实Esc；1920另验证已回EXPLORE、仍未松Esc时的真实trusted repeat。
- 三相位中断、短black窗口、丢keyup、捕获失败退出是明确的引擎外部状态模拟。Chrome focus专项是真实换tab；sandbox专项记录实际权限拒绝/重试，再导航新正常文档真实进入，不称同一sandbox原地获得权限。
- 所有浏览器结果保存执行runner、真实PCK请求、首尾收据、错误与截图。主控独占的 `owner-*` 与 `review.md` 不进入执行者manifest；主控原生窗口验收另存。

## 当前执行结果

最终包 `scene-4315d056df83.pck`，已原样归档至 `package/`。核心网页矩阵14次完成（1366为6+1，1920为7），另有首轮smoke1次、干净权限补证2次、真实转场失焦2次。四项构建检查、30组机位一致性、3相位中断/丢keyup和2个捕获失败/中断退出模拟通过。所有1115项受保护资产与旧证据逐SHA不变。

四组连续画面均捕获到实际全黑帧；16条实际尝试轨迹中，从首次提交淡出到首次完全显现SitDown的观察区间为346–410ms，转场提交帧最大间隔58ms。这是记录路径的短窗口观察，不是新的长期FPS验收。`summary.json`保留原失败和补测的版本归属。

主控原生窗口检查因工具无法可靠确认浏览器URL而停止，仍为 `EVIDENCE_GAP`；主控另行进行的已知URL headless操作检查保存在排除于本manifest的 `owner-*`，不能称原生前台人工验收。
