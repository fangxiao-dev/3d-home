# 生日礼物 · 3D 小屋

根据客厅照片和全局布局图提取重要家具与空间关系，制作宽敞、清爽、偏漫画/卡通风格的客厅。模型比例服务于画面效果。

## 直接查看
- 本机网页预览：<http://127.0.0.1:8767/?v=wide-room>（本地预览服务运行时可用）。
- 方向键随视角移动，Q/E 旋转、滚轮缩放；跟随小标记，靠近入口软墩按 F 查看，靠近长沙发两个坐位按 F 坐下，固定镜头中按 Esc 返回。[操作与验收步骤](PLAYROOM.md)。
- [入口预览图](previews/living-room-entry.png) · [布局预览图](previews/living-room-overview.png)。
- [Blender 可编辑模型](blender/living-room.blend) · [Godot 工程入口](godot/project.godot)。

原客厅模型中加入临时人物、家具碰撞、约 29° 俯角的可旋转缩放镜头、软墩固定特写和两个沙发坐位。挡住镜头的近侧墙窗、顶面和吊灯按机位处理，碰撞保留；固定镜头中锁定探索操作，退出恢复视角和人物状态。环境不投影，走动时人物保留脚下阴影。独立观察场景保留为 `godot/main.tscn`。网页文件位于 `web/`，当前链接仅本机可用。

客厅内宽由 4.3 m 扩到 5.8 m，纵深 5.8 m、层高 3.3 m。家具保持体量，两侧家具组各向外平移 0.75 m，中央留白增加。入口为无靠背软墩，沙发前木椅已移除，保持明亮暖光。

## 项目上下文
- 项目根目录 [AGENTS.md](../AGENTS.md)：给后续 agent 的入口与协作约定。
- [PROJECT.md](PROJECT.md)：已确认目标、协作方式、当前状态与待明确事项，供多个对话共同接续。
- [背景入口](background/README.md)：每个新对话必读的人物与关系摘要；按主题进入 5 份背景复盘和 E 盘原始情书快照。
- [PHOTO_MANIFEST.md](PHOTO_MANIFEST.md) / [photo-manifest.json](photo-manifest.json)：每张图片的名称、描述、物品。
- [LIVING_ROOM.md](LIVING_ROOM.md)：照片解读、估算与建模边界。
- [VERIFICATION.md](VERIFICATION.md)：初始化与迁移的历史验证记录；当前玩法与最新验收见 [PLAYROOM.md](PLAYROOM.md)。
- [IMPLEMENTATION_NOTES.md](IMPLEMENTATION_NOTES.md)：后续建模、互动与验证的复用入口；遇到异常查 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)。

创意和实现可以并行。用户提供故事与审美反馈，agent 维护源模型、代码与可查看结果。用户明确不追求精细，不需要测量尺寸。

## 照片链接
项目根目录 `references/house-photos` 是指向外部房屋图片目录的 junction。

日常素材统一为“场景_视角.jpg”命名的 48 张 JPG；45 张原始 HEIC 保存在素材目录的 `_原始HEIC` 子文件夹。照片仍通过目录链接访问，不复制进项目或打包进网页。

## 软件已就绪
- Blender **4.5.14 LTS**：项目内 portable 安装，官方 SHA256 校验通过。
- Godot **4.7.2 stable** 标准版：项目内 portable 安装，官方 SHA512 校验通过，匹配的 Web 模板已安装。
- 软件和下载缓存位于根目录 `work/tools/` 与 `work/downloads/`，没有修改全局 PATH。
- 实际可执行路径、下载来源和校验值分别记录在根目录 `work/blender-setup.json`、`work/godot-setup.json`。
- Godot 使用自包含 `editor_data`，只安装本项目需要的 Web 模板。后续若需要桌面安装包，再补对应模板。

## agent 重建与运行
在项目根目录使用 PowerShell：

```powershell
# 导入模型并重新生成网页
./outputs/Build.ps1

# 修改建模脚本后：重新生成模型、两张渲染图，再生成网页
./outputs/Build.ps1 -RebuildModel

# 本地预览服务关闭后重新启动；仅监听本机
./outputs/Start-Preview.ps1
```

如 8767 端口已有当前预览，直接访问链接；如被其他程序占用，可用 `-Port 8768` 指定空闲端口。预览服务的进程号记录在根目录 `work/preview-server.json`。

构建时，`Verify-Scene.gd` 检查独立观察场景 `main.tscn`，`Verify-Playroom.gd` 检查当前游玩场景 `playroom.tscn`；两者通过后才导出 Web。网页视觉与实际按键操作仍需在用户使用的浏览器验收。

模型生成源文件：`blender/build_living_room.py`。Blender 坐标为 Z 向上、Y 指向阳台；GLB 导入 Godot 后为 Y 向上、-Z 指向阳台。家具通过命名与 category 元数据保留可识别性。网页模型不包含家庭原始照片。

当前操作版逻辑在 `godot/playroom.gd`；原客厅观察逻辑在 `godot/main.gd`。Godot 使用实时灯光与人物脚下的柔边阴影，不计算家具或环境投影。用户已选择清爽简化的网页效果，Blender 离线渲染图与网页截图分别保留。

`Build.ps1` 会按游戏资源内容生成 `scene-<hash>.pck`，并自动更新网页引用，避免浏览器复用旧场景。完成构建后刷新试玩页；只改变页面地址的 `?v=` 不能更新固定地址的游戏资源缓存。

## 第三方内容
模型由本项目脚本按照片观察生成，未引入第三方家具包。中文界面使用 Google Fonts 的 Noto Sans SC 字符子集；许可见 `godot/assets/NotoSansSC-OFL.txt`。新增中文文案时需补字体字符或改用完整字体。

Blender 与 Godot 下载和许可说明：
- <https://download.blender.org/release/Blender4.5/>
- <https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable>
- <https://godotengine.org/license/>

最终分享网页时，应保留 Godot 和字体的许可说明。
