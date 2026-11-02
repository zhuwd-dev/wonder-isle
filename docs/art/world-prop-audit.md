# 世界道具与引导检查（批次 B）

状态含义：PASS 为已有图片且具备接地处理；FIX 为本批改善；ASSET_REQUIRED 为仍需要合格的童话风格素材。交互和任务条件沿用现有实现。视觉质量仍需在设备上持续验收。

| 任务 / 物品 | 当前素材或绘制 | 状态与待处理 |
| --- | --- | --- |
| Q001 木板 | `assets/art/props/weathered-planks.png`，`_draw_board_at` | PASS：地面锚点、阴影、靠近提示；托盘仍需进一步统一。 |
| Q001 桥梁 | `assets/art/environment/bridge/woodland-footbridge-{damaged,complete}.png` | PASS：损坏、修理和完工素材；保留真实碰撞。 |
| Q002 种子 | `assets/art/props/seed-pouch.png` | FIX：带阴影的种子袋，靠近才出现小亮点，去除名称。 |
| Q002 花圃 | `assets/art/environment/farmland/garden-soil-bed.png` | FIX：携带种子且靠近时柔光；任务结束不显示旧提示。 |
| Q002 幼苗 | `_draw_seed_area` 程序线条和圆形 | ASSET_REQUIRED：需要无裸露根系、与土壤融合的高质量植物素材。 |
| Q003 石头 | `assets/art/props/river-stone.png` | FIX：移除世界名称；拖拽轮廓及池塘标签仍需统一。 |
| Q004 木材 | `assets/art/props/island-wood-crate.png` | FIX：移除常驻名称，靠近显示细小亮点；材料栏仍需材质和尺寸重设计。 |
| Q004 小屋 | `assets/art/environment/buildings/fox-cottage-{construction,complete}.png` | PASS：图片和地面锚点；施工进度文字仍需进一步优化。 |
| Q005 植株和浇水点 | `_draw_q005_plant_at` 等程序绘制 | ASSET_REQUIRED：缺成长、开花及收获后的统一贴图；状态提示保留以确保可理解。 |
| Q006 栅栏、花盆、路灯 | `assets/art/decorations/` 下三个 PNG | PASS：各有素材和锚点；自由摆放遵循原碰撞。 |
| Q007 贝壳 | `_draw_q007_shell_at` 程序绘制 | ASSET_REQUIRED：缺真实接地贝壳及奖励素材。 |
| Q008 石板 | `assets/art/props/weathered-planks.png` 复用 | ASSET_REQUIRED：缺具有石材质感的道路素材。 |
| Q009 树枝、羽毛、草绳 | `_draw_q009_material_at` 程序绘制 | ASSET_REQUIRED：缺三件有自然材质和接地锚点的素材。 |
| Q009 鸟屋 | `assets/art/environment/buildings/birdhouse-{construction,complete}.png` | PASS：有施工和完工状态。 |
| Q010 彩色种子 | `_draw_q010_seed_at` 程序绘制 | ASSET_REQUIRED：缺可区分三色的自然种子素材；保留名称辅助辨识。 |
| Q011 木箱、布包、竹篮 | `_draw_q011_item_at` 程序绘制 | ASSET_REQUIRED：缺三件配套插画素材。 |
| Q012 庆祝 | 现有 NPC 立绘、粒子和任务提示 | FIX：保留明确的庆祝引导；NPC 真正步行动画仍需资源。 |

兔子：修桥时作为任务发起者，后续在安全休息位置，可主动点击；靠近时显示轻量对话图形。当前仍没有可信的行走帧和真实往返行为，不能称作散步动画。
