class_name Lili
extends CharacterBody2D

signal interaction_requested
signal npc_detected(npc: Node2D)
signal npc_left(npc: Node2D)

enum AnimationState {
	IDLE,
	WALKING,
}

@export var walk_speed := 240.0
@export var world_left := 48.0
@export var world_right := 4080.0

var animation_state: AnimationState = AnimationState.IDLE
var nearby_npcs: Array[Node2D] = []
var name_label: PanelContainer
var facing_direction := 1.0


func _ready() -> void:
	var animated_sprite: AnimatedSprite2D = $"Visuals/AnimatedSprite2D"
	var first_frame: Texture2D = animated_sprite.sprite_frames.get_frame_texture(&"idle_right", 0)
	var label_y := -266.0
	if first_frame != null:
		var character_scale := 0.56
		animated_sprite.scale = Vector2.ONE * character_scale
		animated_sprite.position.y = -float(first_frame.get_height()) * character_scale * 0.5 + 5.0
		label_y = animated_sprite.position.y - float(first_frame.get_height()) * character_scale * 0.5 - 38.0
	name_label = PanelContainer.new()
	name_label.position = Vector2(-48, label_y)
	name_label.size = Vector2(96, 28)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("397b55")
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	name_label.add_theme_stylebox_override("panel", style)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.visible = false
	var label := Label.new()
	label.text = "LILI"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_child(label)
	name_label.z_index = 2
	add_child(name_label)


func set_animation_state(new_state: AnimationState) -> void:
	animation_state = new_state


func request_interaction() -> void:
	interaction_requested.emit()


func _physics_process(_delta: float) -> void:
	var can_move := GameManager.game_state == GameManager.GameState.PLAYING or (GameManager.game_state == GameManager.GameState.MISSION and LevelManager.current_level_id == &"level_1")
	if not can_move:
		velocity.x = 0.0
		_set_idle_state()
		return
	var direction := InputManager.get_horizontal_movement()
	velocity.x = direction * walk_speed
	var previous_position := global_position
	move_and_slide()
	position.x = clampf(position.x, world_left, world_right)
	var moved := absf(global_position.x - previous_position.x) > 0.5
	if not is_zero_approx(direction) and moved:
		facing_direction = signf(direction)
		animation_state = AnimationState.WALKING
		$Visuals/AnimatedSprite2D.play(&"walk_right" if facing_direction > 0.0 else &"walk_left")
		$Visuals.scale.x = 1.0
		AudioManager.set_walking(true)
	else:
		_set_idle_state()
	queue_redraw()


func _set_idle_state() -> void:
	AudioManager.set_walking(false)
	animation_state = AnimationState.IDLE
	$Visuals/AnimatedSprite2D.play(&"idle_right" if facing_direction > 0.0 else &"idle_left")
	# Idle profile assets face left, so mirror only the idle-right pose.
	$Visuals.scale.x = -1.0 if facing_direction > 0.0 else 1.0


func _exit_tree() -> void:
	AudioManager.set_walking(false)


func _draw() -> void:
	if $Visuals/AnimatedSprite2D.sprite_frames != null:
		return
	# Placeholder Lili: brown rabbit with a green vest, ready to be replaced by sprites.
	draw_circle(Vector2(0, -20), 30.0, Color("9a6549"))
	draw_circle(Vector2(-12, -61), 9.0, Color("9a6549"))
	draw_circle(Vector2(12, -61), 9.0, Color("9a6549"))
	draw_rect(Rect2(-26, 0, 52, 42), Color("3c9b63"), true)
	draw_circle(Vector2(-10, -22), 3.0, Color("202030"))
	draw_circle(Vector2(10, -22), 3.0, Color("202030"))


func _on_npc_detection_area_body_entered(body: Node2D) -> void:
	if body == self or body in nearby_npcs:
		return
	nearby_npcs.append(body)
	npc_detected.emit(body)


func _on_npc_detection_area_body_exited(body: Node2D) -> void:
	if not body in nearby_npcs:
		return
	nearby_npcs.erase(body)
	npc_left.emit(body)
