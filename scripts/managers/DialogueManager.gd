extends Node

signal dialogue_requested(speaker: String, message: String, accept_text: String, decline_text: String)
signal choice_made(accepted: bool)

var is_open := false


func show_choice(speaker: String, message: String, accept_text := "YA, BANTU!", decline_text := "TIDAK SEKARANG") -> void:
	is_open = true
	GameManager.show_dialogue()
	dialogue_requested.emit(speaker, message, accept_text, decline_text)


func choose(accepted: bool) -> void:
	if not is_open:
		return
	is_open = false
	choice_made.emit(accepted)
	GameManager.resume_gameplay()
