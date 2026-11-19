extends Node

signal tap_requested(screen_position: Vector2)

var touch_direction := 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		tap_requested.emit(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		tap_requested.emit(event.position)


func get_horizontal_movement() -> float:
	var keyboard_direction := Input.get_axis(&"move_left", &"move_right")
	return clampf(keyboard_direction + touch_direction, -1.0, 1.0)


func set_touch_direction(direction: float) -> void:
	touch_direction = clampf(direction, -1.0, 1.0)


func is_interact_pressed() -> bool:
	return Input.is_action_just_pressed(&"interact")


func is_pause_pressed() -> bool:
	return Input.is_action_just_pressed(&"pause")
