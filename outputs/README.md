# 生日礼物 · 3D 小屋

这一版初始化项目，并根据四张客厅照片和全局布局图制作基础客厅。尺寸按照片估算，以辨识度为准。

## 直接查看
- 本机网页预览：<http://127.0.0.1:8767/?v=warm-bright>（本地预览服务运行时可用）。
- 当前入口直接在原 Blender 客厅中游玩：方向键走动，镜头自动跟随，走到窗边落地灯旁按 E 开关。[最小验收步骤](PLAYROOM.md)。
- [入口预览图](previews/living-room-entry.png) · [布局预览图](previews/living-room-overview.png)。
- [Blender 可编辑模型](blender/living-room.blend) · [Godot 工程入口](godot/project.godot)。

现已在原客厅模型中加入临时人物、家具碰撞、室内透视跟随镜头和落地灯开关。天花板与吊灯可见，环境不投影，人物保留脚下阴影。独立观察场景保留为 `godot/main.tscn`。网页文件位于 `web/`，当前链接仅本机可用。

## 项目上下文
- 项目根目录 [AGENTS.md](../AGENTS.md)：给后续 agent 的入口与协作约定。
- [PROJECT.md](PROJECT.md)：已确认目标、协作方式、当前状态与待明确事项，供多个对话共同接续。
- [PHOTO_MANIFEST.md](PHOTO_MANIFEST.md) / [photo-manifest.json](photo-manifest.json)：每张图片的名称、描述、物品。
- [LIVING_ROOM.md](LIVING_ROOM.md)：照片解读、估算与建模边界。
- [VERIFICATION.md](VERIFICATION.md)：实际验证结果与当前限制。

创意和实现可以并行。用户提供故事与审美反馈，agent 维护源模型、代码与可查看结果。用户明确不追求精细，不需要测量尺寸。

## 照片链接
项目根目录 `references/house-photos` 是目录 junction，直接指向：

`E:\MediaSpace\27年生日礼物-3d小屋\房屋图片`

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

模型生成源文件：`blender/build_living_room.py`。Blender 坐标为 Z 向上、Y 指向阳台；GLB 导入 Godot 后为 Y 向上、-Z 指向阳台。家具通过命名与 category 元数据保留可识别性。网页模型不包含家庭原始照片。

当前操作版逻辑在 `godot/playroom.gd`；原客厅观察逻辑在 `godot/main.gd`。Godot 使用实时灯光与人物脚下的柔边阴影，不计算家具或环境投影。用户已选择清爽简化的网页效果，Blender 离线渲染图与网页截图分别保留。

## 第三方内容
模型由本项目脚本按照片观察生成，未引入第三方家具包。中文界面使用 Google Fonts 的 Noto Sans SC 字符子集；许可见 `godot/assets/NotoSansSC-OFL.txt`。新增中文文案时需补字体字符或改用完整字体。

Blender 与 Godot 下载和许可说明：
- <https://download.blender.org/release/Blender4.5/>
- <https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable>
- <https://godotengine.org/license/>

最终分享网页时，应保留 Godot 和字体的许可说明。
