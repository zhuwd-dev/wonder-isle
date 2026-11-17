# M04 · 鸟类停留、飞行与回应

**角色原图：** [bird.png](../../../assets/art/characters/bird.png)（466×595 RGBA）。**鸟屋：** [birdhouse-complete.png](../../../assets/art/environment/birdhouse-complete.png)。**游戏内参考：** [生活岛地图截图](../../../art-production-kit/M04-birds/gameplay-reference/life-island-map.jpg)。

保留鸟喙、羽色、眼睛、比例和鸟屋风格；鸟爪落点固定，飞行起落不变形。停留/待机2–4帧；短飞行及落栖循环≥6帧；打招呼/任务回应4–6帧；建议8FPS。单帧512×512透明RGBA，爪部锚点(256,440)，边缘≥24px；飞行可另记录偏移。

**接入：** `assets/art/characters/bird/`、`assets/art/production-art.json`、`scripts/boot/main.gd`鸟屋互动响应。**验收：** 打招呼后清晰回应；飞离/落栖不闪现，刷新不重置鸟屋进度。

**提示词：**

> 参考附件小鸟和鸟屋截图，保持羽色、鸟喙、眼睛和柔和绘本风格。制作停留待机、眨眼、面向玩家回应、短距离振翅飞行并回到栖木的动作。待机2–4帧，飞行至少6帧循环，回应4–6帧，8FPS。逐帧独立512×512透明RGBA，爪部落点锚点固定(256,440)，透明边缘至少24px。禁止羽色漂移、翅膀糊成一团、鸟屋/树枝背景、文字、投影和拼格。
