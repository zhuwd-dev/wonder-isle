# M01 乌龟：待机与四足爬行

**当前原图：** `current-art/turtle.png`（游戏文件 `assets/art/characters/turtle.png`，504×597 RGBA）。**地图截图：** `gameplay-reference/turtle-garden.jpg`。

- 保留浅绿皮肤、棕色龟壳及壳纹、眼睛、圆润绘本比例和当前光色。
- 输出贴地四方向：下/上/左/右；每方向至少 6 帧循环爬行；Idle 每方向 2–4 帧；停步转向至少 2 帧。
- 每帧独立 512×512 PNG RGBA 透明背景；脚底锚点 `(256,440)` 固定；透明边缘 ≥24 px；动画 6 FPS（允许 5–8）。游戏显示高度约 85–100 逻辑像素，影子由游戏绘制。
- Godot 接入：`assets/art/characters/turtle/{idle,walk}_{down,up,left,right}/`，注册 `assets/art/production-art.json`，接入 `scripts/boot/main.gd` / `scripts/visual/player_animation.gd`。
- 验收：原地呼吸/眨眼、四向爬行、靠近停步转向和互动回应连续录屏；脚底不漂、不滑，不跨入水面/建筑；刷新后位置正确。

**生成提示词：**
> 以附件乌龟 PNG 为角色身份参考，保留棕色龟壳、浅绿色皮肤、壳纹、原有眼睛与柔和手绘绘本光色。制作四方向下/上/左/右各 6 帧无缝四足贴地爬行循环，腿部交替迈步，身体重心低，龟壳稳定，头部轻微伸缩；另做四向待机呼吸/眨眼帧和自然停步回应姿势。逐帧独立 512×512 RGBA 透明 PNG，脚底锚点固定(256,440)，至少24px透明边缘。禁止漂浮、整图摇晃、脚底位移、地面、投影、文字、拼格和帧间串色。
