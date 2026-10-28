# 技术架构与资源流程

本页描述当前实现结构；技术边界、资源归属或构建方式改变时同步更新。玩法要求见[设计](design/README.md)，实际成果见[状态](status.md)。

## 运行与构建

```text
blender/ 源模型、规格、生成脚本
       ↓ 导出模型、角色动画和布局数据
 godot/assets/ + godot/baked/ 静态光照
       ↓ Godot Compatibility / GDScript / Web 导出
 outputs/web/ → 本地 HTTP 服务 → 电脑浏览器
```

网页运行在玩家电脑的浏览器中；当前项目没有应用后端或云端渲染服务。本机工具路径读取被忽略的 `work/*-setup.json`，不是跨机器安装配置。

## 模块与权威来源

| 目录／模块 | 职责与维护位置 |
| --- | --- |
| `blender/` | 环境、人物、房间模块与公共规格；生成房屋及角色 `.blend`、GLB 与布局数据。环境和角色独立构建。 |
| `godot/playroom.gd` | 人物移动、鼠标捕获、互动状态、固定机位与镜头遮挡。运行场景为 `playroom.tscn`。 |
| `godot/album_ui.gd` / `album_timeline.gd` | 数据驱动双页画册与双尺度时间轴；共用内容为 `godot/content/album/album.json`，运行入口管理 F、输入隔离与返回。 |
| `godot/letters_ui.gd` | 多篇文集目录、分页、图片、阅读位置，以及会话内王冠领取／穿戴与人物界面；由运行入口接入输入、阅读镜头与头部王冠。 |
| `godot/birthday.gd` | 蛋糕准备状态、缺条件判断、8 秒生日演出与暂停／结束／重播界面；运行入口统一接入 F 目标、镜头和输入，王冠读取既有状态。 |
| `godot/content/letters/` | 从只读情书快照准备的 15 篇正文和 7 图，供运行时阅读。源文与生成内容完整性由独立脚本核对。 |
| `blender/build_stage1.py` | 独立书本与王冠的可编辑资产来源，输出 `stage1-props.blend` 与 Godot 道具资源；不重做人物骨骼。 |
| `blender/build_stage2.py` | 蛋糕与蜡烛的权威生成源，输出 `stage2-cake.blend` 与独立道具资源；环境侧维护冰箱内腔与原有门铰链。 |
| `godot/scene_environment.gd` | 生成引擎环境、灯光与碰撞；烘焙资源保存在工程内，属于网页运行必需资源。 |
| `scripts/` | 构建、准备及执行烘焙、本地预览；输出网页到 `outputs/web/`。 |
| `tests/` | 现役引擎验证；测试启动时将 `godot/` 设为项目路径。 |
| `references/` | 理解空间与故事的参考资料；原始照片和情书通过外部 junction 只读访问，不随网页导出。 |

Stage 1 确认收录的正文与图片通过内容准备脚本进入 `godot/content/letters/` 并随网页导出；原始 junction 不进入资源包。生成包包含私人内容，仅用于已授权的本地试玩。

家具、坐位与房间使用稳定标识。源侧产生尺寸及互动定位，运行时读取资产数据；Blender 坐标 `(x,y,z)` 转为 Godot `(x,z,-y)`。具体合同按任务从[设计入口](design/README.md)读取。

## 改动入口

运行逻辑改动只需重新导入和导出；环境改动涉及模型导出与重新烘焙；人物独立重建。执行命令见[开发指南](guides/development.md)，经验与故障定位从[指南入口](guides/README.md)进入。

`outputs/` 和 `work/` 不承载源码或当前设计。历史报告是对应版本的证据快照，不能作为当前模块或测试入口。
