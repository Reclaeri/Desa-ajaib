extends Node

signal mission_started(title: String, target: int)
signal mission_progress_changed(current: int, target: int)
signal mission_completed

var mission_title := ""
var current_progress := 0
var target_progress := 0
var active := false
var checkpoint_level_id := ""


func _ready() -> void:
	var checkpoint := SaveManager.get_mission_checkpoint()
	checkpoint_level_id = str(checkpoint.get("level_id", ""))


func start_mission(title: String, target: int) -> void:
	mission_title = title
	target_progress = target
	var checkpoint := SaveManager.get_mission_checkpoint()
	if str(checkpoint.get("level_id", "")) == String(LevelManager.current_level_id) and str(checkpoint.get("title", "")) == title and int(checkpoint.get("target", -1)) == target:
		current_progress = clampi(int(checkpoint.get("progress", 0)), 0, target)
	else:
		current_progress = 0
		checkpoint = {"level_id": String(LevelManager.current_level_id), "title": title, "target": target, "progress": 0}
		SaveManager.set_mission_checkpoint(checkpoint)
	checkpoint_level_id = String(LevelManager.current_level_id)
	active = true
	GameManager.start_mission()
	mission_started.emit(mission_title, target_progress)
	if current_progress > 0:
		mission_progress_changed.emit(current_progress, target_progress)


func advance(amount := 1) -> void:
	if not active:
		return
	current_progress = mini(current_progress + amount, target_progress)
	var checkpoint := SaveManager.get_mission_checkpoint()
	checkpoint["level_id"] = String(LevelManager.current_level_id)
	checkpoint["title"] = mission_title
	checkpoint["target"] = target_progress
	checkpoint["progress"] = current_progress
	SaveManager.set_mission_checkpoint(checkpoint)
	mission_progress_changed.emit(current_progress, target_progress)
	if current_progress >= target_progress:
		active = false
		SaveManager.clear_mission_checkpoint()
		checkpoint_level_id = ""
		mission_completed.emit()


func save_level_state(state: Dictionary) -> void:
	var checkpoint := SaveManager.get_mission_checkpoint()
	checkpoint["level_id"] = String(LevelManager.current_level_id)
	checkpoint["title"] = mission_title
	checkpoint["target"] = target_progress
	checkpoint["progress"] = current_progress
	checkpoint["state"] = state.duplicate(true)
	SaveManager.set_mission_checkpoint(checkpoint)


func get_level_state() -> Dictionary:
	var checkpoint := SaveManager.get_mission_checkpoint()
	if str(checkpoint.get("level_id", "")) != String(LevelManager.current_level_id):
		return {}
	var state: Variant = checkpoint.get("state", {})
	return state.duplicate(true) if state is Dictionary else {}


func mission_status(level_id: StringName) -> String:
	if LevelManager.is_level_completed(level_id):
		return "completed"
	if str(SaveManager.get_mission_checkpoint().get("level_id", "")) == String(level_id):
		return "in_progress"
	return "not_started"


func cancel_mission() -> void:
	active = false
	GameManager.resume_gameplay()
