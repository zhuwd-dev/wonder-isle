# M06 · 任务道具与钓鱼素材

**当前游戏道具目录：** [`assets/art/props/`](../../../assets/art/props/)，包含[河石](../../../assets/art/props/river-stone.png)、[种子袋](../../../assets/art/props/seed-pouch.png)、[浇水壶](../../../assets/art/props/watering-can.png)、[木板](../../../assets/art/props/weathered-planks.png)。**游戏内参考：** [生活岛地图截图](../../../art-production-kit/M06-props/gameplay-reference/life-island-map.jpg)。

木板、河石等已融合良好的任务道具优先保留。待制作：小鱼竿、鱼漂、水波、三种收获鱼插画；鱼线可由程序绘制。单件256×256 RGBA透明；鱼竿握持锚点(128,210)，鱼漂水面锚点(128,128)，结果鱼约角色高度0.25–0.4倍；鱼竿/鱼漂反馈轻循环4–6FPS。

**接入：** 任务素材仍在 `assets/art/props/`；新增钓鱼素材放 `assets/art/fishing/`，更新 `assets/art/production-art.json`并接入`main.gd`钓鱼状态。**验收：** 抛竿、鱼线、漂、水波、收竿提示、结果、退出和再次钓鱼均清楚可见；检查花圃/鱼塘交互优先级。

**提示词：**

> 参考附件游戏地图及已有木板、河石和道具，制作匹配奇趣小岛柔和手绘自然风格的儿童钓鱼物件：小型木鱼竿、彩色木塞鱼漂、轻盈水波和三种可爱淡水鱼结果图。分别输出独立透明背景PNG RGBA，建议256×256；鱼竿握持锚点(128,210)，鱼漂接触水面锚点(128,128)，鱼线由程序单独绘制。无文字、无容器、无背景，不要粗糙几何占位。
