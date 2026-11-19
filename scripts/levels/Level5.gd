extends BaseLevel

var bin_marker: WorldObject
var cleaning_phase := 0
var watering_can_collected := false


func _mission_window_title() -> String:
	return "MENGHIDUPKAN KEMBALI TAMAN!"


func _mission_portrait_path() -> String:
	return "res://assets/characters/tutu/tutu_16.png"


func _mission_instruction() -> String:
	if hero_mode_enabled():
		if MissionManager.current_progress < 3:
			return "Tahap 1/3: tanam tiga bibit di petak yang sesuai."
		if MissionManager.current_progress < 6:
			return "Tahap 2/3: siram setiap bibit yang sudah ditanam."
		return "Tahap 3/3: letakkan bunga untuk menghidupkan taman."
	if cleaning_phase == 0:
		return "Tahap 1: bersihkan sampah dan bawa ke keranjang."
	if cleaning_phase == 1:
		return "Tahap 2: dekati lalu kumpulkan ranting kering."
	return "Tahap 3: ambil penyiram, lalu siram semua tanaman."


func _ready() -> void:
	super()
	var momo := NpcCharacter.new()
	momo.character_name = "Momo"
	momo.body_color = Color("ed6d33")
	momo.texture_path = "res://assets/characters/momo/momo_01.png"
	momo.position = Vector2(680, GROUND_BASELINE)
	add_child(momo)
	mission_npc.set_character_name("Tutu")
	mission_npc.set_character_texture("res://assets/characters/tutu/tutu_01.png")


func _on_mission_progress(current: int, target: int) -> void:
	super(current, target)
	mission_instruction_label.text = _mission_instruction()


func _update_mission_window_progress() -> void:
	super()
	if mission_progress_label != null:
		mission_progress_label.text = "Tahap %d/3 | %d/%d" % [mini(cleaning_phase + 1, 3), MissionManager.current_progress, MissionManager.target_progress]


func start_level_mission() -> void:
	MissionManager.start_mission("Menghidupkan Kembali Taman!", 9)
	if hero_mode_enabled():
		return
	var saved := MissionManager.get_level_state()
	cleaning_phase = 0 if MissionManager.current_progress < 3 else 1 if MissionManager.current_progress < 6 else 2
	watering_can_collected = bool(saved.get("watering_can_collected", MissionManager.current_progress >= 7))
	if cleaning_phase == 0:
		_spawn_trash_phase()
	elif cleaning_phase == 1:
		_spawn_branches_phase()
	else:
		_spawn_watering_phase()
	show_notice(_mission_instruction())


func _spawn_trash_phase() -> void:
	bin_marker = WorldObject.new()
	bin_marker.object_label = "Keranjang sampah"
	bin_marker.texture_path = "res://assets/objects/mission/obj_basket_01.png"
	bin_marker.position = Vector2(860, OBJECT_CENTER_Y)
	add_child(bin_marker)
	for index in range(MissionManager.current_progress, 3):
		var trash := WorldObject.new()
		trash.object_label = "Sampah"
		trash.object_color = Color("a8a39a")
		trash.texture_path = "res://assets/objects/garden/obj_trash_%02d.png" % (index + 1)
		trash.draggable = true
		trash.position = Vector2(390 + index * 130, OBJECT_CENTER_Y)
		trash.drag_ended.connect(_on_trash_dropped)
		add_child(trash)


func _on_trash_dropped(trash: WorldObject) -> void:
	if trash.global_position.distance_to(bin_marker.global_position) <= 100.0:
		AudioManager.play_sfx(AudioManager.SFX_CLEAN_SPARKLE)
		trash.draggable = false
		var tween := create_tween()
		tween.tween_property(trash, "global_position", bin_marker.global_position, 0.25)
		tween.tween_callback(_finish_trash_drop.bind(trash))
	else:
		show_notice("Bawa sampah ke keranjang pengumpulan.")


func _finish_trash_drop(trash: WorldObject) -> void:
	trash.queue_free()
	MissionManager.advance()
	if MissionManager.current_progress == 3:
		cleaning_phase = 1
		_spawn_branches_phase()
		mission_instruction_label.text = _mission_instruction()
		_update_mission_window_progress()
		show_notice("Bagian A selesai! Bagian B: dekati dan kumpulkan tiga ranting.")


func _spawn_branches_phase() -> void:
	if is_instance_valid(bin_marker):
		bin_marker.queue_free()
	for index in range(MissionManager.current_progress - 3, 3):
		var branch := WorldObject.new()
		branch.object_label = "Ranting"
		branch.object_color = Color("936740")
		branch.texture_path = "res://assets/objects/garden/obj_dry_branch_01.png"
		branch.position = Vector2(470 + index * 150, OBJECT_CENTER_Y)
		branch.activated.connect(_on_branch_collected)
		add_interactable(branch)


func _on_branch_collected(branch: WorldObject) -> void:
	if player.global_position.distance_to(branch.global_position) > 120.0:
		show_notice("Dekati ranting sebelum mengumpulkannya.")
		return
	AudioManager.play_sfx(AudioManager.SFX_CLEAN_SPARKLE)
	branch.queue_free()
	MissionManager.save_level_state({"player_x": player.global_position.x, "watering_can_collected": false})
	MissionManager.advance()
	if MissionManager.current_progress == 6:
		cleaning_phase = 2
		_spawn_watering_phase()
		mission_instruction_label.text = _mission_instruction()
		_update_mission_window_progress()
		show_notice("Bagian C: ambil penyiram lalu siram semua tanaman layu.")


func _spawn_watering_phase() -> void:
	if not watering_can_collected:
		var watering_can := WorldObject.new()
		watering_can.object_label = "Penyiram"
		watering_can.object_color = Color("5d9ee8")
		watering_can.texture_path = "res://assets/objects/garden/obj_watering_can_01.png"
		watering_can.position = Vector2(600, OBJECT_CENTER_Y)
		watering_can.activated.connect(_on_watering_can_collected)
		add_interactable(watering_can)
	else:
		_spawn_remaining_plants()


func _spawn_remaining_plants() -> void:
	for index in range(maxi(MissionManager.current_progress - 6, 0), 3):
		var plant := WorldObject.new()
		plant.object_label = "Tanaman Layu"
		plant.object_color = Color("a8b35b")
		plant.texture_path = "res://assets/objects/decorations/decor_bush_01.png"
		plant.position = Vector2(720 + index * 135, OBJECT_CENTER_Y)
		plant.activated.connect(_on_plant_watered)
		add_interactable(plant)


func _on_watering_can_collected(watering_can: WorldObject) -> void:
	if player.global_position.distance_to(watering_can.global_position) > 120.0:
		show_notice("Dekati penyiram sebelum mengambilnya.")
		return
	AudioManager.play_sfx(AudioManager.SFX_WATER_SPLASH)
	watering_can_collected = true
	watering_can.queue_free()
	MissionManager.save_level_state({"player_x": player.global_position.x, "watering_can_collected": true})
	show_notice("Penyiram siap! Dekati setiap tanaman lalu tekan E atau sentuh tanaman.")
	_spawn_remaining_plants()


func _on_plant_watered(plant: WorldObject) -> void:
	if player.global_position.distance_to(plant.global_position) > 120.0:
		show_notice("Dekati tanaman sebelum menyiraminya.")
		return
	if not watering_can_collected:
		show_notice("Ambil penyiram sebelum menyirami tanaman.")
		return
	AudioManager.play_sfx(AudioManager.SFX_WATER_SPLASH)
	plant.queue_free()
	MissionManager.save_level_state({"player_x": player.global_position.x, "watering_can_collected": true})
	MissionManager.advance()
	if MissionManager.current_progress >= MissionManager.target_progress:
		show_notice("Taman kembali asri! Semua sahabat berkumpul merayakan kebaikanmu.")
	else:
		show_notice("Tanaman tersiram dan mulai berbunga!")
