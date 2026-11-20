# M01 · 乌龟待机、四足爬行与互动

## 参考与身份锁定

- 原始角色：[turtle.png](../../../assets/art/characters/turtle.png)，504×597 RGBA。
- 实际游戏参考：[乌龟花园截图](../../../art-production-kit/M01-turtle/gameplay-reference/turtle-garden.jpg)。风格参考：[生活岛地图](../../../art-production-kit/M02-fox/gameplay-reference/life-island-map.jpg)。
- 保持原图的浅绿皮肤、琥珀棕色分片龟壳、壳上的绿植与白花、眼睛、脸部比例、柔和高光和绘本质感。不要重设计、改色、加配饰或改变物种比例。
- 角色当前在世界坐标约 `(1160,280)` 的池塘旁；锚点表示脚底，不是图片中心。影子由游戏绘制，不烘焙进素材。

## 交付帧规格

| 动画 | 方向 | 帧数 | FPS | 循环 |
|---|---|---:|---:|---|
| `idle` | down / up / left / right | 每向 3 帧 | 2 | 是 |
| `walk` | down / up / left / right | 每向 6 帧 | 6（允许 5–8） | 是 |
| `turn` | down / up / left / right 的转向组合 | 每次至少 2 帧 | 6 | 否 |
| `interact` | 四向注视玩家并友好回应 | 每向 4 帧 | 6 | 否，结束回 idle |
| `happy` | down / up / left / right | 每向 4 帧 | 6 | 否，结束回 idle |

每帧是一张**单独的** 512×512 PNG RGBA，透明背景，不能提交拼图或图集。脚底锚点固定在 `(256,440)`，每帧距画布边缘至少 24px。角色整体大小、龟壳轮廓和基线在同一组中保持一致。场景显示高度约 85–100 逻辑像素；不改碰撞盒来迁就图片。

文件目录和命名：

```text
assets/art/characters/turtle/
  idle_down/000.png ... 002.png
  idle_up/000.png ... 002.png
  idle_left/000.png ... 002.png
  idle_right/000.png ... 002.png
  walk_down/000.png ... 005.png
  walk_up/000.png ... 005.png
  walk_left/000.png ... 005.png
  walk_right/000.png ... 005.png
  interact_<direction>/000.png ... 003.png
  happy_<direction>/000.png ... 003.png
```

逐帧动作说明和可复制提示词见 [GENERATION_PROMPTS.md](GENERATION_PROMPTS.md)。

## 动作要求

- **Idle**：四足着地，龟壳与身体基线稳定；呼吸只在胸颈有细微变化，眨眼不带动整张身体上下浮动。
- **Walk**：低重心四足爬行；前后肢交替迈步，支撑脚贴地，摆动脚抬起幅度很小；壳保持刚性，不缩放、不摇摆。方向循环首尾应连贯。
- **Turn**：脚和壳先稳定，头部先转向，随后身体朝向对齐；禁止把整张图旋转成新方向。
- **Interact**：朝玩家轻抬头/注视、眨眼或轻轻伸颈，回应友好；动作结束准确回到当前方向的 idle。
- **Happy**：Q005 交付完成后给短暂微笑、眨眼或轻抬前足的反馈；四足仍有地面支撑，不跳起、不明显弹壳。

## 接入与运行验收

候选帧先放 `assets/art/incoming/M01-turtle/`，完成透明通道、锚点、帧序、尺寸和 SHA256 检查后，再迁入以上正式目录。更新 `assets/art/production-art.json`，使用当前角色绘制层和 `scripts/visual/player_animation.gd` 的状态切换方式接入；不改存档字段、Q005 条件、碰撞、玩家输入或其它 NPC。

动画状态依据 `turtle_position` 的实际位移判断。被水岸、池塘或树木碰撞阻止后应回 idle；玩家接近/交互时暂时抑制移动并播放转向或回应，之后恢复原巡游目标。刷新仍从现有任务/世界状态恢复，不保存动画帧序号。

最终验收需在实际游戏地图检查四方向 idle/walk、停步、障碍碰撞、靠近注视、互动和 Q005 完成反馈；录制真实运行视频。检查脚底无滑动、壳体稳定、无闪烁/裁切/比例突变，避免穿入池塘、水面、建筑和树木遮挡区。再运行 Godot 全量回归、乌龟巡游、Q005、交互优先级、浇水收获、存档刷新、手机横屏及动画资源加载测试。

## 当前状态

**VISUAL BLOCKED**：已对照原图试生成爬行序列样稿，但样稿有不透明背景且腿部动作没有形成连续交替，未达到本规格的透明帧与动画验收要求，因此未放进游戏，也未替换当前静态素材。需要外部美术提供符合 `GENERATION_PROMPTS.md` 的独立 PNG 帧后再接入。

当前游戏以 `scripts/boot/main.gd::_draw_turtle()` 绘制单张 `assets/art/characters/turtle.png`。现有 `scripts/visual/player_animation.gd` 是玩家鼠标动画控制器，乌龟尚未接入；`_keep_turtle_at_habitat()` 当前将乌龟固定在栖息点。正式动画帧验收前不启用程序化肢体动作，也不伪造爬行。
