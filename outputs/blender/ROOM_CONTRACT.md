# 全屋粗版独立实现合同（历史）

本文仅记录粗版阶段的分工与接口。当前制作采用 [成品场景 V2](../design/scene-v2.md) 的统一尺度、资产与坐位合同。

共用坐标：Blender Z 向上，客厅阳台方向 +Y；Godot 映射为 (x,z,-y)。层高 3.3。各范围和 API 以 `room_api.py` 为准，原客厅家具比例保持。

每个新增区域只写 `rooms/<room_id>.py`，入口 `def build(api)`。使用 `api.box/cylinder/ellipsoid/rod`、`api.shell` 和共用材质；所有位置为世界坐标。不得编辑别人的区域、共享 API、原客厅或 Godot 集成。场景以照片为参考，偏卡通，留通道，不复制杂物。无新增 F 互动。

| 场景 | 负责的壳体与开口 | 必须保留的识别元素 |
| --- | --- | --- |
| dining | west/east 实墙；north 不建墙（走道统一拥有）；south 开口 X=-1.7..0.9，入口横向细框与透明玻璃边界由厨房负责 | 餐桌椅、餐边柜、冰箱；通向厨房视线清楚 |
| study | west/east/south 实墙；north 不建墙（走道统一拥有门洞 X=6.1..7.6） | 书桌、书柜、椅子、古筝与琴架，主要动线宽至少 1 m |
| wash | west/east/south 实墙；north 不建墙（走道拥有 X=2.35..4.2 开口） | 台盆、浴室柜、镜子，south 墙关闭厕所门，入口可走近台盆 |
| balcony | west/east/north；south 全开与客厅相连；north 墙用窗结构代替实墙但保留阻挡 | 洗衣柜、洗衣机、洗衣池、窗、晾衣架；客厅开口保留宽通道 |
| hallway | west/east 实墙；north X=-2.9..2.9 与 south X=-2.9..2.0 全高开放；south X=2.35..4.2、6.1..7.6 为普通门洞 | north 墙 X=5.6、10.2 闭门，south X=10.8 闭门；不建这些门后内部；通道至少 1.4 m |
| kitchen | west/east/south；north 不建墙（餐厅拥有）；入口 Y=-6.6、X=-1.7..0.9 透明玻璃隔断须 solid=true | 上下橱柜、灶台、水槽、转角台面；从餐厅可看清，人物不能进入 |

`shell(sides)` 自动生成地面、所列侧墙、顶面，`sides` 为 side -> opening intervals 的 dict。开口格式为 `(start,end[,height])`，普通门洞默认高 2.45，客厅与餐厅的无隔断连接显式高 3.3。省略的边由相邻区域拥有。窗面需要自己建墙下段、框、浅色玻璃和碰撞，使用 side 参与近侧遮挡。

书房内嵌书柜、餐厅内嵌餐边柜全组附属东墙，统一 `side='east'`，避免背面挡住人物；碰撞保留，独立桌椅照常可见。厨房透明入口及门框固定可见，表达不可进入的边界。跨房间门洞的共享墙按相机到人物的跨平面关系隐藏，不改变物理边界。

实体默认碰撞；小摆件、窗框、吊柜、镜面、灯、细椅腿可显式 `solid=False`，用对应主体或底座承担简单阻挡。墙附件须与所附墙相同 side；顶面/吊灯 `side='top'`。普通家具 side 空字符串。厨房可用 api.env['material'] 创建 alpha 低的玻璃材质，写入 api.m；实体碰撞不依赖玻璃可见性。

验证：每个 worker 读实际照片，Python 语法与只记录调用的 fake API 验证（至少验证主体名字、finite bounds、无出界家具、入口走道留白）。模块返回后主控串行生成整屋 Blender/GLB，统一 reviewer 审查，网页问题交回对应 worker；worker 不同时运行共享 Build 或写整屋资源。各模块 source hash 作为固定审查版本。

客厅 worker 仅修改原生成脚本：保持已有家具，移除假远窗阻挡以接通阳台，保持原厅口开放；把原对象标记 `room_id=living`，再调用六个模块；输出原 .blend/GLB 路径保持兼容。新区域由 metadata collision/cutaway 控制 Godot，主控负责整屋运行时连接。
