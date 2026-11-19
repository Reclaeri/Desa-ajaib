extends BaseLevel

var bridge_planks: Array[WorldObject] = []
var bridge_gaps: Array[ColorRect] = []
var bridge_components: Array[WorldObject] = []
var placed: Array[bool] = [false, false, false, false, false, false]


func _mission_window_title() -> String:
	return "JEMBATAN UNTUK SEMUA!"


func _mission_portrait_path() -> String:
	return "res://assets/characters/villagers/deer/deer_16.png"


func _mission_instruction() -> String:
	return "Seret 4 papan dan 2 tali ke tempat yang benar."


func _mission_focus_position() -> Vector2:
	return Vector2(1450, GROUND_BASELINE)


func start_level_mission() -> void:
	MissionManager.start_mission("Jembatan untuk Semua!", 6)
	if hero_mode_enabled():
		return
	var saved := MissionManager.get_level_state()
	if saved.has("placed") and saved["placed"] is Array:
		var restored: Array = saved["placed"]
		for index in mini(restored.size(), placed.size()):
			placed[index] = bool(restored[index])
	mission_npc.set_character_name("Rusa")
	mission_npc.position = Vector2(1150, GROUND_BASELINE)
	var tutu := NpcCharacter.new()
	tutu.character_name = "Tutu"
	tutu.texture_path = "res://assets/characters/tutu/tutu_01.png"
	tutu.position = Vector2(1290, GROUND_BASELINE)
	add_child(tutu)
	var villager_textures := ["res://assets/characters/villagers/deer/deer_01.png", "res://assets/characters/villagers/hedgehog/hedgehog_01.png"]
	for index in villager_textures.size():
		var villager := NpcCharacter.new()
		villager.character_name = "WARGA %d" % (index + 1)
		villager.texture_path = villager_textures[index]
		villager.position = Vector2(1850 + index * 130, GROUND_BASELINE)
		add_child(villager)
	for index in 4:
		if not placed[index]:
			var gap := ColorRect.new()
			gap.color = Color("334b64")
			gap.position = Vector2(1480 + index * 92, 615)
			gap.size = Vector2(82, 18)
			gap.z_index = -1
			add_child(gap)
			bridge_gaps.append(gap)
		var board := WorldObject.new()
		board.object_label = "Papan %d" % (index + 1)
		board.texture_path = "res://assets/objects/bridge/obj_wood_%02d.png" % (index + 1)
		board.draggable = not placed[index]
		board.position = Vector2(1520 + index * 92, 622) if placed[index] else Vector2(1030 + index * 105, OBJECT_CENTER_Y)
		board.draggable = not placed[index]
		if placed[index]:
			board.z_index = 2
		else:
			board.drag_ended.connect(_on_component_dropped.bind(index))
		add_child(board)
		bridge_planks.append(board)
		bridge_components.append(board)
	for index in 2:
		var rope_index := index + 4
		var rope := WorldObject.new()
		rope.object_label = "Tali %d" % (index + 1)
		rope.texture_path = "res://assets/objects/bridge/obj_rope_%02d.png" % (index + 1)
		rope.draggable = not placed[rope_index]
		rope.position = Vector2(1510 + index * 180, 680) if placed[rope_index] else Vector2(1110 + index * 160, OBJECT_CENTER_Y - 40)
		if not placed[rope_index]:
			rope.drag_ended.connect(_on_component_dropped.bind(rope_index))
		add_child(rope)
		bridge_components.append(rope)
	if MissionManager.current_progress == 6:
		backdrop.set_background("res://assets/backgrounds/bg_level_03_river_repaired.png")
	show_notice("Jembatan rusak! Seret papan dan tali ke tempatnya.")


func _on_component_dropped(component: WorldObject, index: int) -> void:
	var target := Vector2.ZERO
	if index < 4:
		target = Vector2(1520 + index * 92, 622)
	else:
		target = Vector2(1510 + (index - 4) * 180, 680)
	if component.global_position.distance_to(target) > 95.0:
		show_notice("Dekatkan komponen ke tempat yang bercahaya.")
		return
	AudioManager.play_sfx(AudioManager.SFX_WOOD_PLANK)
	component.draggable = false
	component.z_index = 2
	var tween := create_tween()
	tween.tween_property(component, "global_position", target, 0.2)
	placed[index] = true
	MissionManager.save_level_state({"placed": placed, "player_x": player.global_position.x})
	MissionManager.advance()
	show_notice("Komponen %d terpasang dengan baik!" % (index + 1))
	if MissionManager.current_progress == 6:
		backdrop.set_background("res://assets/backgrounds/bg_level_03_river_repaired.png")
		for character in get_tree().get_nodes_in_group("mission_characters"):
			if is_instance_valid(character) and character.has_method("play_happy_reaction"):
				character.play_happy_reaction()
		for bridge_gap in bridge_gaps:
			bridge_gap.queue_free()
		for bridge_plank in bridge_planks:
			bridge_plank.hide()
		show_notice("Jembatan kokoh dan warga menyeberang dengan aman! Ketuk keranjang di kanan untuk lanjut.")
