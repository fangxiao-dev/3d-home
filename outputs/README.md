# 生日礼物 · 3D 小屋

当前可玩候选采用 [相对鼠标游览与分层 Esc](design/mouse-look.md)，并按 [固定场景转场](design/fixed-scene-transition.md)短淡化切入各坐位预设机位：点击开始后，左右移动鼠标观察，停手即停；坐姿中显示光标，Esc 起身后直接返回游览，外层再次 Esc 才暂停。纯色材质与自然光影保留。当前资源版本和实际验证范围统一见 [HOUSE.md](HOUSE.md)，操作见 [PLAYROOM.md](PLAYROOM.md)。

场景包含 [成品场景 V2](design/scene-v2.md) 的 7 个可见区域、正式通用卡通角色与 5 个坐位。[66 秒边缘控制历史演示](verification/navigation-v2/fixed-1366-demo/page@b3d57a64397207f99d3cb2d386c76757.webm)属于导航包 1a42（旧材质）；[94 秒演示](verification/scene-v2/demo.mp4)属于更早控制版本。

## 直接查看

- 本机网页预览：<http://127.0.0.1:8767/>，仅本机可用，资源随构建更新。
- [操作与动作验收](PLAYROOM.md) · [制作方案与美术目标板](design/scene-v2.md)
- [房屋 Blender 源模型](blender/living-room.blend) · [角色 Blender 源模型](blender/character.blend) · [Godot 工程](godot/project.godot)

## 打开试玩流程

用户只要求打开项目或检查画面时，从已有网页启动。用户明确要求 Blender/Godot 编辑工程时，打开上方对应源文件或工程。

1. 工作目录为项目根目录 `D:\vibe-code-life\3d-home`。确认 `outputs/web/index.html` 存在；缺失时按下方“软件与重建”生成网页。
2. 检查默认地址 `http://127.0.0.1:8767/`。已有服务且页面的 `GODOT_CONFIG.mainPack` 与本地 `outputs/web/index.html` 一致时，复用该服务；无服务时执行 `./outputs/Start-Preview.ps1`。
3. 若 8767 被其他服务占用，执行 `./outputs/Start-Preview.ps1 -Port 8768`，使用新地址并告知用户实际端口。启动进程信息与日志在 `work/preview-server.json`、`work/preview-server*.log`。
4. 在 Chrome 打开普通试玩地址。已有对应标签时复用；点击“开始游览”进入鼠标观察和方向键行走，普通游览时按 Esc 恢复光标。浏览器工具报错时先查标签列表，定位已创建页面后继续，避免重复创建空白页。
5. 确认实际画面出现房屋与人物，保留试玩标签，告知用户地址和操作方式。加载失败时检查服务日志及浏览器错误，按 [排查入口](TROUBLESHOOTING.md) 处理，不能以端口监听或 HTML 返回成功代替画面确认。

正常打开沿用现有模型、烘焙和网页资源。当前性能接受水平为 25–30 FPS（2026-10-25 用户确认）。打开流程的验收是网页实际可查看；历史全屋测试与性能数据见 [HOUSE.md](HOUSE.md)。

## 资料与当前规则

- [PROJECT.md](PROJECT.md)：目标、当前阶段、空间范围和待定内容。
- [设计入口](design/README.md)：当前场景制作与后续 V1 彩蛋；原稿推荐项不自动成为需求。
- [参考资料入口](../references/README.md)：照片、人物背景、情书和聊天资料。
- [PHOTO_MANIFEST.md](PHOTO_MANIFEST.md)：照片名称、描述与物品；原图位于只读 junction。
- [LIVING_ROOM.md](LIVING_ROOM.md)：照片观察和原型尺寸历史。
- [IMPLEMENTATION_NOTES.md](IMPLEMENTATION_NOTES.md)：实施入口与经验；[TROUBLESHOOTING.md](TROUBLESHOOTING.md)：已有排障记录。

## 软件与重建

本项目使用 Blender 4.5.14 LTS、Godot 4.7.2 stable 标准版、GDScript、Compatibility 网页渲染。实际可执行路径分别读取 `work/blender-setup.json` 和 `work/godot-setup.json`；软件、缓存和日志位于根目录 `work/`。

在项目根目录执行：

```powershell
# 从环境与角色源文件重建、导入、烘焙、验证并导出网页
./outputs/Build.ps1 -RebuildAll

# 环境改动：重建环境并重新烘焙
./outputs/Build.ps1 -RebuildModel

# 角色改动：重建独立骨骼角色
./outputs/Build.ps1 -RebuildCharacter

# 灯光改动：重新烘焙
./outputs/Build.ps1 -BakeLighting

# 仅运行逻辑改动：使用与当前环境匹配的烘焙数据
./outputs/Build.ps1

# 本地预览（已有服务时复用）
./outputs/Start-Preview.ps1
```

共享整屋构建、Godot 导入与烘焙串行执行。预览服务默认只监听本机 8767，端口占用时可使用 `-Port 8768`。生成网页使用内容指纹资源包，变更后刷新页面即可；查询参数不代替资源指纹。

## 资产来源与运行接口

- 环境：`blender/build_living_room.py` 及房间模块生成 `.blend`、环境 GLB、房间边界、家具与坐位数据。
- 角色：`blender/build_character.py` 独立生成 `.blend`、蒙皮 GLB 和动画合同，环境构建不会覆盖它。
- 公共尺度：`blender/scene-v2-spec.json`。Blender 坐标 `(x,y,z)` 转为 Godot `(x,z,-y)`。
- 运行入口：`godot/playroom.tscn`；操作与状态逻辑：`godot/playroom.gd`；环境光照：`godot/scene_environment.gd`。
- 静态光照在本机离线烘焙，网页读取烘焙数据。构建检查模型与光照源哈希，拒绝使用已失配的烘焙资源。
- 调试页 `?test` 提供只读运行状态；正常试玩页保持简洁。

构建检查覆盖资产一致性、五坐位、整屋通行和镜头输入回归。当前浏览器载体位于 [fixed-scene-transition](verification/fixed-scene-transition-20261025/)，覆盖固定机位淡化、真实捕获、相对鼠标观察、分层 Esc、失焦、拒绝捕获、跨房间和坐起。上一轮 [mouse-look](verification/mouse-look-20261025/) 保留该版性能观察；旧 [navigation-v2](verification/navigation-v2/) 属于边缘控制历史证据。实际 Chrome 画面与连续动作另行验收，只有对应资源的证据才代表该版本。

## 第三方与隐私

房屋与通用角色由本项目制作；字体 Noto Sans SC 许可见 [OFL](godot/assets/NotoSansSC-OFL.txt)。网页交付保留 Godot 与字体许可。

房屋照片、故事与原始情书通过 `references` 的只读外部链接访问，留在 E 盘；当前环境制作不把它们打包进网页。公开发布另行由用户明确指示。
