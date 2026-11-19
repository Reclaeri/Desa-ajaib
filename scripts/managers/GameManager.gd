extends Node

enum GameState {
	MENU,
	PLAYING,
	DIALOGUE,
	MISSION,
	PAUSED,
	ENDING,
}

signal game_state_changed(new_state: GameState)

var game_state: GameState = GameState.MENU
var state_before_pause: GameState = GameState.PLAYING


func show_main_menu() -> void:
	get_tree().paused = false
	set_game_state(GameState.MENU)


func start_new_game() -> void:
	SaveManager.reset_progress()
	LevelManager._restore_saved_progress()
	open_level(LevelManager.get_first_level_id())


func continue_game() -> void:
	open_level(LevelManager.get_resume_level_id())


func open_level(level_id: StringName) -> void:
	if LevelManager.open_level(level_id):
		set_game_state(GameState.PLAYING)


func start_mission() -> void:
	set_game_state(GameState.MISSION)


func show_dialogue() -> void:
	set_game_state(GameState.DIALOGUE)


func resume_gameplay() -> void:
	set_game_state(GameState.PLAYING)


func toggle_pause() -> void:
	if game_state == GameState.PAUSED:
		get_tree().paused = false
		set_game_state(state_before_pause)
		return
	state_before_pause = game_state
	get_tree().paused = true
	set_game_state(GameState.PAUSED)


func show_ending() -> void:
	set_game_state(GameState.ENDING)


func set_game_state(new_state: GameState) -> void:
	if game_state == new_state:
		return
	game_state = new_state
	game_state_changed.emit(game_state)
