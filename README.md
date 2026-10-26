# 生日礼物 · 3D 小屋

用 Blender 制作家中的场景，在 Godot 网页里控制人物、探索和互动。

## 打开试玩

新会话在本项目中说“打开项目给我试玩”即可，agent 按 [固定打开流程](outputs/README.md#打开试玩流程) 启动本机服务并在 Chrome 打开已有网页。

手动启动：在项目根目录执行 `./outputs/Start-Preview.ps1`，随后打开 <http://127.0.0.1:8767/>。服务已运行时直接打开地址。

- [操作说明](outputs/PLAYROOM.md)：点击开始游览，WASD/方向键移动，鼠标左右移动观察、停手即停，滚轮缩放；F 淡化切入固定机位后坐下，互动内 Esc 直接起身返回，外层新的 Esc 才暂停。
- [66 秒边缘控制历史演示（旧材质）](outputs/verification/navigation-v2/fixed-1366-demo/page@b3d57a64397207f99d3cb2d386c76757.webm) · [当前验证结果与边界](outputs/HOUSE.md)

## 项目资料

- [项目目标与当前状态](outputs/PROJECT.md)
- [成品场景 V2：制作目标、合同与进度](outputs/design/scene-v2.md)
- [当前固定场景转场与 Esc 分层](outputs/design/fixed-scene-transition.md) · [相对鼠标游览](outputs/design/mouse-look.md) · [边缘控制历史方案](outputs/design/navigation-v2.md)
- [全屋场景与验收](outputs/HOUSE.md)
- [交互机制 V1 与彩蛋设计](outputs/design/README.md)
- [参考资料入口：照片、背景、情书与聊天资料](references/README.md)
- [本地预览、软件与重建说明](outputs/README.md)
- [移动、镜头与 F 键互动验收](outputs/PLAYROOM.md)
- [后续实现与经验复用](outputs/IMPLEMENTATION_NOTES.md) · [常见问题排查](outputs/TROUBLESHOOTING.md) · [本阶段复盘](outputs/RETROSPECTIVE.md)

`references/house-photos` 是指向外部房屋图片目录的 junction，照片保留在原位置。软件和缓存位于 `work/`；它们与照片链接、网页构建产物均不进入 Git。
