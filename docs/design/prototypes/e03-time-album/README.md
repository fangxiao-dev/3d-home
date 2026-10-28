# E03 时间画册 · 交互原型

[Stage 3 时间画册设计](../../stage-3-e03-time-album.md) 的 HTML 参考原型。开发顺序为先在 HTML 对齐视觉与交互，再移植到 Godot；Godot 实现以此为视觉与交互参考，内容与规则以设计稿为准。

| 文件 | 说明 |
| --- | --- |
| `v1.3.html` | 当前数据化原型：读取游戏共用 album.json；13 个记忆单元，语义块模板 |
| `v1.2.html` | 用户提供的视觉参考：真实季度星群，2026 年星群退场；保留原件 |
| `E03-点赞互动-时间聚合.json` | 重连前 778 条记录的年度与季度聚合 |
| `v1.1.html` | 历史版本：双轨时间轴、2026 放大、通话针脚、成对脚印、真实亮星、三种留白相框、私人语言示例 |
| `assets/` | 仅放示意 SVG 插画 |

- 真实照片不存本目录：圣诞树三张引用 `godot/content/letters/images/`；画册新照片放 `godot/content/album/images/`，原型、Godot 与 Blender 共用。
- 原型用相对路径引用仓库内照片，需在仓库根目录起本地静态服务后访问 `docs/design/prototypes/e03-time-album/v1.3.html`。
- v1.2 星群来自真实时间聚合；示意插画、部分记忆年份仍为演示，不代表已核实的日期或最终素材。
- 新迭代另存为 `v1.4.html` 等，旧版本保留便于对比。

当前内容直接编辑 `godot/content/album/album.json`，v1.3 与 Godot 都读取该文件；样式分别由两端模板维护。`scripts/Prepare-Album.py` 是从历史原型重新提取初始内容的工具，会覆盖 JSON 与 v1.3，不作为日常内容编辑命令。
