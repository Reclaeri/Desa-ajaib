class_name WorldObject
extends Area2D
## WorldObject - Desa Ajaib (For Mother)
## Versi ramah anak SD kelas 1-3:
## - Area sentuh besar (mudah ditekan jari kecil)
## - Objek "bernapas" pelan supaya anak tahu itu bisa disentuh
## - Efek membesar saat disentuh / diseret, bayangan, dan animasi pop saat selesai
## - Label besar dengan latar supaya mudah dibaca
## - Bisa kembali ke posisi awal kalau salah taruh (return_home)
## - BARU: place_feet_at() supaya kaki karakter menapak tepat di jalan
## API lama tetap sama: signal activated & drag_ended, activate(), is_collected.

signal activated(world_object: WorldObject)
signal drag_ended(world_object: WorldObject)

const HIT_RADIUS := 48.0
const MAX_SPRITE_HEIGHT := 130.0
const MAX_SPRITE_SCALE := 0.36
const HOVER_SCALE := 1.12
const DRAG_SCALE := 1.22
const IDLE_PULSE := 1.05

@export var object_label := "Objek"
@export var object_color := Color("f5bf4f")
@export var draggable := false
@export var texture_path := ""
@export var show_label := true
@export var idle_animation := true
## Kalau true, objek digeser otomatis supaya kakinya ada di feet_position
## (posisi global) saat _ready. Cocok untuk karakter yang berdiri di jalan.
@export var snap_feet_on_ready := false
@export var feet_position := Vector2.ZERO

var is_collected := false
var is_dragging := false
var texture_sprite: Sprite2D
var last_pointer_position := Vector2.ZERO
var dragging_touch := false
var home_position := Vector2.ZERO

var _drag_offset := Vector2.ZERO
var _base_scale := Vector2.ONE
var _visual_scale := 1.0
var _scale_tween: Tween
var _idle_tween: Tween
var _highlight_tween: Tween
var _proximity_highlighted := false
var _highlight_alpha := 0.28


func _ready() -> void:
	add_to_group("world_objects")
	input_pickable = true
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = HIT_RADIUS
	collision.shape = shape
	add_child(collision)
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		var texture: Texture2D = load(texture_path)
		texture_sprite = Sprite2D.new()
		texture_sprite.texture = texture
		var height := maxf(float(texture.get_height()), 1.0)
		_base_scale = Vector2.ONE * minf(MAX_SPRITE_SCALE, MAX_SPRITE_HEIGHT / height)
		texture_sprite.scale = _base_scale
		add_child(texture_sprite)
	if snap_feet_on_ready:
		place_feet_at(feet_position)
	home_position = global_position
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	_start_idle_animation()
	queue_redraw()


# ------------------------------------------------------------- INPUT

func _input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if is_collected:
		return
	if draggable:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_begin_drag(false, get_global_mouse_position())
		elif event is InputEventScreenTouch and event.pressed:
			_begin_drag(true, _screen_to_world(event.position))
		elif event is InputEventScreenDrag and is_dragging:
			_move_to(_screen_to_world(event.position))
	elif (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_mark_input_handled()
		_pop()
		activated.emit(self)


func _input(event: InputEvent) -> void:
	if not is_dragging or is_collected:
		return
	if event is InputEventScreenDrag:
		_move_to(_screen_to_world(event.position))
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and not event.pressed:
		_move_to(_screen_to_world(event.position))
		_end_drag()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_move_to(get_global_mouse_position())
		_end_drag()


func _process(_delta: float) -> void:
	if is_dragging and not dragging_touch and not is_collected:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_move_to(get_global_mouse_position())
		else:
			_end_drag()


func _begin_drag(by_touch: bool, pointer_world: Vector2) -> void:
	dragging_touch = by_touch
	is_dragging = true
	_drag_offset = global_position - pointer_world   # objek tidak "loncat" ke jari
	z_index = 100
	_stop_idle_animation()
	_animate_scale(DRAG_SCALE, 0.12)
	_mark_input_handled()


func _end_drag() -> void:
	is_dragging = false
	dragging_touch = false
	z_index = 0
	_animate_scale(1.0, 0.15)
	_start_idle_animation()
	_mark_input_handled()
	drag_ended.emit(self)


func _move_to(pointer_world: Vector2) -> void:
	last_pointer_position = pointer_world
	global_position = pointer_world + _drag_offset
	queue_redraw()


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position


func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


# --------------------------------------------------------- PUBLIC API

func activate() -> void:
	if is_collected:
		return
	_pop()
	activated.emit(self)


## Letakkan objek supaya KAKI-nya (bagian bawah sprite) tepat di world_pos.
## Contoh: rabbit.place_feet_at(Vector2(360, 570))
func place_feet_at(world_pos: Vector2) -> void:
	global_position = world_pos - Vector2(0.0, _feet_offset())
	home_position = global_position


## Dipanggil kalau objek diletakkan di tempat yang salah: meluncur pelan ke posisi awal.
func return_home() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", home_position, 0.35)


## Dipanggil kalau objek berhasil dikumpulkan / dibersihkan: pop lalu hilang.
func collect() -> void:
	if is_collected:
		return
	is_collected = true
	set_proximity_highlight(false)
	is_dragging = false
	_stop_idle_animation()
	monitorable = false
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(_set_visual_scale, _visual_scale, 1.35, 0.15)
	tween.chain().tween_method(_set_visual_scale, 1.35, 0.0, 0.2)
	tween.chain().tween_callback(func() -> void: visible = false)


# ------------------------------------------------------- ANIMASI VISUAL

func _on_hover(hovering: bool) -> void:
	if is_collected or is_dragging:
		return
	_animate_scale(HOVER_SCALE if hovering else 1.0, 0.1)


func _pop() -> void:
	var tween := create_tween()
	tween.tween_method(_set_visual_scale, _visual_scale, 1.25, 0.08)
	tween.tween_method(_set_visual_scale, 1.25, 1.0, 0.14)


func _animate_scale(target: float, duration: float) -> void:
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	_scale_tween = create_tween()
	_scale_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_method(_set_visual_scale, _visual_scale, target, duration)


func set_proximity_highlight(enabled: bool) -> void:
	if _proximity_highlighted == enabled:
		return
	_proximity_highlighted = enabled and not is_collected
	if _highlight_tween != null and _highlight_tween.is_running():
		_highlight_tween.kill()
	if _proximity_highlighted:
		_highlight_tween = create_tween().set_loops()
		_highlight_tween.tween_method(_set_highlight_alpha, 0.22, 0.5, 0.65)
		_highlight_tween.tween_method(_set_highlight_alpha, 0.5, 0.22, 0.65)
	else:
		_highlight_alpha = 0.0
	queue_redraw()


func _set_highlight_alpha(value: float) -> void:
	_highlight_alpha = value
	queue_redraw()


func _set_visual_scale(value: float) -> void:
	_visual_scale = value
	if texture_sprite != null:
		texture_sprite.scale = _base_scale * value
	queue_redraw()


func _start_idle_animation() -> void:
	if not idle_animation or is_collected:
		return
	_stop_idle_animation()
	_idle_tween = create_tween().set_loops()
	_idle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_method(_set_visual_scale, 1.0, IDLE_PULSE, 0.9)
	_idle_tween.tween_method(_set_visual_scale, IDLE_PULSE, 1.0, 0.9)


func _stop_idle_animation() -> void:
	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()
	_idle_tween = null


# ------------------------------------------------------------ GAMBAR

## Jarak dari titik tengah objek ke kakinya (bagian bawah sprite).
func _feet_offset() -> float:
	if texture_sprite != null and texture_sprite.texture != null:
		return texture_sprite.texture.get_height() * _base_scale.y * 0.5
	return 30.0   # placeholder bulat: posisi bayangan lama


func _draw() -> void:
	var s := _visual_scale
	var feet := _feet_offset()
	# Bayangan lembut tepat di kaki (makin turun saat diseret = terlihat "terangkat")
	var shadow_y := feet + (8.0 if is_dragging else 0.0)
	var shadow_w := 30.0 if texture_sprite == null else maxf(30.0, feet * 0.6)
	draw_set_transform(Vector2(0, shadow_y), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, shadow_w * s, Color(0, 0, 0, 0.18))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _proximity_highlighted and not is_collected:
		var ring_radius := clampf(_feet_offset() * 0.45, 36.0, 70.0) * s
		draw_arc(Vector2(0, -_feet_offset() * 0.45), ring_radius, 0.0, TAU, 40, Color(1.0, 0.78, 0.24, _highlight_alpha), 4.0, true)
		var prompt := "SERET" if draggable else "E / SENTUH"
		var prompt_size := ThemeDB.fallback_font.get_string_size(prompt, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
		var prompt_rect := Rect2(Vector2(-prompt_size.x * 0.5 - 8.0, -_feet_offset() - 54.0), prompt_size + Vector2(16, 10))
		draw_rect(prompt_rect, Color("fff0cf"), true)
		draw_rect(prompt_rect, Color("b87c2e"), false, 2.0)
		draw_string(ThemeDB.fallback_font, prompt_rect.position + Vector2(8.0, 17.0), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("57351f"))

	if texture_sprite == null:
		# Placeholder bulat berwarna dengan outline & kilau
		draw_circle(Vector2.ZERO, 36.0 * s, Color.WHITE)
		draw_circle(Vector2.ZERO, 32.0 * s, object_color)
		draw_circle(Vector2(-10, -10) * s, 9.0 * s, object_color.lightened(0.3))

	if show_label and not object_label.is_empty():
		_draw_label()


func _draw_label() -> void:
	var font := ThemeDB.fallback_font
	var font_size := 20
	var text_size := font.get_string_size(object_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pill_size := text_size + Vector2(24, 10)
	var pill_pos := Vector2(-pill_size.x * 0.5, maxf(54.0, _feet_offset() + 24.0))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.2, 0.27, 0.82)
	style.set_corner_radius_all(14)
	draw_style_box(style, Rect2(pill_pos, pill_size))
	draw_string(font, pill_pos + Vector2(12, pill_size.y * 0.5 + text_size.y * 0.3),
		object_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
