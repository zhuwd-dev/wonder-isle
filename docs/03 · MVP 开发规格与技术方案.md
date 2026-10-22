# 《奇趣小岛》MVP 开发规格与技术方案

版本：V1.0  
建议引擎：Godot 4（首选）或 Unity（若开发者已有明显经验优势）  
首版：单机、离线优先、本地存档  
本文是开发规格，不是已经创建的工程。

---

## 1. 技术决策

### 首选：Godot 4 + GDScript
理由：
- 免费开源，适合小型 2D/2.5D 项目。
- 工程轻量，适合快速迭代。
- 不需要后端、账号、数据库或在线服务。
- 场景、资源和脚本组织适合模块化原型。

### 备选：Unity + C#
如果开发者已有 Unity 经验，或关键素材/插件明确依赖 Unity，则优先使用熟悉的工具，避免因换引擎增加学习成本。

### 首版技术原则
- 不引入后端服务。
- 不接登录、分析 SDK、广告或支付 SDK。
- 不在没有实际需要时引入第三方插件。
- 核心玩法逻辑与 UI 尽量分离。
- 任务、物品、动物互动尽可能使用数据配置。
- 先保证功能闭环，再做性能和美术优化。

## 2. 建议目录

```text
WonderIsland/
├── project.godot
├── scenes/
│   ├── boot/Main.tscn
│   ├── island/Island.tscn
│   ├── island/BuildMode.tscn
│   ├── characters/Animal.tscn
│   ├── interactions/Collectible.tscn
│   ├── interactions/InteractionPoint.tscn
│   └── ui/
│       ├── HUD.tscn
│       ├── TaskPanel.tscn
│       └── SettingsPanel.tscn
├── scripts/
│   ├── game_state/
│   ├── interaction/
│   ├── building/
│   ├── quest/
│   ├── save/
│   └── ui/
├── data/
│   ├── items/
│   ├── quests/
│   ├── animals/
│   └── regions/
├── assets/
│   ├── environment/
│   ├── characters/
│   ├── props/
│   ├── ui/
│   └── audio/
├── docs/
│   ├── GDD.md
│   ├── test-checklist.md
│   └── asset-licenses.md
└── tests/  # 只有确有必要且可随项目交付的自动化测试才保留
```

不要为了符合目录示例而大规模搬动已有工程。若已有项目，先审计并沿用合理结构。

## 3. 核心模块

### GameState
维护当前运行状态、已解锁区域、全局事件和当前任务状态。避免多个场景各自维护互相矛盾的进度。

### InteractionSystem
统一处理可交互对象：
- 可否互动；
- 点击反馈；
- 互动锁，防止重复触发；
- 成功/失败回调；
- 事件日志（仅开发调试，不收集儿童数据）。

### QuestSystem
任务配置字段建议：
- id；
- title_key；
- description_key；
- type；
- prerequisites；
- target_id；
- required_count；
- reward_items；
- world_changes；
- state。

任务系统必须校验前置条件，任务完成后只发奖一次。

### BuildingSystem
负责：
- 进入/退出建造模式；
- 选择物品；
- 拖拽预览；
- 检查允许放置区域；
- 网格吸附（若使用）；
- 检查重叠；
- 确认、取消、移动和移除；
- 更新存档。

关键建造点（桥、花园、动物住所）使用关卡状态，不作为普通可移动装饰。

### InventorySystem
仅维护首版必要资源与解锁装饰。不引入复杂经济系统。资源变更应由明确游戏事件触发，并保证重复事件不会重复奖励。

### SaveSystem
本地存档，至少包含 schema_version、任务状态、区域解锁、资源、已解锁物品、摆放数据和设置。

建议实现：
1. 写入临时文件；
2. 校验写入结果；
3. 采用安全替换策略；
4. 保留最近一次有效备份（若平台与文件接口允许）；
5. 读取时校验字段和版本；
6. 不兼容时安全回退，并告知玩家可恢复的状态。

不要把存档当作可信任的外部输入；读取时校验类型、范围和 ID。

## 4. 数据结构草案

### ItemDefinition
```json
{
  "id": "decor_flower_01",
  "display_name_key": "item.flower_01.name",
  "category": "decor",
  "scene_path": "res://scenes/...",
  "placeable": true,
  "allowed_surface": ["garden"],
  "rotations": [0, 90, 180, 270]
}
```

### QuestDefinition
```json
{
  "id": "Q001",
  "type": "collect_and_build",
  "prerequisites": [],
  "target_id": "bridge_main",
  "required_count": 3,
  "reward_items": [{"id": "seed_glow", "count": 1}],
  "world_changes": [{"id": "bridge_main", "state": "repaired"}]
}
```

### SaveData
```json
{
  "schema_version": 1,
  "unlocked_regions": ["meadow"],
  "completed_quests": [],
  "quest_states": {},
  "inventory": {},
  "unlocked_items": [],
  "placed_objects": [],
  "plant_states": {},
  "settings": {
    "music_volume": 0.8,
    "sfx_volume": 0.8
  }
}
```

以上是概念数据结构，具体序列化格式以所选引擎和项目实现为准。避免将资源路径直接暴露给用户可编辑的数据，加载时需验证资源 ID。

## 5. 场景与操作

### MVP 场景
- Main：初始化状态、载入存档、进入小岛。
- Island：地图与互动对象。
- Animal：动物角色、互动动画和请求。
- Collectible：可收集物。
- BuildMode：选择与摆放装饰。
- HUD：任务提示、资源、建造入口。
- SettingsPanel：音量、返回等基本设置。

### 输入
- 鼠标输入可用于编辑器测试。
- 触屏输入作为目标交互；要处理点击和拖拽冲突。
- 可交互对象应有最小点击区域。
- 不能只依赖 hover 状态。
- 支持安全区域和常见屏幕比例。

## 6. 美术资源规则

- 选择统一风格、明确可商用的资源。
- 记录每项资源的来源、作者、许可证、购买凭证、署名要求和使用限制。
- 不从其他游戏提取模型、贴图、音乐或角色。
- AI 生成资产需记录生成来源和使用条款，并人工检查一致性。
- 优先复用材质、色板、地形模块和基础动画。
- 第一版不要求每个对象都有独立复杂骨骼动画。

## 7. 质量要求

### 功能
- 新游戏可以进入。
- 核心任务可完成。
- 建造可放置、移动、移除。
- 重复点击不会重复奖励。
- 进度可保存与恢复。
- 损坏存档不会导致无提示崩溃。
- 无网络时所有首版玩法可用。

### 性能
- 以目标测试设备的稳定流畅为目标。
- 先测真实设备，再按数据优化；不凭感觉提前做复杂优化。
- 避免每帧大量扫描全部对象。
- 地图与物件优先使用可复用资源。
- 不因一个装饰物引入昂贵的实时特效。

### 安全
- 不发起未声明的网络请求。
- 不收集儿童个人信息。
- 不包含广告、支付、聊天或公开 UGC。
- 日志不输出个人信息。
- 所有素材授权有记录。

## 8. 开发顺序与验收

### 阶段 A：工程与交互骨架
验收：能启动，显示小岛，点击对象有反馈。

### 阶段 B：任务闭环
验收：完成寻物、交付、修桥，地图状态发生变化。

### 阶段 C：建造
验收：装饰可以拖拽、合法性检查、重新摆放并保存。

### 阶段 D：存档
验收：关闭重启后恢复；重复奖励被阻止；无效存档有安全处理。

### 阶段 E：MVP 内容
验收：3 种动物、约 12 个任务、约 15 件装饰可正常完成。

### 阶段 F：触屏与试玩
验收：目标设备上关键交互可用；完成测试清单；记录试玩问题。

## 9. 不允许 AI 擅自做的事情

- 不得未经确认更换引擎或引入后端。
- 不得添加联网分析、广告、支付、账号、聊天或云同步。
- 不得删除或覆盖用户已有文件而不先检查。
- 不得一次性生成大量无验收的场景与脚本。
- 不得宣称测试通过，除非实际运行了相应测试。
- 不得把临时占位素材标记为最终授权素材。
- 不得为了“架构完善”提前引入复杂依赖。
