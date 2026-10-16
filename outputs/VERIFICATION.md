# 本次初始化验证

日期：2026-10-15。范围：agent 上下文、软件依赖、照片目录链接、基础客厅与本地网页观察预览。该范围已完成；整份生日礼物尚未完成。

| 验证项 | 实际结果 |
| --- | --- |
| 上下文 | 根目录 AGENTS.md、PROJECT.md、LIVING_ROOM.md 已记录技术选择、用户分工、多对话并行和照片估算要求。 |
| 原照片入口 | `references/house-photos` 经文件属性确认是 Junction，目标是用户指定 E 盘目录。指定 HEIC 与布局图原件未复制进项目，未修改原件。 |
| Blender | 4.5.14 LTS 官方 Windows portable 包；SHA256 匹配官方清单；实际执行版本命令、生成脚本和渲染成功。 |
| Godot | 4.7.2 stable 标准版，软件与模板的 SHA512 匹配官方清单；匹配 Web 模板实际导出成功。 |
| 基础模型 | 依据 4 张照片生成可编辑 `.blend`、GLB 和两张预览图；296 个网格、14 个分类。按照片核对沙发与电视对置、双椅、茶几、柜体、窗帘和开口关系。 |
| 引擎导入 | 实际运行输出 `ROOM_PREVIEW_READY meshes=296`，退出码 0。 |
| 视角结构检查 | `Verify-Scene.gd` 读取实际导入模型：9 个顶面分类网格在俯瞰隐藏、返回室内恢复；相机状态正常，输出 `SCENE_VERIFY_OK ceiling_meshes=9`。 |
| 浏览器 | 本机 Chrome 155.0.8059.40，1440×1000：加载实际 Web 导出，四个视角按键均触发，发送旋转/缩放输入，中文可读。控制台错误 0，失败请求 0。 |
| 视觉复核 | 查看入口和俯瞰的浏览器截图；确认俯瞰屋顶已隐藏、主要布局可见。Blender 渲染与浏览器实时灯光不同，分别留图。 |
| 独立审查 | luna-worker 只读核对源文件、模型结构、junction 和运行证据，最终增量无可行动缺陷。 |

## 证据入口
- [Blender 入口图](previews/living-room-entry.png)、[Blender 俯瞰图](previews/living-room-overview.png)。
- [浏览器入口截图](previews/browser-entry.png)、[浏览器俯瞰截图](previews/browser-overview.png)。
- [模型清单](blender/model-manifest.json)、[导入与视角检查脚本](Verify-Scene.gd)。
- 原始运行日志在项目根目录 `work/blender-build.log`、`work/godot-import.log`、`work/web-build.log`、`work/browser-verification.json`；安装来源与校验信息在 `work/*-setup.json`。

## 当前边界
- 场景是按照片估算的基础模型；家具细节、材质与光照未做精细还原，符合用户要求。
- 只完成客厅。阳台仅作为开口/窗框边界提示，其他区域未建模。
- 当前是可切视角的观察预览，人物、碰撞、互动和彩蛋待后续创意与实现。
- `127.0.0.1:8767` 是本机链接；未公开发布。服务重启方式见 README。
- 原件保护采用 agent 只读操作约定；未变更 E 盘 NTFS 权限。

## 已处理的导入检查点
Godot 把 glTF 自定义属性放在节点的 `extras` 元数据字典中。顶面显示切换使用 `extras.category`；直接读取顶层 `category` 会导致俯瞰仍被屋顶挡住。当前实现和 `Verify-Scene.gd` 已覆盖这一真实导入边界。

## 2026-10-16 目录迁移
- 正式目录为 `D:\vibe-code-life\3d-home`；迁移前后 6417 个实际文件逐个通过 SHA256 内容比对。
- `references/house-photos` 在新目录重建为指向原 E 盘目录的 junction；manifest 中的 48 张图片均可读取，照片未复制。
- 新位置的 Blender 版本检查、Godot 导入与物理验证、Web 导出和 Chrome 方向键/E 键测试通过；预览服务根目录已切换到 D 盘。
- 本地 Git 跟踪模型、代码、文档和预览图；软件缓存、照片链接、网页导出和 Python 缓存已忽略。迁移证据保存在 `work/migration-*`。
