extends Node

signal level_unlocked(level_id: StringName)
signal level_completed(level_id: StringName)
signal current_level_changed(level_id: StringName)

const LEVEL_ORDER := [&"level_1", &"level_2", &"level_3", &"level_4", &"level_5"]
const LEVEL_SCENES := {
	&"level_1": "res://scenes/levels/level_1/Level1.tscn",
	&"level_2": "res://scenes/levels/level_2/Level2.tscn",
	&"level_3": "res://scenes/levels/level_3/Level3.tscn",
	&"level_4": "res://scenes/levels/level_4/Level4.tscn",
	&"level_5": "res://scenes/levels/level_5/Level5.tscn",
}
const ENDING_SCENE := "res://scenes/ending/Ending.tscn"

var current_level_id: StringName = &""
var unlocked_level_ids: Array[StringName] = [&"level_1"]
var completed_level_ids: Array[StringName] = []
var helped_level_ids: Array[StringName] = []
var scene_change_pending := false
var help_action_count := 0
const TOTAL_HELP_ACTIONS := 31


func _ready() -> void:
	_restore_saved_progress()


func get_first_level_id() -> StringName:
	return LEVEL_ORDER[0]


func get_resume_level_id() -> StringName:
	var saved_level := StringName(SaveManager.get_last_open_level())
	if is_level_unlocked(saved_level) and not is_level_completed(saved_level):
		return saved_level
	for level_id: StringName in LEVEL_ORDER:
		if is_level_unlocked(level_id) and not is_level_completed(level_id):
			return level_id
	return get_first_level_id()


func set_current_level(level_id: StringName) -> bool:
	if not is_level_unlocked(level_id):
		return false
	current_level_id = level_id
	SaveManager.set_last_open_level(level_id)
	current_level_changed.emit(level_id)
	return true


func open_level(level_id: StringName) -> bool:
	var scene_path: String = LEVEL_SCENES.get(level_id, "")
	if scene_path.is_empty() or not is_level_unlocked(level_id):
		return false
	set_current_level(level_id)
	_change_scene_deferred(scene_path)
	return true


func open_next_level() -> void:
	var next_level := get_next_level_id(current_level_id)
	if next_level == &"":
		SaveManager.set_all_levels_completed(true)
		_change_scene_deferred(ENDING_SCENE)
		return
	open_level(next_level)


func _change_scene_deferred(scene_path: String) -> void:
	if scene_change_pending:
		return
	scene_change_pending = true
	call_deferred("_perform_scene_change", scene_path)


func _perform_scene_change(scene_path: String) -> void:
	var transition_layer := CanvasLayer.new()
	transition_layer.layer = 100
	var fade := ColorRect.new()
	fade.color = Color(0.04, 0.07, 0.08, 0.0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	transition_layer.add_child(fade)
	get_tree().root.add_child(transition_layer)
	var fade_in := create_tween()
	fade_in.tween_property(fade, "color:a", 1.0, 0.22)
	await fade_in.finished
	if get_tree().change_scene_to_file(scene_path) != OK:
		push_error("Gagal berpindah scene: %s" % scene_path)
		scene_change_pending = false
		transition_layer.queue_free()
		return
	await get_tree().process_frame
	var fade_out := create_tween()
	fade_out.tween_property(fade, "color:a", 0.0, 0.28)
	await fade_out.finished
	transition_layer.queue_free()
	scene_change_pending = false


func is_level_unlocked(level_id: StringName) -> bool:
	return level_id in unlocked_level_ids


func is_level_completed(level_id: StringName) -> bool:
	return level_id in completed_level_ids


func unlock_level(level_id: StringName) -> void:
	if is_level_unlocked(level_id):
		return
	unlocked_level_ids.append(level_id)
	SaveManager.set_unlocked_levels(unlocked_level_ids)
	level_unlocked.emit(level_id)


func complete_current_level() -> void:
	if current_level_id == &"" or is_level_completed(current_level_id):
		return
	completed_level_ids.append(current_level_id)
	SaveManager.set_completed_levels(completed_level_ids)
	level_completed.emit(current_level_id)
	var next_level := get_next_level_id(current_level_id)
	if next_level != &"":
		unlock_level(next_level)
		SaveManager.set_last_open_level(next_level)


func get_next_level_id(level_id: StringName) -> StringName:
	var level_index := LEVEL_ORDER.find(level_id)
	if level_index < 0 or level_index >= LEVEL_ORDER.size() - 1:
		return &""
	return LEVEL_ORDER[level_index + 1]


func _restore_saved_progress() -> void:
	unlocked_level_ids.clear()
	for level_id: Variant in SaveManager.get_unlocked_levels():
		unlocked_level_ids.append(StringName(level_id))
	if unlocked_level_ids.is_empty():
		unlocked_level_ids.append(get_first_level_id())
	completed_level_ids.clear()
	for level_id: Variant in SaveManager.get_completed_levels():
		completed_level_ids.append(StringName(level_id))
	helped_level_ids.clear()
	for level_id: Variant in SaveManager.get_helped_levels():
		helped_level_ids.append(StringName(level_id))
	help_action_count = SaveManager.get_help_actions()


func register_help_action(amount: int = 1) -> void:
	help_action_count = clampi(help_action_count + amount, 0, TOTAL_HELP_ACTIONS)
	SaveManager.set_help_actions(help_action_count)


func register_level_helped(level_id: StringName) -> void:
	if level_id == &"" or level_id in helped_level_ids:
		return
	helped_level_ids.append(level_id)
	SaveManager.set_helped_levels(helped_level_ids)


func get_rating_stars() -> int:
	var helped_count := helped_level_ids.size()
	if helped_count >= LEVEL_ORDER.size():
		return 3
	if helped_count >= 3:
		return 2
	return 1
