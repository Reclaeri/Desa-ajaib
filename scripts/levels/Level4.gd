extends BaseLevel

var citizens: Array[NpcCharacter] = []
var served: Array[bool] = []
var foods: Array[WorldObject] = []
var decorations: Array[WorldObject] = []
var decorations_placed := 0


func _mission_window_title() -> String:
	return "PERSIAPAN PESTA KEBUN!"


func _mission_instruction() -> String:
	return "Bagikan bekal kepada lima warga, lalu pasang empat perlengkapan pesta."


func _mission_portrait_path() -> String:
	return "res://assets/characters/momo/momo_18.png"


func _ready() -> void:
	super()
	mission_npc.position = Vector2(455, GROUND_BASELINE)

const CITIZEN_SPRITES := [
	"res://assets/characters/villagers/deer/deer_01.png",
	"res://assets/characters/villagers/hedgehog/hedgehog_01.png",
	"res://assets/characters/villagers/squirrel/squirrel_01.png",
	"res://assets/characters/villagers/rabbit/rabbit_villager_01.png",
	"res://assets/characters/villagers/bird/bird_01.png",
]
const FOOD_SPRITES := [
	"res://assets/objects/food/obj_cake_01.png",
	"res://assets/objects/food/obj_bread_01.png",
	"res://assets/objects/food/obj_fruit_01.png",
	"res://assets/objects/drinks/obj_juice_01.png",
	"res://assets/objects/food/obj_bread_01.png",
]


func start_level_mission() -> void:
	MissionManager.start_mission("Persiapan Pesta Kebun!", CITIZEN_SPRITES.size() + 4)
	if hero_mode_enabled():
		return
	served.resize(CITIZEN_SPRITES.size())
	served.fill(false)
	var saved := MissionManager.get_level_state()
	if saved.has("served") and saved["served"] is Array:
		served.assign(saved["served"])
	else:
		served.fill(false)
	decorations_placed = clampi(int(saved.get("decorations_placed", 0)), 0, 4)
	var tutu := NpcCharacter.new()
	tutu.character_name = "Tutu"
	tutu.texture_path = "res://assets/characters/tutu/tutu_01.png"
	tutu.position = Vector2(300, GROUND_BASELINE)
	add_child(tutu)
	for index in CITIZEN_SPRITES.size():
		var citizen := NpcCharacter.new()
		citizen.character_name = ["Rusa", "Landak", "Tupai", "Kelinci Kecil", "Burung"][index]
		citizen.texture_path = CITIZEN_SPRITES[index]
		citizen.position = Vector2(620 + index * 145, GROUND_BASELINE)
		citizens.append(citizen)
		add_child(citizen)
		if served[index]:
			continue
		var food := WorldObject.new()
		food.object_label = "Bekal"
		food.texture_path = FOOD_SPRITES[index]
		food.draggable = true
		food.position = Vector2(470 + index * 52, OBJECT_CENTER_Y)
		food.drag_ended.connect(_on_food_dropped.bind(index))
		foods.append(food)
		add_child(food)
	_spawn_decorations()
	mission_label.text = "Warga bahagia: %d/%d" % [MissionManager.current_progress, citizens.size()]
	show_notice("Pesta panen dimulai! Seret kue dan bekal langsung kepada setiap warga.")


func _on_food_dropped(food: WorldObject, food_index: int) -> void:
	var nearest := -1
	var best_distance := INF
	for index in citizens.size():
		var distance: float = food.global_position.distance_to(citizens[index].global_position + Vector2(0, -70))
		if distance < best_distance:
			best_distance = distance
			nearest = index
	if nearest < 0 or best_distance > 115.0:
		show_notice("Dekatkan bekal ke warga yang sedang menunggu.")
		return
	if served[nearest]:
		show_notice("Warga ini sudah mendapat bekal. Coba warga berikutnya!")
		return
	AudioManager.play_sfx(AudioManager.SFX_STRAWBERRY)
	citizens[nearest].play_happy_reaction()
	served[nearest] = true
	MissionManager.save_level_state({"served": served, "decorations_placed": decorations_placed, "player_x": player.global_position.x})
	food.draggable = false
	var tween := create_tween()
	tween.tween_property(food, "global_position", citizens[nearest].global_position + Vector2(24, -80), 0.25)
	tween.tween_callback(food.queue_free)
	MissionManager.advance()
	mission_label.text = "Warga bahagia: %d/%d" % [MissionManager.current_progress, citizens.size()]
	show_notice("%s menerima bekal dengan senang hati!" % citizens[nearest].character_name)
	if MissionManager.current_progress == citizens.size():
		show_notice("Makanan siap! Tata perlengkapan pesta untuk menyelesaikan persiapan.")


func _spawn_decorations() -> void:
	var decoration_assets := [
		"res://assets/objects/tableware/obj_tableware_01.png",
		"res://assets/objects/tableware/obj_tableware_02.png",
		"res://assets/objects/tableware/obj_tableware_03.png",
		"res://assets/objects/tableware/obj_tableware_04.png",
	]
	for index in range(decorations_placed, decoration_assets.size()):
		var decoration := WorldObject.new()
		decoration.object_label = "Dekorasi %d" % (index + 1)
		decoration.texture_path = decoration_assets[index]
		decoration.draggable = true
		decoration.position = Vector2(420 + index * 82, OBJECT_CENTER_Y - 70)
		decoration.drag_ended.connect(_on_decoration_dropped.bind(index))
		decorations.append(decoration)
		add_child(decoration)


func _on_decoration_dropped(decoration: WorldObject, index: int) -> void:
	var target := Vector2(620 + index * 135, OBJECT_CENTER_Y - 105)
	if decoration.global_position.distance_to(target) > 115.0:
		show_notice("Dekatkan perlengkapan ke meja pesta yang bercahaya.")
		return
	decoration.draggable = false
	AudioManager.play_sfx(AudioManager.SFX_STRAWBERRY)
	var tween := create_tween()
	tween.tween_property(decoration, "global_position", target, 0.22)
	decorations_placed += 1
	MissionManager.save_level_state({"served": served, "decorations_placed": decorations_placed, "player_x": player.global_position.x})
	MissionManager.advance()
	show_notice("Dekorasi pesta terpasang!")
	if decorations_placed >= 4 and MissionManager.current_progress >= MissionManager.target_progress:
		show_notice("Pesta kebun siap dimulai! Semua teman berkumpul dengan gembira.")
