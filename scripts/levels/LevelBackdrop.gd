class_name LevelBackdrop
extends Node2D

@export var sky_color := Color("72c9ed")
@export var ground_color := Color("62b85b")
@export var background_path := ""
var is_bright := false
var background_texture: Texture2D
var background_sprite: Sprite2D


func make_bright() -> void:
	is_bright = true
	queue_redraw()


func _ready() -> void:
	if not background_path.is_empty() and ResourceLoader.exists(background_path):
		background_texture = load(background_path)
		background_sprite = Sprite2D.new()
		background_sprite.texture = background_texture
		background_sprite.position = Vector2(background_texture.get_width() * 0.5, background_texture.get_height() * 0.5)
		background_sprite.z_index = -10
		add_child(background_sprite)
	queue_redraw()


func _draw() -> void:
	if background_texture != null:
		return
	var sky := sky_color.lightened(0.14) if is_bright else sky_color
	var ground := ground_color.lightened(0.16) if is_bright else ground_color
	draw_rect(Rect2(-100, -100, 3600, 820), sky)
	draw_circle(Vector2(250, 105), 62, Color("ffe687"))
	draw_rect(Rect2(-100, 790, 4300, 300), ground)
	for x in range(100, 3200, 230):
		draw_circle(Vector2(x, 770), 58, Color("479a57"))
		draw_circle(Vector2(x + 52, 780), 46, Color("3a8c4b"))
	if is_bright:
		for x in range(120, 3100, 145):
			draw_circle(Vector2(x, 820), 9, Color("ff8fc2"))
			draw_circle(Vector2(x + 8, 816), 8, Color("ffd34f"))


func set_background(path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var next_texture: Texture2D = load(path)
	if next_texture == null:
		return
	background_texture = next_texture
	var next_sprite := Sprite2D.new()
	next_sprite.texture = next_texture
	next_sprite.position = Vector2(next_texture.get_width() * 0.5, next_texture.get_height() * 0.5)
	next_sprite.z_index = -9
	next_sprite.modulate.a = 0.0
	add_child(next_sprite)
	var fade := create_tween()
	fade.tween_property(next_sprite, "modulate:a", 1.0, 0.55)
	if is_instance_valid(background_sprite):
		fade.tween_callback(background_sprite.queue_free)
	background_sprite = next_sprite
