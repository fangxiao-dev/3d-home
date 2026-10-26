---
status: investigated
doc_type: performance-diagnosis
last_verified_at: 2026-10-25
---

# 性能开销诊断

当前可重复测量的主要成本在场景渲染链。材质相关绘制、实时阴影、MSAA 抗锯齿都有显著边际成本；普通每帧脚本约 2.9 ms，不能解释整帧三十多毫秒的大部分。现有证据不支持先削减模型细节。GPU 执行与 CPU 驱动等待尚未完全拆开，不能给出精确占比或唯一底层根因。

本轮只诊断，当前试玩仍是 `scene-1a42f717cba2.pck`，源运行脚本为 `181ecd08…`。工作目录 `D:/vibe-code-life/3d-home`，分支 `main`，HEAD `cbbdf2bb97767fec1c465c7431921c2ea53dce25`。旧 1080p 长测失败、人工验收缺口及冻结报告保持原状；本轮不是正式优化验收。

## 已量出的成本

默认 Chrome / Intel UHD / ANGLE D3D11，1920×1080 输出、DPR 1。固定书房人物、相机、缩放和可见家具组，同实例恢复基线以观察漂移。下表是诊断副本条件下的实验收益，不能相加成占比。

| 对照 | 实测均值 | 相邻基线与解释 |
| --- | --- | --- |
| 原包普通页面 | 客厅 37.627、书房 37.842 ms | 各 600 rAF 预热、600 rAF 样本；普通页缺游戏帧计数和精确姿态，不用两页差值归因 |
| 材质整体改为无光照灰色 | 25.562 ms | 相邻基线 33.542 / 35.425，减少 7.98–9.86 ms；135 draw / 81,640 render primitives 不变 |
| 关闭实时太阳阴影 | 26.621 ms | 相邻基线 33.651 / 31.904，减少 5.28–7.03 ms |
| 关闭 2×MSAA 抗锯齿 | 29.518 ms | 相邻基线 35.092 / 33.651，减少 4.13–5.57 ms |
| 真正将画布降为 1280×720 | 25.517 ms，约 39.2 FPS | 相邻 1080p 为 35.049 / 36.623，减少 9.53–11.11 ms |

材质 override 同时改变纹理、光照、透明等状态，玻璃也变为不透明灰色；这不是纯光照实验，更不是可交付的画质方案。它证明仅凭面数不能解释成本，并未证明几何完全无关。环境 GLB 实际有 219 个网格、162,926 个资产三角面、21 个材质、10 张图像；资产面数与运行时多 pass 的 render primitives 分开。

真实 720p 保持相同姿态、可见组和 135 draw，但 render primitives 从 81,640 变为 61,690；可能涉及 LOD 选择变化，本轮没有单独证明。因此其收益属于真实低分辨率路径整体收益，不能全部归为像素数量减少。

## 脚本不是已测到的主要预算

普通 `_process` 约 2.85–2.91 ms，其中遮挡显隐约 2.71–2.77 ms；相机计时包含显隐，不能重复相加。测试路径 `_process` 约 4.54 ms。测试桥、停止显隐、停止 `_process` 的整帧收益受基线漂移影响，不能据此判定脚本零成本或负成本。

隐藏整个环境降至 19.527 ms，但同时将 draw 从 135 降至 16，并改变图元、阴影；这是整体渲染抑制实验，不是独立的几何复杂度实验。

## 内部缩放的额外退化已定位到具体路径

当前原版 `scale=1`，不承担以下额外开销。直接把引擎内部 `scaling_3d_scale` 调到 2/3，在这台 Intel / ANGLE 环境反而显著变慢：

| 同实例对照 | 均值 |
| --- | ---: |
| 内部 720p，正常执行拷贝 | 71.829 ms |
| 仅跳过跨尺寸深度/模板拷贝 | 30.809 ms |
| 恢复拷贝 | 71.336 ms |

每段 180 个游戏帧。三段均相同 1920 输出、相机/人物/可见组、AA/阴影和绘制统计。原始调用核验：跳过段仅消除了 180 次 `mask=0x500`（DEPTH|STENCIL）、1280×720→1920×1080、NEAREST 的 `blitFramebuffer`；同尺寸 COLOR|DEPTH 的 MSAA resolve 和最终 COLOR blit 均继续执行。该传输及其下游后果对应约 40.53–41.02 ms 的差值。

即使关闭 MSAA，内部缩放仍为 66.144 ms，相邻全分辨率无 AA 为 30.012 / 31.482 ms，不能归为 MSAA 独有交互。JS 直接调用墙钟很小，不能代表延后的 GPU/驱动执行与等待成本。

这只是隔离消除实验。跳过 wrapper 的匹配条件比这次目标宽，不能用于生产；本轮没有确认驱动缺陷，也没有验证删除拷贝的通用正确性。尺寸来自调用参数和缓冲分配跟踪，未完整读取所有 FBO 附件。

## 证据与限制

- 原包复现：[书房](baseline-study/report.json)、[客厅](baseline-spawn/report.json)。四个短窗均值都低于 40 ms，未重现旧长测 19/52 滚动窗口失败；不会覆盖旧结论。
- 核心单项：[7 段无探针对照](main-no-probe-v1/report.json)、[14 段细分](detail-no-probe-v1/report.json)。各段 120 游戏帧预热、240 游戏帧测量，未安装 GPU/GL/RAF probe 包装。
- 缩放定位：[最终路径实验](final-path-isolation/report.json)，各段 120 帧预热、180 帧测量；完整 blit 原始记录保留。
- 计时载体：[GPU smoke](smoke-v1/report.json)。异步 timer query 包含实际 draw、无 disjoint；完整区间过滤后 GPU elapsed 约 38.868 / 65.336 / 37.310 ms。它包含提交间隙，不能与回调墙钟或脚本耗时相加。未完成探针总开销的精确校准，核心因果结论使用无该探针的实验。
- 可见窗口：[失败原件](headful-confirm/report.json)。Intel / 1920 buffer、起始 DOM visible/focus 已记录，但 600 游戏帧预热在 120 秒内未完成，0 有效 block；原因未确认。不能将 headless 对照写成已通过的可见窗口性能复测。
- 普通页原生帧计数缺口、系统负载和供电条件未完全隔离、短采样和不同硬件泛化范围均保留。报告数值不是另一台电脑的帧率保证。
- `TIME_PROCESS` 是含 draw/sync 的周期性墙钟统计，不是纯 CPU；旧 snapshot 的 `triangles` 实为包含 visible/shadow/canvas 的 aggregate primitives，不作为资产面数。Godot 阴影分项 draw 为 0 与真实 GL 调用及总 draw 差异不一致，本轮不据其断言阴影没有绘制。

## 建议的下一步

先保留模型造型与细节，在同画面比较下调整阴影质量、抗锯齿和正确的低分辨率呈现路径。真实 720p 已显示收益，但不要直接采用本轮发现退化的内部缩放路线。材质灰模、隐藏环境、跳过深度拷贝都只用于定位，不进入当前试玩。任何正式画质改动仍需视觉、操作和长测回归。

## 来源与复现入口

各 run 的 `runner.cjs`（存在时）、原始报告内 runner/plan/PCK 哈希、根目录计划与 probe、[诊断源码](diagnostic-source/)、[来源指纹](source-manifest.json)、[保护与清理核验](validation.json)一起保留。原始报告不因本说明补写而改写。

源码核对依据：[Godot 缓冲配置](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/drivers/gles3/storage/render_scene_buffers_gles3.cpp)、[GLES3 渲染与缩放后处理](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/drivers/gles3/rasterizer_scene_gles3.cpp)、[post_copy](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/drivers/gles3/effects/post_effects.cpp)、[主循环计时](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/main/main.cpp)、[WebGL 异步计时规范](https://registry.khronos.org/webgl/extensions/EXT_disjoint_timer_query_webgl2/)。
