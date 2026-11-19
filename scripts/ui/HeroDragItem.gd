class_name HeroDragItem
extends TextureRect

signal drag_finished(item: HeroDragItem)

var home_position := Vector2.ZERO
var drag_bounds := Rect2(0, 0, 1280, 720)
var dragging := false
var locked := false
var touch_dragging := false


func setup(bounds: Rect2) -> void:
	drag_bounds = bounds
	home_position = position
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			touch_dragging = false
			z_index = 20
			accept_event()
		else:
			_finish_drag()
	elif event is InputEventMouseMotion and dragging:
		_move_to_pointer(get_global_mouse_position())
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		dragging = true
		touch_dragging = true
		z_index = 20
		accept_event()
	elif event is InputEventScreenDrag and dragging:
		_move_to_pointer(event.position)
		accept_event()
	elif event is InputEventScreenTouch and not event.pressed:
		_finish_drag()


func _process(_delta: float) -> void:
	if not dragging or touch_dragging:
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_move_to_pointer(get_global_mouse_position())
	else:
		_finish_drag()


func _move_to_pointer(pointer: Vector2) -> void:
	var parent_control: Control = get_parent() as Control
	if parent_control == null:
		return
	var local_pointer: Vector2 = pointer - parent_control.global_position
	var next: Vector2 = local_pointer - (size * 0.5)
	position = Vector2(
		clampf(next.x, drag_bounds.position.x, drag_bounds.end.x - size.x),
		clampf(next.y, drag_bounds.position.y, drag_bounds.end.y - size.y)
	)


func _finish_drag() -> void:
	if not dragging:
		return
	dragging = false
	z_index = 10
	drag_finished.emit(self)


func return_home() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", home_position, 0.22)
