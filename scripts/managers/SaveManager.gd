extends Node

signal progress_loaded
signal progress_saved

const SAVE_PATH := "user://desa_ajaib_progress.save"
const SAVE_VERSION := 2
const VALID_LEVELS := ["level_1", "level_2", "level_3", "level_4", "level_5"]

var _progress: Dictionary = {
	"save_version": SAVE_VERSION,
	"has_game_progress": false,
	"last_open_level": "level_1",
	"unlocked_levels": ["level_1"],
	"completed_levels": [],
	"helped_levels": [],
	"all_levels_completed": false,
	"help_actions": 0,
	"mission_checkpoint": {},
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 0.8,
	"voice_volume": 0.8,
}
var _save_valid := false


func _ready() -> void:
	load_progress()


func has_saved_progress() -> bool:
	return _save_valid and bool(_progress.get("has_game_progress", false)) and (FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SAVE_PATH + ".bak"))


func load_progress() -> void:
	_save_valid = false
	if not FileAccess.file_exists(SAVE_PATH) and not FileAccess.file_exists(SAVE_PATH + ".bak"):
		progress_loaded.emit()
		return
	var loaded_data := _read_save_file(SAVE_PATH)
	if loaded_data.is_empty():
		var backup_path := SAVE_PATH + ".bak"
		loaded_data = _read_save_file(backup_path)
		if not loaded_data.is_empty():
			push_warning("Save utama rusak; memulihkan dari backup.")
	if loaded_data.is_empty():
		push_warning("Data save tidak valid. Game dimulai dengan progres default.")
		progress_loaded.emit()
		return
	_progress = _sanitize_progress(loaded_data)
	_save_valid = true
	progress_loaded.emit()


func reset_progress() -> void:
	_progress["has_game_progress"] = true
	_progress["last_open_level"] = "level_1"
	_progress["unlocked_levels"] = ["level_1"]
	_progress["completed_levels"] = []
	_progress["helped_levels"] = []
	_progress["all_levels_completed"] = false
	_progress["help_actions"] = 0
	_progress["mission_checkpoint"] = {}
	save_progress()


func save_progress() -> void:
	_progress["save_version"] = SAVE_VERSION
	var temp_path := SAVE_PATH + ".tmp"
	var temp_file := FileAccess.open(temp_path, FileAccess.WRITE)
	if temp_file == null:
		push_error("Gagal membuat file save sementara: %s" % error_string(FileAccess.get_open_error()))
		return
	temp_file.store_string(JSON.stringify(_progress))
	temp_file.close()
	var absolute_save_path := ProjectSettings.globalize_path(SAVE_PATH)
	var absolute_temp_path := ProjectSettings.globalize_path(temp_path)
	var absolute_backup_path := ProjectSettings.globalize_path(SAVE_PATH + ".bak")
	if FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists(SAVE_PATH + ".bak"):
			DirAccess.remove_absolute(absolute_backup_path)
		var backup_error := DirAccess.rename_absolute(absolute_save_path, absolute_backup_path)
		if backup_error != OK:
			push_error("Gagal mengamankan save lama: %s" % error_string(backup_error))
			return
	var replace_error := DirAccess.rename_absolute(absolute_temp_path, absolute_save_path)
	if replace_error != OK:
		if FileAccess.file_exists(SAVE_PATH + ".bak"):
			DirAccess.rename_absolute(absolute_backup_path, absolute_save_path)
		push_error("Gagal mengganti file save: %s" % error_string(replace_error))
		return
	if FileAccess.file_exists(SAVE_PATH + ".bak"):
		DirAccess.remove_absolute(absolute_backup_path)
	_save_valid = true
	progress_saved.emit()


func _read_save_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var save_file := FileAccess.open(path, FileAccess.READ)
	if save_file == null:
		return {}
	var json := JSON.new()
	if json.parse(save_file.get_as_text()) != OK or not json.data is Dictionary:
		return {}
	return json.data


func _sanitize_progress(data: Dictionary) -> Dictionary:
	var clean := _progress.duplicate(true)
	clean["has_game_progress"] = bool(data.get("has_game_progress", true))
	var last_level := str(data.get("last_open_level", "level_1"))
	if last_level in VALID_LEVELS:
		clean["last_open_level"] = last_level
	var unlocked: Array[String] = ["level_1"]
	var raw_unlocked: Variant = data.get("unlocked_levels", ["level_1"])
	if raw_unlocked is Array:
		for level_id: Variant in raw_unlocked:
			var level_text := str(level_id)
			if level_text in VALID_LEVELS and not level_text in unlocked:
				unlocked.append(level_text)
	clean["unlocked_levels"] = unlocked
	var completed: Array[String] = []
	var raw_completed: Variant = data.get("completed_levels", [])
	if raw_completed is Array:
		for level_id: Variant in raw_completed:
			var level_text := str(level_id)
			if level_text in VALID_LEVELS and not level_text in completed:
				completed.append(level_text)
	clean["completed_levels"] = completed
	var helped: Array[String] = []
	var raw_helped: Variant = data.get("helped_levels", [])
	if raw_helped is Array:
		for level_id: Variant in raw_helped:
			var level_text := str(level_id)
			if level_text in VALID_LEVELS and not level_text in helped:
				helped.append(level_text)
	clean["helped_levels"] = helped
	clean["all_levels_completed"] = bool(data.get("all_levels_completed", false))
	clean["help_actions"] = maxi(0, int(data.get("help_actions", 0)))
	var raw_checkpoint: Variant = data.get("mission_checkpoint", {})
	if raw_checkpoint is Dictionary and str(raw_checkpoint.get("level_id", "")) in VALID_LEVELS:
		clean["mission_checkpoint"] = raw_checkpoint.duplicate(true)
	for setting in ["master_volume", "music_volume", "sfx_volume", "voice_volume"]:
		var raw_volume: Variant = data.get(setting, clean[setting])
		if raw_volume is int or raw_volume is float:
			clean[setting] = clampf(float(raw_volume), 0.0, 1.0)
	return clean


func get_last_open_level() -> String:
	return str(_progress.get("last_open_level", "level_1"))


func set_last_open_level(level_id: StringName) -> void:
	_progress["last_open_level"] = String(level_id)
	_progress["has_game_progress"] = true
	save_progress()


func get_unlocked_levels() -> Array:
	var levels: Array = _progress.get("unlocked_levels", ["level_1"])
	return levels.duplicate()


func set_unlocked_levels(level_ids: Array[StringName]) -> void:
	var serialized_levels: Array[String] = []
	for level_id: StringName in level_ids:
		serialized_levels.append(String(level_id))
	_progress["unlocked_levels"] = serialized_levels
	save_progress()


func get_completed_levels() -> Array:
	var levels: Array = _progress.get("completed_levels", [])
	return levels.duplicate()


func set_completed_levels(level_ids: Array[StringName]) -> void:
	var serialized_levels: Array[String] = []
	for level_id: StringName in level_ids:
		serialized_levels.append(String(level_id))
	_progress["completed_levels"] = serialized_levels
	save_progress()


func get_helped_levels() -> Array:
	var levels: Array = _progress.get("helped_levels", [])
	return levels.duplicate()


func set_helped_levels(level_ids: Array[StringName]) -> void:
	var serialized_levels: Array[String] = []
	for level_id: StringName in level_ids:
		serialized_levels.append(String(level_id))
	_progress["helped_levels"] = serialized_levels
	save_progress()


func are_all_levels_completed() -> bool:
	return bool(_progress.get("all_levels_completed", false))


func set_all_levels_completed(completed: bool) -> void:
	_progress["all_levels_completed"] = completed
	save_progress()


func get_help_actions() -> int:
	return int(_progress.get("help_actions", 0))


func set_help_actions(value: int) -> void:
	_progress["help_actions"] = maxi(0, value)
	save_progress()


func get_mission_checkpoint() -> Dictionary:
	var checkpoint: Variant = _progress.get("mission_checkpoint", {})
	return checkpoint.duplicate(true) if checkpoint is Dictionary else {}


func set_mission_checkpoint(checkpoint: Dictionary) -> void:
	_progress["mission_checkpoint"] = checkpoint.duplicate(true)
	_progress["has_game_progress"] = true
	save_progress()


func clear_mission_checkpoint() -> void:
	_progress["mission_checkpoint"] = {}
	save_progress()


func get_volume(setting_name: String, default_value: float = 0.8) -> float:
	return float(_progress.get(setting_name, default_value))


func set_volume(setting_name: String, volume: float) -> void:
	_progress[setting_name] = clampf(volume, 0.0, 1.0)
	save_progress()
