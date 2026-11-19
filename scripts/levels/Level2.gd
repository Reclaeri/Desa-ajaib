extends BaseLevel

var tutu: NpcCharacter
var lili_count := 0
var tutu_count := 0
var strawberry_label: Label


func _mission_window_title() -> String:
	return "BERBAGI ITU INDAH!"


func _mission_portrait_path() -> String:
	return "res://assets/characters/momo/momo_18.png"


func _mission_instruction() -> String:
	return "Seret stroberi kepada Lili dan Tutu. Bagikan tiga stroberi untuk masing-masing!"


func _ready() -> void:
	super()
	tutu = NpcCharacter.new()
	tutu.character_name = "Tutu"
	tutu.texture_path = "res://assets/characters/tutu/tutu_01.png"
	tutu.position = Vector2(1010, GROUND_BASELINE)
	add_child(tutu)
	mission_npc.position = Vector2(740, GROUND_BASELINE)
	mission_npc.texture_path = "res://assets/characters/momo/momo_01.png"
	mission_npc.character_name = "Momo"
	# Replace the sprite texture loaded during the base scene build with Momo.
	if mission_npc.texture_sprite != null:
		mission_npc.texture_sprite.texture = load(mission_npc.texture_path)


func start_level_mission() -> void:
	MissionManager.start_mission("Berbagi Itu Indah!", 6)
	if hero_mode_enabled():
		return
	var state := MissionManager.get_level_state()
	lili_count = clampi(int(state.get("lili_count", 0)), 0, 3)
	tutu_count = clampi(int(state.get("tutu_count", 0)), 0, 3)
	var spawned := 0
	for index in 6:
		if (index % 2 == 0 and index / 2 < lili_count) or (index % 2 == 1 and index / 2 < tutu_count):
			continue
		var strawberry := WorldObject.new()
		strawberry.object_label = "Stroberi"
		strawberry.texture_path = "res://assets/objects/food/obj_strawberry_%02d.png" % (index % 3 + 1)
		strawberry.draggable = true
		strawberry.position = Vector2(450 + spawned * 76, OBJECT_CENTER_Y)
		spawned += 1
		strawberry.drag_ended.connect(_on_strawberry_dropped)
		add_child(strawberry)
	show_notice("Seret stroberi langsung ke tangan Lili atau Tutu. Bagikan 3 untuk masing-masing!")
	mission_progress_label.text = "Lili %d/3 berbagi  •  Tutu %d/3 berbagi" % [lili_count, tutu_count]
	mission_label.text = "Lili: %d/3     Tutu: %d/3" % [lili_count, tutu_count]


func _on_strawberry_dropped(strawberry: WorldObject) -> void:
	var d_lili := strawberry.global_position.distance_to(player.global_position + Vector2(28, -88))
	var d_tutu := strawberry.global_position.distance_to(tutu.global_position + Vector2(-24, -78))
	if minf(d_lili, d_tutu) > 115.0:
		show_notice("Dekatkan stroberi ke tangan temanmu.")
		return
	if d_lili <= d_tutu:
		if lili_count >= 3:
			show_notice("Lili sudah mendapat tiga stroberi. Tutu masih menunggu!")
			return
		lili_count += 1
		player.get_node("Visuals").scale = Vector2(1.06, 1.06)
	else:
		if tutu_count >= 3:
			show_notice("Tutu sudah mendapat tiga stroberi. Bagikan kepada Lili!")
			return
		tutu_count += 1
		tutu.set_sad(false)
		tutu.play_happy_reaction()
	MissionManager.save_level_state({"lili_count": lili_count, "tutu_count": tutu_count, "player_x": player.global_position.x})
	AudioManager.play_sfx(AudioManager.SFX_STRAWBERRY)
	strawberry.draggable = false
	var recipient := player.global_position + Vector2(28, -88) if d_lili <= d_tutu else tutu.global_position + Vector2(-24, -78)
	var tween := create_tween()
	tween.tween_property(strawberry, "global_position", recipient, 0.28)
	tween.tween_callback(strawberry.queue_free)
	MissionManager.advance()
	mission_label.text = "Lili: %d/3     Tutu: %d/3" % [lili_count, tutu_count]
	mission_progress_label.text = "Lili %d/3  •  Tutu %d/3" % [lili_count, tutu_count]
	show_notice("Terima kasih! Lili dan Tutu senang berbagi bersama.")
	if lili_count == 3 and tutu_count == 3:
		show_notice("Semua stroberi terbagi rata! Ketiga sahabat menikmati bekal bersama. Ketuk keranjang di kanan untuk lanjut.")
