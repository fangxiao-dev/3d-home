# 启动与构建

以下命令都从项目根目录执行。运行与重建方式变化时更新本页；玩法见[操作说明](controls.md)。

## 打开试玩流程

1. 确认 `outputs/web/index.html` 存在。缺失时按下方构建说明导出网页。
2. 检查 <http://127.0.0.1:8767/>：现有服务返回当前导出页时复用，否则从 `work/preview-server.json` 核对本项目服务后重启。端口被其他项目占用时使用 `-Port 8768`，告知实际地址。
3. 无服务时执行 `./scripts/Start-Preview.ps1`，在 Chrome 打开普通试玩页；优先复用已有标签。
4. 实际确认房屋和人物出现，保留标签并告知地址。点击“开始游览”进入控制；Esc 释放光标。端口监听或 HTML 返回不等于画面验证通过。

仅打开项目沿用已有模型、光照与网页，不运行整屋测试。失败时查[问题排查](troubleshooting.md)。

## 软件与本机配置

当前使用 Blender 4.5.14 LTS、Godot 4.7.2 stable 标准版、GDScript、Compatibility 网页渲染。本机依赖路径见 `work/blender-setup.json` 和 `work/godot-setup.json`；这些本地配置不进入 Git。预览需要 PATH 中可用的 Python。

Godot 编辑工程为 `godot/project.godot`；房屋和人物源文件分别为 `blender/living-room.blend`、`blender/character.blend`。

## 构建命令

```powershell
# 运行逻辑变更：导入、现役构建检查并导出
./scripts/Build.ps1

# 只导出；例如目录迁移后的启动检查
./scripts/Build.ps1 -SkipChecks

# 环境变更：重建环境并重新烘焙
./scripts/Build.ps1 -RebuildModel

# 角色变更：独立重建角色
./scripts/Build.ps1 -RebuildCharacter

# Stage 1 书本／王冠道具变更：独立重建道具
./scripts/Build.ps1 -RebuildProps

# Stage 2 蛋糕／蜡烛变更：独立重建
./scripts/Build.ps1 -RebuildCake

# 灯光变更：重新烘焙
./scripts/Build.ps1 -BakeLighting

# 全量重建
./scripts/Build.ps1 -RebuildAll

# 本地预览
./scripts/Start-Preview.ps1
```

共享的 Godot 导入、构建与烘焙串行执行。构建保留现有模型与烘焙匹配检查，不能拿旧烘焙配新环境；网页资源包版本用于浏览器缓存更新。日常操作无需额外 SHA 或完整归档流程。

## 更新文集内容与字体

`scripts/Prepare-Letters.ps1` 从只读情书快照生成 `godot/content/letters/`；`tests/Verify-LettersContent.ps1` 核对 15 篇正文与 7 图。更新内容后依次执行：

```powershell
./scripts/Prepare-Letters.ps1
./tests/Verify-LettersContent.ps1
python scripts/Prepare-ReadingFont.py
./scripts/Build.ps1
```

字体准备脚本从本机 Blender 随附的 OFL Noto 字体提取正文及界面字形，需要 Python 的 fontTools 与 Brotli（本机依赖位于 `work/python-deps/`）。源文集仍为只读，生成的正文与图片会进入网页资源包，公开上传需单独授权。

`-RebuildAll` 包含 Stage 1 道具与 Stage 2 蛋糕重建。环境内原有占位本已移除，冰箱已有内腔与门铰链；环境变化仍按 `-RebuildModel` 重建并重新烘焙。

## 文件边界

`outputs/web/` 是可部署网页，不代表已上线；`outputs/previews/` 是生成画面。源文件和必要运行资源在 `blender/`、`godot/`，不能将整个工程当作可删除产物。网页发布范围仅为 `outputs/web/`，参考资料不打包。

运行检查按[测试入口](../../tests/README.md)和根协作规则选择最小范围。初次克隆仍需要准备上述本机工具配置，不能只凭仓库文件宣称新机器开箱运行。
