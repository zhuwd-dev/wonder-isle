extends RefCounted

## Small data-oriented registry for reusable scene sprites. Positions are their
## ground contact anchors; collision geometry remains owned by world logic.

const FOX_COTTAGE_COMPLETE: Texture2D = preload("res://assets/art/environment/buildings/fox-cottage-complete.png")
const FOX_COTTAGE_CONSTRUCTION: Texture2D = preload("res://assets/art/environment/buildings/fox-cottage-construction.png")
const BIRDHOUSE_COMPLETE: Texture2D = preload("res://assets/art/environment/buildings/birdhouse-complete.png")
const BIRDHOUSE_CONSTRUCTION: Texture2D = preload("res://assets/art/environment/buildings/birdhouse-construction.png")
const GARDEN_SOIL_BED: Texture2D = preload("res://assets/art/environment/farmland/garden-soil-bed.png")
const NATURAL_POND: Texture2D = preload("res://assets/art/environment/pond/natural-pond.png")
const RIVER_STONE: Texture2D = preload("res://assets/art/props/river-stone.png")
const GARDEN_FENCE: Texture2D = preload("res://assets/art/decorations/garden-fence.png")
const TERRACOTTA_PLANTER: Texture2D = preload("res://assets/art/decorations/terracotta-planter.png")
const GARDEN_LANTERN: Texture2D = preload("res://assets/art/decorations/garden-lantern.png")
const DAMAGED_WOODLAND_BRIDGE: Texture2D = preload("res://assets/art/environment/bridge/woodland-footbridge-damaged.png")
const BRIDGE_REPAIR_PLANK: Texture2D = preload("res://assets/art/environment/bridge/bridge-deck-plank.png")

const FOX_COTTAGE_SIZE := Vector2(154, 140)
const BIRDHOUSE_SIZE := Vector2(76, 102)
const GARDEN_SOIL_SIZE := Vector2(204, 75)
const POND_SIZE := Vector2(210, 124)
const RIVER_STONE_SIZE := Vector2(32, 23)
const GARDEN_FENCE_SIZE := Vector2(64, 40)
const TERRACOTTA_PLANTER_SIZE := Vector2(42, 56)
const GARDEN_LANTERN_SIZE := Vector2(42, 58)
const BRIDGE_REPAIR_PLANK_SIZE := Vector2(24, 14)

## Background-image collision contacts, measured in the 1280x720 world image.
## Tree collision is at the trunk base; canopies and small flowers remain open.
## Rock circles are conservative ground-contact approximations, not image bounds.
const BACKGROUND_OBSTACLES := [
	{
		"id": "northwest_cherry_trunk",
		"kind": "tree_trunk",
		"center": Vector2(118, 180),
		"radius": 13.0,
		"visual_bounds": Rect2(40, 56, 150, 145),
		"root_y": 181.0,
	},
	{
		"id": "west_meadow_boulder",
		"kind": "rock",
		"center": Vector2(112, 226),
		"radius": 18.0,
		"visual_bounds": Rect2(64, 191, 83, 75),
		"root_y": 246.0,
	},
	{
		"id": "southwest_cherry_trunk",
		"kind": "tree_trunk",
		"center": Vector2(126, 520),
		"radius": 12.0,
		"visual_bounds": Rect2(50, 458, 136, 101),
		"root_y": 533.0,
	},
	{
		"id": "southwest_shore_rock",
		"kind": "rock",
		"center": Vector2(246, 562),
		"radius": 15.0,
		"visual_bounds": Rect2(215, 535, 64, 57),
		"root_y": 581.0,
	},
	{
		"id": "south_meadow_rock",
		"kind": "rock",
		"center": Vector2(584, 558),
		"radius": 16.0,
		"visual_bounds": Rect2(541, 532, 91, 59),
		"root_y": 576.0,
	},
	{
		"id": "northeast_cherry_trunk",
		"kind": "tree_trunk",
		"center": Vector2(1182, 171),
		"radius": 12.0,
		"visual_bounds": Rect2(1113, 88, 167, 134),
		"root_y": 191.0,
	},
	{
		"id": "east_shore_boulder",
		"kind": "rock",
		"center": Vector2(950, 257),
		"radius": 16.0,
		"visual_bounds": Rect2(926, 224, 54, 66),
		"root_y": 280.0,
	},
	{
		"id": "southeast_cliff_rock",
		"kind": "rock",
		"center": Vector2(1177, 528),
		"radius": 17.0,
		"visual_bounds": Rect2(1141, 491, 75, 76),
		"root_y": 554.0,
	},
]


static func draw_centered(canvas: CanvasItem, texture: Texture2D, center: Vector2, size: Vector2, modulate := Color.WHITE) -> void:
	canvas.draw_texture_rect(texture, Rect2(center - size * 0.5, size), false, modulate)


static func draw_grounded(canvas: CanvasItem, texture: Texture2D, ground_anchor: Vector2, size: Vector2, modulate := Color.WHITE) -> void:
	var rect := Rect2(ground_anchor - Vector2(size.x * 0.5, size.y), size)
	canvas.draw_texture_rect(texture, rect, false, modulate)
