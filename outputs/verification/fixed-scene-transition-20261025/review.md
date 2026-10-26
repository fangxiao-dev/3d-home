# 固定场景转场与分层 Esc：独立审查及主控验收

2026-10-25。本轮控制实现与已测功能完成；可见窗口人工手感及全项目验收仍有边界，无需追加技术决定即可试玩。

当前 PCK `4315d056df8368c0b0307e94e5f7e51f58da362711ae69e205573654ebba9287`，runtime `2f5d1c1da226f28c001be81fb5a3a51fbf11aea4650da085d0852f49cd3044a9`。实际资源原件在 [package](package/scene-4315d056df83.pck)。固定代码比较为本轮 `work/fixed-scene-transition-20261025/baseline/` 的 cdd5 运行版到 `candidate-1/` 快照，不是包含更早未提交改动的 Git HEAD diff。

## 独立审查

执行者 `/root/navigation_builder`、独立只读审查者 `/root/navigation_review`、验收主控 `/root`。

- 固定代码增量通过。遮罩 alpha1 后切机位并同步遮挡，跨下一帧再淡入，alpha0 后才 SitDown；坐位镜头不取游览 yaw/zoom。正常与退出遇阻回坐共用路径、取消/失焦/捕获失败、保存视角返回均已检查。
- Esc 按下至松开只消费一次，echo 和同按下过程的重复事件不跨返场再触发外层暂停；失焦清理闩锁，避免丢 key-up 后失效。四项构建、30 组机位回归、三阶段中断与两项捕获失败模拟通过；模拟不混算为网页权限用例。
- 1366 覆盖可按原报告有效前段 6 次＋同包从出生走至书房补测 1 次组合；1920 为完整 7 次，共 14 核心用例。原 1366 false 报告保留。书房向右位移约 94.5 mm 未到 120 mm，截图与桌边约束相符，但无逐次 collider 记录，不作排它碰撞根因结论。补测向左约 275 mm，仍用 180 ms / 120 mm 门槛，未修改产品碰撞。
- 独立核对连续画面：1366 0043 旧构图→0044 实际全 RGB0→0045 新构图，1920 0020→0021 全黑→0022 新构图；查看五座截图及揭示后的动作，未发现新视觉阻断。frame_pre_draw 只是提交前状态，实际 JPEG 黑帧另提供像素证据。
- 唯一测试载体 finding T1（审查临时记录曾标 T2，属于同一项）：早期 activation=false 后又用 Playwright evaluate 读取 exitT，污染最终用户激活前提。原 runner/报告保留，不将该早先 false 当最终权限证明。两分辨率独立 permission-smoke 改为最终读取全用 CDP userGesture:false，6.5 秒后 false 紧接真实 Esc，补证通过。1920 还记录 SEATED 首按、STAND_UP 重复、EXPLORE 重复均 trusted，返场重复不暂停，松开后新 Esc 才暂停。
- 两分辨率真实切标签检查通过：切换前及隐藏时最后绘制帧分别仍在 fade_out / fade_in，DOM 确实 hidden=true、focus=false、locked=false；两类读值非原子操作，不称失焦事件瞬间的精确 alpha。返回后遮罩清零、互动返场资格已取消，起身后手动点击恢复。短 black 相位只由引擎模拟覆盖。
- 两尺寸 sandbox 各两次真实点击拒绝，明确 console/权限错误共四条、未知错误为零；恢复是导航新正常文档后真实点击，不称原受限文档原地恢复，也不冒充坐姿退出捕获失败的真实浏览器证据。

## 主控独立检查

[实际 runner](owner-check/runner.cjs) · [原始报告](owner-check/report.json) · [坐姿](owner-check/seated.png) · [返场直接游览](owner-check/returned-active.png) · [外层暂停](owner-check/outer-paused.png)。

主控使用独立、已知本机 URL 的安装版无头 Chrome，以真实点击、F/Esc、鼠标和方向键操作；读取均为 CDP userGesture:false，没有伪造游戏状态或锁定。检查通过：完全遮黑切镜、揭示后 SitDown、坐姿光标可见、6.5 秒后失去瞬时激活仍由真实 Esc 起身恢复、同一次 Esc 返场重复不暂停、松开后鼠标 100px 转 12°、实际行走、新 Esc 暂停与真实点击继续。意外错误为零，实际网络 PCK 与首尾完整收据一致。主控查看三张实际页面截图及四张转场关键帧。

原生 Windows 前台检查被 Computer Use 的网址可信度检查停止，没有新成功操作/截图；随后停止所有原生输入。详情见 [owner-native](owner-native/README.md)。独立无头网页检查不替代可见人工手感验收，该缺口保留。

## 时序、证据与边界

执行者 16 份转场轨迹观测跨度 346–410 ms、最大提交间隔 58 ms，见 [transition-metrics](transition-metrics.json)。主控独立稀疏轨迹观测淡出首次提交 t30267 至首次 SitDown t31176，共 909 ms，最大间隔 299 ms；不确定具体原因，不用它证明精确 350 ms 或性能通过。名义淡出/淡入 Tween 为 150/200 ms，不能把名义时长等同所有环境实际耗时。此前 1080p 长测失败保持原样，本轮未运行替代长测。

[冻结 summary](summary.json) SHA-256 `bc3b87aed91944709a96e1fde788db6fdca04b4cd275d3df1c8bfe3d226bb41a`；[505 项执行者清单](source-manifest.json) SHA-256 `9909082ff9b4546d2c9fcb009d40c52f2af64e3280a1846998cc86ae46f4684e`。主控逐项核对无缺失或变化；1115 个受保护资产、字体、源文件及旧证据未变。主控文档及 owner-* / review.md 单独归档，不修改执行者原件。

试玩服务保留 `http://127.0.0.1:8767/`。所有自有测试浏览器与临时服务关闭，未提交、推送或部署。

最终增量终审 PASSED：独立审查者逐项核对 505 项清单、1115 个保护项、9 个主控文件指纹与 16 份时序派生，均无差异；核对根 README 的相对鼠标与分层 Esc 修正、当前项目说明及所有已列边界，无剩余阻断。本轮控制范围可交付；可见人工手感、旧性能失败与全项目未闭环状态保持原样。
