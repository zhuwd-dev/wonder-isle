# M01 · 乌龟待机与四足爬行

**原图：** [turtle.png](../../../assets/art/characters/turtle.png)（504×597 RGBA）

**游戏内参考：** [乌龟花园截图](../../../art-production-kit/M01-turtle/gameplay-reference/turtle-garden.jpg)。风格总览：[生活岛地图](../../../art-production-kit/M02-fox/gameplay-reference/life-island-map.jpg)。

**保留：** 浅绿皮肤、棕色龟壳与壳纹、眼睛、圆润绘本比例和当前色光。

**制作规格：** 四方向下/上/左/右；各方向至少6帧连续四足爬行，Idle每向2–4帧，停步转向至少2帧。逐帧独立512×512 PNG RGBA透明背景；脚底锚点固定(256,440)，透明边缘≥24px；6 FPS（允许5–8）。游戏显示高度约85–100逻辑像素，影子由游戏绘制。

**接入：** `assets/art/characters/turtle/{idle,walk}_{down,up,left,right}/`；更新 `assets/art/production-art.json` 并接入 `scripts/boot/main.gd` / `scripts/visual/player_animation.gd`。

**验收：** 原地呼吸/眨眼、四向爬行、靠近后停步转向及互动回应连续录屏；脚底不漂不滑，不跨入水面/建筑；刷新后位置正确。

**可复制提示词：**

> 以附件乌龟PNG为角色身份参考，保留棕色龟壳、浅绿色皮肤、壳纹、原有眼睛与柔和手绘绘本光色。制作四方向下/上/左/右各6帧无缝四足贴地爬行循环，腿部交替迈步，身体重心低，龟壳稳定，头部轻微伸缩；另做四向待机呼吸/眨眼帧和自然停步转向姿势。逐帧独立512×512 RGBA透明PNG，脚底锚点固定(256,440)，至少24px透明边缘。禁止漂浮、整图摇晃、脚底位移、地面、投影、文字、拼格和帧间串色。
