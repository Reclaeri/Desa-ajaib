class_name DropZone
extends Area2D

@export var zone_label := "Letakkan di sini"
@export var zone_color := Color("8bcf7b")
@export var radius := 58.0


func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	add_child(collision)
	queue_redraw()


func accepts(world_object: WorldObject) -> bool:
	return global_position.distance_to(world_object.global_position) <= radius + 35.0


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, zone_color.darkened(0.15))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 30, Color.WHITE, 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(-radius, radius + 26), zone_label, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 15, Color.WHITE)
