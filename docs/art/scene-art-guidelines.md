# 奇趣小岛场景美术与资源规范

## 视觉基准

运行时地图基准是 `assets/art/environment/floating-garden-bg.jpg`，原图 1280×720。它采用明亮的童话绘本插画：轻俯视的三分之四视角，草地以黄绿色为主，河水偏青蓝，石头有柔和的暖色受光；主要高光来自左上方，远景边缘有柔化和空气透视。`woodland-footbridge.png` 和角色 PNG 是独立物件细节密度的参照。场景新素材采用透明 RGBA 切图，保留背景图本身，不替换或重绘整张地图。

## 新增资源清单

| 资源 | 用途 / 任务 | PNG 尺寸 | 游戏显示尺寸 | 锚点 | 碰撞 / 状态 |
| --- | --- | ---: | ---: | --- | --- |
| `assets/art/environment/bridge/woodland-footbridge-damaged.png` | 小桥未修复态，Q001 0/3、施工中的底图 | 1560×1008 | 210×136 | 中心，`BRIDGE_CENTER` | 透明断板口显示不安全缺损；沿用现有桥梁通行条件 |
| `assets/art/environment/bridge/bridge-deck-plank.png` | 桥面施工补板，Q001 1/3、2/3 | 1560×1008 | 24×14 | 中心，对齐 `BRIDGE_SLOTS` | 透明独立单板，完成后切回现有完整桥图 |
| `assets/art/environment/buildings/fox-cottage-construction.png` | 狐狸小屋施工态，Q004 | 626×560 | 154×140 | 底边中心，世界点 `HOUSE_POSITION + (0, 52)` | 房屋主体矩形由 `main.gd` 管理；交付数决定施工态或完成态 |
| `assets/art/environment/buildings/fox-cottage-complete.png` | 狐狸小屋完成态，Q004 | 613×560 | 154×140 | 底边中心，世界点 `HOUSE_POSITION + (0, 52)` | 同上；完成后切换资源，不叠加旧程序屋身 |
| `assets/art/environment/buildings/birdhouse-construction.png` | 鸟屋施工态，Q009 | 300×400 | 76×102 | 底边中心，世界点 `Q009_BIRDHOUSE_POSITION + (0, 40)` | 鸟屋主体矩形由 `main.gd` 管理；交付数显示施工进度 |
| `assets/art/environment/buildings/birdhouse-complete.png` | 鸟屋完成态，Q009 | 297×400 | 76×102 | 底边中心，世界点 `Q009_BIRDHOUSE_POSITION + (0, 40)` | 同上；完工后切换资源 |
| `assets/art/environment/farmland/garden-soil-bed.png` | 种子花圃与乌龟花园土壤层，Q002/Q005 | 800×294 | 204×75 | 中心，`Q005_GARDEN_RECT.get_center()` | 土壤不阻挡；三个植物点和生长状态仍由任务逻辑绘制 |
| `assets/art/environment/pond/natural-pond.png` | 自然岸线与水面，Q003 | 840×497 | 210×124 | 中心，`POND_RECT.get_center()` | 只阻挡水面内部；三块石头任务槽单独绘制 |
| `assets/art/props/river-stone.png` | 河石/石块交互物件，Q003 | 110×80 | 32×23 | 中心 | 使用现有石块位置与拖放规则 |
| `assets/art/decorations/garden-fence.png` | 木篱笆装饰，Q006 | 256×161 | 64×40 | 底边中心，放置点下移 12px | 装饰区不阻挡玩家；已替换程序几何图 |
| `assets/art/decorations/terracotta-planter.png` | 陶盆装饰，Q006 | 181×240 | 42×56 | 底边中心，放置点下移 12px | 装饰区不阻挡玩家；已替换程序几何图 |
| `assets/art/decorations/garden-lantern.png` | 木柱花灯装饰，Q006 | 187×256 | 42×58 | 底边中心，放置点下移 12px | 装饰区不阻挡玩家；已替换程序几何图 |
| `assets/art/props/weathered-planks.png` | 地面拾取木板、托盘图标及小路木板，Q001/Q008 | 320×287 | 地面 72×64；托盘 52×46；小路 60×40 | 中心 | 复用现有项目资源；桥面施工补板使用专用桥面透视素材 |

除 `weathered-planks.png`（仓库已有资源）外，这些资源在 2026-10-30 通过已连接的 OpenAI Image Generation 工具为本项目生成，并使用仓库内地图背景、桥梁和角色作为风格参照；没有下载第三方游戏素材。原始生成图按工具提供的源图 ID 记录在 `assets/art/scene-art-manifest.json`，仓库内版本已裁切透明边距并按目标显示尺寸约 4 倍缩放。许可仍遵循图像生成服务条款，详见 `docs/asset-licenses.md`。

## 后续资源接入约定

1. 一种物件的任务状态优先使用独立纹理资源；状态通过任务逻辑选择纹理，不把已完成资源和临时几何补丁重叠。
2. 每个资源登记世界锚点、显示尺寸、交互区域、地面碰撞和遮挡状态；图片视觉边界不能直接当作碰撞边界。
3. 地面物件使用底边中心锚点，地表贴片使用中心锚点。角色与小屋、鸟屋等可分离物件按脚底 Y 值处理前后关系。
4. PNG 应使用透明背景，不含文字、边框、水印或整块场景；导入前检查 alpha、白边、透视、颜色和缩放结果。
5. 静态资源预加载一次并复用；不在逐帧绘制中生成贴图或重建静态碰撞。

## 合成背景限制

当前地图是单张 JPEG，没有可用的 PSD/分层项目文件。主要树干和岩石已以接地圆形碰撞近似；这不等于每个背景障碍的像素级分割。树冠及岩石前景图层无法从现有合成图中无损取得，因此不生成矩形截图补丁。需要对每个树冠/岩石实现真实前景遮挡时，应由美术提供原始分层，或在不改变底图的前提下制作经过人工校准的透明遮挡图层。

当前单独排序的小屋和鸟屋有角色脚底 Y 判定；这不会改变背景 JPEG 中树冠、树干、岩石的像素层级。碰撞圆登记在 `scene_art_registry.gd`，由地图坐标人工对照测量；如更换背景，必须重新校准这些接地点。
