class_name NpcCharacter
extends Area2D

signal tapped

@export var character_name := "Warga"
@export var body_color := Color("67ad5b")
@export var mood := "senang"
@export var texture_path := ""
var texture_sprite: Sprite2D
var name_label: PanelContainer
var interaction_indicator: PanelContainer
var _sprite_rest_position := Vector2.ZERO
var _sprite_rest_scale := Vector2.ONE
var _idle_tween: Tween
var _reaction_tween: Tween
var _indicator_tween: Tween


func set_character_name(value: String) -> void:
	character_name = value
	if is_instance_valid(name_label) and name_label.get_child_count() > 0:
		(name_label.get_child(0) as Label).text = character_name.to_upper()


func _set_name_label_visibility(is_visible: bool) -> void:
	if is_instance_valid(name_label):
		name_label.visible = is_visible


func set_character_texture(value: String) -> void:
	texture_path = value
	if value.is_empty() or not ResourceLoader.exists(value):
		return
	if texture_sprite == null:
		texture_sprite = Sprite2D.new()
		add_child(texture_sprite)
		move_child(texture_sprite, 0)
	var texture: Texture2D = load(value)
	texture_sprite.texture = texture
	var sprite_scale := minf(0.46, 220.0 / maxf(float(texture.get_height()), 1.0))
	texture_sprite.scale = Vector2.ONE * sprite_scale
	texture_sprite.position.y = -(float(texture.get_height()) * sprite_scale) * 0.5
	_sprite_rest_position = texture_sprite.position
	_sprite_rest_scale = texture_sprite.scale
	if is_instance_valid(name_label):
		name_label.position.y = texture_sprite.position.y - (float(texture.get_height()) * sprite_scale * 0.5) - 36.0
	_start_idle_animation()


func set_sad(is_sad: bool) -> void:
	mood = "sedih" if is_sad else "senang"
	queue_redraw()


func _ready() -> void:
	add_to_group("mission_characters")
	input_pickable = true
	var collision := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 54.0
	shape.height = 244.0
	collision.position.y = -110.0
	collision.shape = shape
	add_child(collision)
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		var texture: Texture2D = load(texture_path)
		texture_sprite = Sprite2D.new()
		texture_sprite.texture = texture
		var target_height := 220.0
		var sprite_scale := minf(0.46, target_height / maxf(float(texture.get_height()), 1.0))
		texture_sprite.scale = Vector2.ONE * sprite_scale
		texture_sprite.position.y = -(float(texture.get_height()) * sprite_scale) * 0.5
		_sprite_rest_position = texture_sprite.position
		_sprite_rest_scale = texture_sprite.scale
		add_child(texture_sprite)
	name_label = PanelContainer.new()
	var label_y := -140.0
	if texture_sprite != null:
		label_y = texture_sprite.position.y - (float(texture_sprite.texture.get_height()) * texture_sprite.scale.y * 0.5) - 36.0
	name_label.position = Vector2(-70, label_y)
	name_label.size = Vector2(140, 30)
	var label_style := StyleBoxFlat.new()
	label_style.bg_color = Color("397b55")
	label_style.corner_radius_top_left = 12
	label_style.corner_radius_top_right = 12
	label_style.corner_radius_bottom_left = 12
	label_style.corner_radius_bottom_right = 12
	label_style.content_margin_left = 8
	label_style.content_margin_right = 8
	label_style.content_margin_top = 4
	label_style.content_margin_bottom = 4
	name_label.add_theme_stylebox_override("panel", label_style)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.visible = GameManager.game_state == GameManager.GameState.MISSION and LevelManager.current_level_id != &"level_1"
	var text := Label.new()
	text.text = character_name.to_upper()
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 16)
	text.add_theme_color_override("font_color", Color.WHITE)
	text.add_theme_color_override("font_shadow_color", Color("163350"))
	text.add_theme_constant_override("shadow_offset_x", 1)
	text.add_theme_constant_override("shadow_offset_y", 2)
	name_label.add_child(text)
	name_label.z_index = 2
	add_child(name_label)
	interaction_indicator = PanelContainer.new()
	interaction_indicator.position = Vector2(-58.0, name_label.position.y - 36.0)
	interaction_indicator.size = Vector2(116, 28)
	var hint_style := StyleBoxFlat.new()
	hint_style.bg_color = Color("fff0cf")
	hint_style.border_color = Color("d39a3f")
	hint_style.set_border_width_all(2)
	hint_style.set_corner_radius_all(12)
	interaction_indicator.add_theme_stylebox_override("panel", hint_style)
	interaction_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interaction_indicator.visible = false
	var hint_label := Label.new()
	hint_label.text = "KLIK / SENTUH"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", Color("57351f"))
	interaction_indicator.add_child(hint_label)
	add_child(interaction_indicator)
	_start_idle_animation()


func _start_idle_animation() -> void:
	if not is_instance_valid(texture_sprite):
		return
	if _reaction_tween != null and _reaction_tween.is_running():
		return
	if _idle_tween != null and _idle_tween.is_running():
		return
	texture_sprite.position = _sprite_rest_position
	texture_sprite.scale = _sprite_rest_scale
	texture_sprite.rotation = 0.0
	_idle_tween = create_tween().set_loops()
	_idle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(texture_sprite, "position:y", _sprite_rest_position.y - 2.0, 1.0)
	_idle_tween.parallel().tween_property(texture_sprite, "rotation", -0.012, 1.0)
	_idle_tween.tween_property(texture_sprite, "position:y", _sprite_rest_position.y, 1.0)
	_idle_tween.parallel().tween_property(texture_sprite, "rotation", 0.0, 1.0)


func play_happy_reaction() -> void:
	if not is_instance_valid(texture_sprite):
		set_sad(false)
		return
	if _idle_tween != null and _idle_tween.is_running():
		_idle_tween.kill()
	if _reaction_tween != null and _reaction_tween.is_running():
		_reaction_tween.kill()
	texture_sprite.position = _sprite_rest_position
	texture_sprite.rotation = 0.0
	texture_sprite.scale = _sprite_rest_scale
	var rest_scale := _sprite_rest_scale
	_reaction_tween = create_tween()
	_reaction_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_reaction_tween.tween_property(texture_sprite, "position:y", _sprite_rest_position.y - 10.0, 0.14)
	_reaction_tween.parallel().tween_property(texture_sprite, "scale", rest_scale * 1.06, 0.14)
	_reaction_tween.tween_property(texture_sprite, "position:y", _sprite_rest_position.y, 0.2)
	_reaction_tween.parallel().tween_property(texture_sprite, "scale", rest_scale, 0.2)
	_reaction_tween.finished.connect(_start_idle_animation)
	set_sad(false)


func set_interaction_indicator(is_available: bool) -> void:
	if not is_instance_valid(interaction_indicator) or interaction_indicator.visible == is_available:
		return
	interaction_indicator.visible = is_available
	if _indicator_tween != null and _indicator_tween.is_running():
		_indicator_tween.kill()
	interaction_indicator.scale = Vector2.ONE
	if is_available:
		interaction_indicator.pivot_offset = interaction_indicator.size * 0.5
		_indicator_tween = create_tween().set_loops()
		_indicator_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_indicator_tween.tween_property(interaction_indicator, "scale", Vector2(1.04, 1.04), 0.5)
		_indicator_tween.tween_property(interaction_indicator, "scale", Vector2.ONE, 0.5)


func _input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		var viewport := get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()
		tapped.emit()


func _draw() -> void:
	if texture_sprite != null:
		return
	draw_circle(Vector2(0, -28), 28.0, body_color)
	draw_rect(Rect2(-23, 0, 46, 42), body_color.darkened(0.15), true)
	draw_circle(Vector2(-9, -32), 3.0, Color("202030"))
	draw_circle(Vector2(9, -32), 3.0, Color("202030"))
	if mood == "sedih":
		draw_arc(Vector2(0, -15), 10, PI, TAU, 12, Color("202030"), 2)
	else:
		draw_arc(Vector2(0, -23), 10, 0, PI, 12, Color("202030"), 2)
	draw_string(ThemeDB.fallback_font, Vector2(-40, 58), character_name, HORIZONTAL_ALIGNMENT_CENTER, 80, 15, Color.WHITE)
