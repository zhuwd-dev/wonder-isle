extends Node2D
## Texture-alpha outline: follows the illustrated silhouette, not a geometric ring.
const EFFECT = preload("res://scripts/visual/ground_focus.gdshader")
var texture: Texture2D
var display_size := Vector2(204, 75)
func _init() -> void:
	var shader_material := ShaderMaterial.new()
	shader_material.shader = EFFECT
	material = shader_material
func show_focus(source: Texture2D, screen_top_left: Vector2, world_size: Vector2, camera_scale: float, strength: float) -> void:
	texture = source
	display_size = world_size
	position = screen_top_left
	scale = Vector2.ONE * camera_scale
	visible = strength > 0.005
	(material as ShaderMaterial).set_shader_parameter("radius_uv", Vector2(8.0 / world_size.x, 8.0 / world_size.y))
	(material as ShaderMaterial).set_shader_parameter("strength", strength)
	(material as ShaderMaterial).set_shader_parameter("silhouette", source)
	(material as ShaderMaterial).set_shader_parameter("content_scale", (world_size + Vector2(20, 20)) / world_size)
	queue_redraw()
func _draw() -> void:
	if texture != null:
		draw_texture_rect(texture, Rect2(Vector2(-10, -10), display_size + Vector2(20, 20)), false)
