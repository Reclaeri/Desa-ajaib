extends BaseLevel

var basket: WorldObject
var carrying_basket := false


func start_level_mission() -> void:
	MissionManager.start_mission("Temukan keranjang Tutu", 1)
	var state := MissionManager.get_level_state()
	carrying_basket = bool(state.get("carrying_basket", false))
	if carrying_basket:
		return
	basket = WorldObject.new()
	basket.object_label = "Keranjang Buah"
	basket.object_color = Color("d78d45")
	basket.texture_path = "res://assets/objects/mission/obj_basket_01.png"
	basket.position = Vector2(1640, OBJECT_CENTER_Y)
	basket.activated.connect(_on_basket_activated)
	add_interactable(basket)
	show_notice("Cari keranjang di hutan, lalu bawa kembali kepada Tutu.")


func _on_basket_activated(world_object: WorldObject) -> void:
	if player.global_position.distance_to(world_object.global_position) > 105.0:
		show_notice("Lili harus mendekati keranjang terlebih dahulu.")
		return
	carrying_basket = true
	world_object.queue_free()
	MissionManager.save_level_state({"carrying_basket": true, "player_x": player.global_position.x})
	show_notice("Keranjang didapat! Kembali ke Tutu.")


func _update_mission() -> void:
	if carrying_basket and player.global_position.distance_to(mission_npc.global_position) < 115.0:
		carrying_basket = false
		mission_npc.play_happy_reaction()
		LevelManager.register_help_action()
		MissionManager.advance()
		show_notice("Tutu tersenyum senang. Terima kasih, Lili! Ketuk keranjang di kanan untuk lanjut.")
