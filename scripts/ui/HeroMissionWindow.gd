class_name HeroMissionWindow
extends Control

signal item_success(state: Dictionary)
signal mission_completed
signal closed

const ITEM_SIZE := Vector2(92, 92)
const CHARACTER_SIZE := Vector2(180, 230)
const DRAG_BOUNDS := Rect2(150, 185, 980, 350)
# Level 2 "Berbagi Itu Indah": ubah angka ini saja, semua teks, slot, dan progress ikut menyesuaikan.
const SHARE_PER_CHILD := 3
const LEVEL_2_TOTAL := SHARE_PER_CHILD * 2
const STRAWBERRY_PATH := "res://assets/objects/food/obj_strawberry_01.png"

var level_id := &""
var mission_title := ""
var mission_instruction := ""
var target_progress := 0
var current_progress := 0
var state: Dictionary = {}
var item_nodes: Array[HeroDragItem] = []
var target_nodes: Array[Panel] = []
var section_label_nodes: Array[Label] = []
var target_rects: Array[Rect2] = []
var target_ids: Array[String] = []
var progress_label: Label
var progress_bar: ProgressBar
var progress_tween: Tween
var status_label: Label
var title_label: Label
var portrait: TextureRect
var portrait_name_label: Label
var interaction_area: Panel
var completed_panel: Panel
var completed_title_label: Label
var completed_text: Label
var completion_button: Button
var tutorial_panel: Panel
var tutorial_hand: TextureRect
var tutorial_demo_item: Sprite2D
var tutorial_hand_tween: Tween
var tutorial_text_label: Label
var tutorial_demo_label: Label
var tutorial_demo_label2: Label
var tutorial_demo_target: Panel
var tutorial_demo_target2: Panel
var level2_slots := {"lili": [], "tutu": []}
var slot_nodes: Array[Panel] = []
var built := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_shell()


func open_mission(new_level_id: StringName, title: String, instruction: String, portrait_path: String, npc_label: String, starting_progress: int, saved_state: Dictionary) -> void:
	level_id = new_level_id
	mission_title = title
	mission_instruction = instruction
	current_progress = starting_progress
	state = saved_state.duplicate(true)
	if level_id == &"level_2":
		target_progress = LEVEL_2_TOTAL
	elif level_id == &"level_3":
		target_progress = 6
	else:
		target_progress = 9
	_clear_items()
	title_label.text = mission_title
	_update_instruction_text()
	portrait.texture = load(portrait_path) if ResourceLoader.exists(portrait_path) else null
	portrait_name_label.text = npc_label
	status_label.text = "Pilih objek yang benar, lalu seret ke targetnya."
	progress_label.visible = true
	status_label.visible = true
	if level_id == &"level_5":
		completed_text.text = "Terima kasih! Taman kami hidup kembali."
	else:
		completed_text.text = "Terima kasih sudah membantu kami!"
	visible = true
	completed_panel.visible = false
	interaction_area.visible = true
	tutorial_panel.visible = true
	interaction_area.modulate.a = 0.28
	_configure_tutorial_for_level()
	_start_hand_tutorial()
	_build_activity()
	_update_progress()
	status_label.text = _objective_summary()


func _update_instruction_text() -> void:
	var current_instruction := mission_instruction
	if level_id == &"level_5":
		if current_progress < 3:
			current_instruction = "Tahap 1/3: Tanam tiga bibit di petak yang sesuai."
		elif current_progress < 6:
			current_instruction = "Tahap 2/3: Siram setiap bibit yang sudah ditanam."
		else:
			current_instruction = "Tahap 3/3: Letakkan bunga untuk menghidupkan taman."
	$MissionCard/Instruction.text = "Caranya mudah: " + current_instruction


func _build_shell() -> void:
	if built:
		return
	built = true
	var dim := ColorRect.new()
	dim.color = Color(0.025, 0.04, 0.06, 0.48)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var card := Panel.new()
	card.name = "MissionCard"
	card.position = Vector2(90, 54)
	card.size = Vector2(1100, 620)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f6e6c5f2")
	style.border_color = Color("9a7047")
	style.set_border_width_all(4)
	style.set_corner_radius_all(26)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 18
	card.add_theme_stylebox_override("panel", style)
	add_child(card)
	var eyebrow := Label.new()
	eyebrow.text = "HERO MISSION"
	eyebrow.position = Vector2(36, 24)
	eyebrow.size = Vector2(220, 24)
	eyebrow.add_theme_font_size_override("font_size", 15)
	eyebrow.add_theme_color_override("font_color", Color("7f5c3e"))
	card.add_child(eyebrow)
	title_label = Label.new()
	title_label.position = Vector2(34, 45)
	title_label.size = Vector2(820, 48)
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color("4b3427"))
	card.add_child(title_label)
	portrait = TextureRect.new()
	portrait.position = Vector2(960, 20)
	portrait.size = Vector2(100, 100)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(portrait)
	portrait_name_label = Label.new()
	portrait_name_label.position = Vector2(946, 119)
	portrait_name_label.size = Vector2(128, 24)
	portrait_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_name_label.add_theme_font_size_override("font_size", 15)
	portrait_name_label.add_theme_color_override("font_color", Color("4b3427"))
	card.add_child(portrait_name_label)
	var instruction := Label.new()
	instruction.name = "Instruction"
	instruction.position = Vector2(36, 105)
	instruction.size = Vector2(900, 42)
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.add_theme_font_size_override("font_size", 18)
	instruction.add_theme_color_override("font_color", Color("654a38"))
	card.add_child(instruction)
	interaction_area = Panel.new()
	interaction_area.name = "InteractionArea"
	interaction_area.position = Vector2(24, 150)
	interaction_area.size = Vector2(1052, 420)
	interaction_area.mouse_filter = Control.MOUSE_FILTER_STOP
	var area_style := StyleBoxFlat.new()
	area_style.bg_color = Color("fff7e4c8")
	area_style.border_color = Color("d8b67d")
	area_style.set_border_width_all(2)
	area_style.set_corner_radius_all(18)
	interaction_area.add_theme_stylebox_override("panel", area_style)
	card.add_child(interaction_area)
	progress_label = Label.new()
	progress_label.position = Vector2(36, 570)
	progress_label.size = Vector2(260, 32)
	progress_label.add_theme_font_size_override("font_size", 21)
	progress_label.add_theme_color_override("font_color", Color("4b3427"))
	card.add_child(progress_label)
	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(36, 604)
	progress_bar.size = Vector2(260, 14)
	progress_bar.show_percentage = false
	var progress_track := StyleBoxFlat.new()
	progress_track.bg_color = Color("dcc89f")
	progress_track.set_corner_radius_all(7)
	progress_bar.add_theme_stylebox_override("background", progress_track)
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = Color("68c933")
	progress_fill.set_corner_radius_all(7)
	progress_bar.add_theme_stylebox_override("fill", progress_fill)
	card.add_child(progress_bar)
	status_label = Label.new()
	status_label.position = Vector2(320, 572)
	status_label.size = Vector2(700, 30)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color("6f513b"))
	card.add_child(status_label)
	var guide_label := Label.new()
	guide_label.text = "PETUNJUK   1. Pilih gambar   •   2. Seret perlahan   •   3. Lepaskan di kotak hijau"
	guide_label.position = Vector2(320, 606)
	guide_label.size = Vector2(1020, 22)
	guide_label.add_theme_font_size_override("font_size", 14)
	guide_label.add_theme_color_override("font_color", Color("8a684c"))
	card.add_child(guide_label)
	completed_panel = Panel.new()
	completed_panel.position = Vector2(330, 170)
	completed_panel.size = Vector2(620, 330)
	completed_panel.visible = false
	var complete_style := StyleBoxFlat.new()
	complete_style.bg_color = Color("fff1b9")
	complete_style.border_color = Color("d39a3f")
	complete_style.set_border_width_all(3)
	complete_style.set_corner_radius_all(24)
	completed_panel.add_theme_stylebox_override("panel", complete_style)
	add_child(completed_panel)
	completed_title_label = Label.new()
	completed_title_label.text = "MISI SELESAI!"
	completed_title_label.position = Vector2(30, 60)
	completed_title_label.size = Vector2(560, 48)
	completed_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	completed_title_label.add_theme_font_size_override("font_size", 32)
	completed_title_label.add_theme_color_override("font_color", Color("3f6538"))
	completed_title_label.add_theme_constant_override("outline_size", 2)
	completed_title_label.add_theme_color_override("font_outline_color", Color("fff1d1"))
	completed_panel.add_child(completed_title_label)
	completed_text = Label.new()
	completed_text.text = "Hebat! Kamu berhasil menyelesaikan misi ini."
	completed_text.position = Vector2(35, 125)
	completed_text.size = Vector2(550, 40)
	completed_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	completed_text.add_theme_font_size_override("font_size", 18)
	completed_text.add_theme_color_override("font_color", Color("593b2b"))
	completed_text.add_theme_constant_override("outline_size", 2)
	completed_text.add_theme_color_override("font_outline_color", Color("fff1d1"))
	completed_panel.add_child(completed_text)
	completion_button = Button.new()
	completion_button.text = "LANJUTKAN"
	completion_button.position = Vector2(180, 205)
	completion_button.size = Vector2(260, 52)
	completion_button.add_theme_font_size_override("font_size", 20)
	completion_button.add_theme_color_override("font_color", Color("593b2b"))
	var completion_button_style := StyleBoxFlat.new()
	completion_button_style.bg_color = Color("e2c98f")
	completion_button_style.border_color = Color("9a7047")
	completion_button_style.set_border_width_all(2)
	completion_button_style.set_corner_radius_all(14)
	completion_button.add_theme_stylebox_override("normal", completion_button_style)
	var completion_hover := completion_button_style.duplicate() as StyleBoxFlat
	completion_hover.bg_color = Color("f1dca9")
	completion_button.add_theme_stylebox_override("hover", completion_hover)
	completion_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	completion_button.disabled = false
	completion_button.pressed.connect(func() -> void:
		completed_panel.visible = false
		visible = false
		closed.emit()
	)
	completed_panel.add_child(completion_button)
	tutorial_panel = Panel.new()
	tutorial_panel.position = Vector2(330, 170)
	tutorial_panel.size = Vector2(620, 330)
	var tutorial_style := StyleBoxFlat.new()
	tutorial_style.bg_color = Color("fff1cfff")
	tutorial_style.border_color = Color("d39a3f")
	tutorial_style.set_border_width_all(3)
	tutorial_style.set_corner_radius_all(24)
	tutorial_panel.add_theme_stylebox_override("panel", tutorial_style)
	add_child(tutorial_panel)
	var tutorial_title := Label.new()
	tutorial_title.text = "CARA BERMAIN"
	tutorial_title.position = Vector2(30, 34)
	tutorial_title.size = Vector2(560, 42)
	tutorial_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_title.add_theme_font_size_override("font_size", 30)
	tutorial_title.add_theme_color_override("font_color", Color("3f6538"))
	tutorial_title.add_theme_constant_override("outline_size", 2)
	tutorial_title.add_theme_color_override("font_outline_color", Color("fff1d1"))
	tutorial_panel.add_child(tutorial_title)
	tutorial_text_label = Label.new()
	tutorial_text_label.text = "Contoh cara bermain:\nGeser objek ke kotak tujuan."
	tutorial_text_label.position = Vector2(52, 84)
	tutorial_text_label.size = Vector2(516, 78)
	tutorial_text_label.add_theme_font_size_override("font_size", 20)
	tutorial_text_label.add_theme_color_override("font_color", Color("654a38"))
	tutorial_panel.add_child(tutorial_text_label)
	var demo_target := Panel.new()
	demo_target.position = Vector2(430, 168)
	demo_target.size = Vector2(128, 92)
	var demo_style := StyleBoxFlat.new()
	demo_style.bg_color = Color("d9efc7")
	demo_style.border_color = Color("6f9b67")
	demo_style.set_border_width_all(3)
	demo_style.set_corner_radius_all(16)
	demo_target.add_theme_stylebox_override("panel", demo_style)
	tutorial_panel.add_child(demo_target)
	tutorial_demo_label = Label.new()
	tutorial_demo_label.text = "LEPAS DI SINI"
	tutorial_demo_label.position = Vector2(8, 34)
	tutorial_demo_label.size = Vector2(112, 24)
	tutorial_demo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_demo_label.add_theme_font_size_override("font_size", 13)
	tutorial_demo_label.add_theme_color_override("font_color", Color("55714f"))
	demo_target.add_child(tutorial_demo_label)
	tutorial_demo_target = demo_target
	tutorial_demo_target2 = Panel.new()
	tutorial_demo_target2.position = Vector2(52, 168)
	tutorial_demo_target2.size = Vector2(128, 92)
	tutorial_demo_target2.add_theme_stylebox_override("panel", demo_style)
	tutorial_demo_target2.visible = false
	tutorial_panel.add_child(tutorial_demo_target2)
	tutorial_demo_label2 = Label.new()
	tutorial_demo_label2.position = Vector2(8, 34)
	tutorial_demo_label2.size = Vector2(112, 24)
	tutorial_demo_label2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_demo_label2.add_theme_font_size_override("font_size", 13)
	tutorial_demo_label2.add_theme_color_override("font_color", Color("55714f"))
	tutorial_demo_target2.add_child(tutorial_demo_label2)
	tutorial_demo_item = Sprite2D.new()
	var demo_texture: Texture2D = load("res://assets/objects/food/obj_strawberry_01.png") as Texture2D
	tutorial_demo_item.texture = demo_texture
	tutorial_demo_item.position = Vector2(170, 210)
	if demo_texture != null:
		var demo_size: Vector2 = demo_texture.get_size()
		tutorial_demo_item.scale = Vector2.ONE * minf(62.0 / demo_size.x, 62.0 / demo_size.y)
	tutorial_panel.add_child(tutorial_demo_item)
	tutorial_hand = TextureRect.new()
	tutorial_hand.texture = load("res://assets/ui/tutorial_hand.svg")
	tutorial_hand.position = Vector2(145, 178)
	tutorial_hand.size = Vector2(72, 84)
	tutorial_hand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tutorial_hand.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tutorial_hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_panel.add_child(tutorial_hand)
	var tutorial_button := Button.new()
	tutorial_button.text = "MULAI MISI"
	tutorial_button.position = Vector2(180, 246)
	tutorial_button.size = Vector2(260, 54)
	tutorial_button.add_theme_font_size_override("font_size", 20)
	tutorial_button.pressed.connect(_start_activity)
	tutorial_panel.add_child(tutorial_button)


func _build_activity() -> void:
	if level_id == &"level_2":
		_build_level_2()
	elif level_id == &"level_3":
		_build_level_3()
	elif level_id == &"level_4":
		_build_level_4()
	else:
		_build_level_5()


func _start_activity() -> void:
	if tutorial_hand_tween != null and tutorial_hand_tween.is_valid():
		tutorial_hand_tween.kill()
	tutorial_panel.visible = false
	interaction_area.modulate.a = 1.0
	if level_id == &"level_2":
		status_label.text = "Ayo mulai! %s" % level_2_instruction()
	else:
		status_label.text = "Ayo mulai! Seret gambar ke kotak hijau yang sesuai."


func _configure_tutorial_for_level() -> void:
	var asset_path := "res://assets/objects/food/obj_strawberry_01.png"
	var object_name := "strawberry"
	var target_name := "LILI atau TUTU"
	if level_id == &"level_3":
		asset_path = "res://assets/objects/bridge/obj_wood_01.png"
		object_name = "3 papan dan 1 batang kayu"
		target_name = "kotak bernomor yang sesuai"
	elif level_id == &"level_4":
		asset_path = "res://assets/objects/food/obj_cake_01.png"
		object_name = "makanan"
		target_name = "meja pesta"
	elif level_id == &"level_5":
		asset_path = "res://assets/objects/garden/hero_seed.svg"
		object_name = "benih"
		target_name = "lubang tanah"
	if tutorial_text_label != null:
		if level_id == &"level_2":
			tutorial_text_label.text = "Bagi %d stroberi sama banyak:\n%d untuk Lili, %d untuk Tutu." % [LEVEL_2_TOTAL, SHARE_PER_CHILD, SHARE_PER_CHILD]
		else:
			tutorial_text_label.text = "Contoh cara bermain:\nGeser %s ke %s." % [object_name, target_name]
	if tutorial_demo_target != null:
		var demo_y := 150.0 if level_id == &"level_2" else 168.0
		tutorial_demo_target.position = Vector2(430, demo_y)
		tutorial_demo_target2.position = Vector2(52, demo_y)
		tutorial_demo_target2.visible = level_id == &"level_2"
	if tutorial_demo_label != null:
		tutorial_demo_label.text = "TUTU" if level_id == &"level_2" else "LEPAS DI SINI"
	if tutorial_demo_label2 != null:
		tutorial_demo_label2.text = "LILI"
	if tutorial_demo_item != null:
		tutorial_demo_item.texture = load(asset_path) as Texture2D
		var demo_texture: Texture2D = tutorial_demo_item.texture
		if demo_texture != null:
			var demo_size: Vector2 = demo_texture.get_size()
			tutorial_demo_item.scale = Vector2.ONE * minf(62.0 / demo_size.x, 62.0 / demo_size.y)


func _start_hand_tutorial() -> void:
	if tutorial_hand == null:
		return
	if tutorial_hand_tween != null and tutorial_hand_tween.is_valid():
		tutorial_hand_tween.kill()
	if level_id == &"level_2":
		_start_level_2_hand_tutorial()
		return
	tutorial_hand.position = Vector2(145, 178)
	tutorial_demo_item.position = Vector2(170, 210)
	tutorial_hand_tween = create_tween().set_loops()
	tutorial_hand_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tutorial_hand_tween.tween_property(tutorial_hand, "position", Vector2(405, 178), 0.9)
	tutorial_hand_tween.parallel().tween_property(tutorial_demo_item, "position", Vector2(495, 210), 0.9)
	tutorial_hand_tween.tween_interval(0.25)
	tutorial_hand_tween.tween_property(tutorial_hand, "position", Vector2(145, 178), 0.9)
	tutorial_hand_tween.parallel().tween_property(tutorial_demo_item, "position", Vector2(170, 210), 0.9)
	tutorial_hand_tween.tween_interval(0.45)


func _start_level_2_hand_tutorial() -> void:
	var start_hand := Vector2(268, 140)
	var start_item := Vector2(300, 178)
	tutorial_hand.position = start_hand
	tutorial_demo_item.position = start_item
	tutorial_hand_tween = create_tween().set_loops()
	tutorial_hand_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for destination in [Vector2(116, 196), Vector2(494, 196)]:
		tutorial_hand_tween.tween_property(tutorial_hand, "position", destination + Vector2(-32, -38), 0.9)
		tutorial_hand_tween.parallel().tween_property(tutorial_demo_item, "position", destination, 0.9)
		tutorial_hand_tween.tween_interval(0.5)
		tutorial_hand_tween.tween_callback(func() -> void:
			tutorial_hand.position = start_hand
			tutorial_demo_item.position = start_item
		)
		tutorial_hand_tween.tween_interval(0.3)


func level_2_instruction() -> String:
	return "Bagi %d stroberi sama banyak: %d untuk Lili, %d untuk Tutu." % [LEVEL_2_TOTAL, SHARE_PER_CHILD, SHARE_PER_CHILD]


func _build_level_2() -> void:
	var lili_count := clampi(int(state.get("lili_count", 0)), 0, SHARE_PER_CHILD)
	var tutu_count := clampi(int(state.get("tutu_count", 0)), 0, SHARE_PER_CHILD)
	var lili_x := 80.0
	var tutu_x := 662.0
	_add_target(Vector2(lili_x, 10), Vector2(310, 262), "lili", Color("d9efc7"))
	_add_target(Vector2(tutu_x, 10), Vector2(310, 262), "tutu", Color("d9efc7"))
	_add_character("res://assets/characters/lili/lili_16.png", "LILI", Vector2(lili_x + 12, 10), "lili")
	_add_character("res://assets/characters/tutu/tutu_16.png", "TUTU", Vector2(tutu_x + 12, 10), "tutu")
	_add_level_2_slots("lili", lili_x, lili_count)
	_add_level_2_slots("tutu", tutu_x, tutu_count)
	var remaining := LEVEL_2_TOTAL - lili_count - tutu_count
	for index in remaining:
		# Stroberi bebas dijatuhkan ke Lili atau Tutu (target_id kosong), tanpa lencana angka.
		_add_item("res://assets/objects/food/obj_strawberry_%02d.png" % (index % 3 + 1), Vector2(230 + index * 100, 310), "", {"kind": "strawberry", "index": index})


func _add_level_2_slots(target_id: String, box_x: float, filled: int) -> void:
	var texture: Texture2D = load(STRAWBERRY_PATH) as Texture2D
	var slots: Array = []
	for i in SHARE_PER_CHILD:
		var slot := Panel.new()
		slot.position = Vector2(box_x + 222.0, 40.0 + i * 68.0)
		slot.size = Vector2(60, 60)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var slot_style := StyleBoxFlat.new()
		slot_style.bg_color = Color(1, 1, 1, 0.6)
		slot_style.border_color = Color("6f9b67")
		slot_style.set_border_width_all(3)
		slot_style.set_corner_radius_all(14)
		slot.add_theme_stylebox_override("panel", slot_style)
		interaction_area.add_child(slot)
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.position = slot.size * 0.5
		var base_scale := 1.0
		if texture != null:
			var texture_size: Vector2 = texture.get_size()
			base_scale = minf(46.0 / texture_size.x, 46.0 / texture_size.y)
		sprite.scale = Vector2.ONE * base_scale
		sprite.modulate = Color.WHITE if i < filled else Color(0.25, 0.25, 0.25, 0.28)
		slot.add_child(sprite)
		slot.set_meta("sprite", sprite)
		slot.set_meta("base_scale", base_scale)
		var number_label := Label.new()
		number_label.text = str(i + 1)
		number_label.position = Vector2(0, 34)
		number_label.size = Vector2(56, 24)
		number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		number_label.add_theme_font_size_override("font_size", 16)
		number_label.add_theme_color_override("font_color", Color("405a36"))
		number_label.add_theme_constant_override("outline_size", 4)
		number_label.add_theme_color_override("font_outline_color", Color("fff8e9"))
		number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(number_label)
		slots.append(slot)
		slot_nodes.append(slot)
	level2_slots[target_id] = slots


func _fill_level_2_slot(target_id: String, slot_index: int) -> void:
	var slots: Array = level2_slots.get(target_id, [])
	if slot_index < 0 or slot_index >= slots.size():
		return
	var slot: Panel = slots[slot_index]
	if not is_instance_valid(slot):
		return
	var sprite: Sprite2D = slot.get_meta("sprite")
	var base_scale: float = slot.get_meta("base_scale")
	sprite.modulate = Color.WHITE
	sprite.scale = Vector2.ONE * base_scale * 1.35
	var pop := create_tween()
	pop.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(sprite, "scale", Vector2.ONE * base_scale, 0.25)


func _level_2_target_at(item_center: Vector2) -> String:
	var best := ""
	var best_distance := INF
	for id in ["lili", "tutu"]:
		var index := target_ids.find(id)
		if index < 0:
			continue
		var rect: Rect2 = target_rects[index]
		if not rect.grow(34.0).has_point(item_center):
			continue
		var distance := item_center.distance_to(rect.get_center())
		if distance < best_distance:
			best_distance = distance
			best = id
	return best


func _level_2_status(target_id: String) -> String:
	var lili := int(state.get("lili_count", 0))
	var tutu := int(state.get("tutu_count", 0))
	var name_text := "Lili" if target_id == "lili" else "Tutu"
	var other_name := "Tutu" if target_id == "lili" else "Lili"
	var mine := lili if target_id == "lili" else tutu
	var other := tutu if target_id == "lili" else lili
	if lili >= SHARE_PER_CHILD and tutu >= SHARE_PER_CHILD:
		return "Hebat! Lili %d stroberi, Tutu %d stroberi. Sama banyak!" % [SHARE_PER_CHILD, SHARE_PER_CHILD]
	if mine >= SHARE_PER_CHILD:
		return "%s sudah dapat %d stroberi. Sekarang bagi ke %s ya!" % [name_text, SHARE_PER_CHILD, other_name]
	return "%s dapat %d dari %d stroberi. %s dapat %d." % [name_text, mine, SHARE_PER_CHILD, other_name, other]


func _build_level_3() -> void:
	var placed: Array = state.get("placed", [false, false, false, false, false, false])
	for index in 4:
		_add_target(Vector2(226 + index * 150, 48), Vector2(150, 72), "board_%d" % index, Color("e8c38d"))
		if index >= placed.size() or not bool(placed[index]):
			var item_kind := "log" if index == 3 else "board"
			_add_item("res://assets/objects/bridge/obj_wood_%02d.png" % (index + 1), Vector2(255 + index * 150, 250), "board_%d" % index, {"kind": item_kind, "index": index})
	for index in 2:
		var rope_index := index + 4
		_add_target(Vector2(340 + index * 192, 150), Vector2(180, 52), "rope_%d" % index, Color("d7c39a"))
		if rope_index >= placed.size() or not bool(placed[rope_index]):
			_add_item("res://assets/objects/bridge/obj_rope_%02d.png" % (index + 1), Vector2(340 + index * 192, 325), "rope_%d" % index, {"kind": "rope", "index": rope_index})


func _build_level_4() -> void:
	var served: Array = state.get("served", [false, false, false, false, false])
	var food_paths := ["res://assets/objects/food/obj_cake_01.png", "res://assets/objects/food/obj_bread_01.png", "res://assets/objects/food/obj_fruit_01.png", "res://assets/objects/drinks/obj_juice_01.png", "res://assets/objects/food/obj_bread_01.png"]
	_add_section_label("MAKANAN  -  BAGIKAN KE WARGA", Vector2(32, 4), Vector2(430, 26))
	for index in 5:
		var column_x := 86.0 + index * 180.0
		_add_target(Vector2(column_x, 58), Vector2(160, 92), "food_%d" % index, Color("f5ddb1"), true)
		if not bool(served[index]):
			_add_item(food_paths[index], Vector2(column_x + 34.0, 150), "food_%d" % index, {"kind": "food", "index": index})
	var placed_decorations: Array = state.get("decorations", [])
	if placed_decorations.is_empty():
		for index in mini(int(state.get("decorations_placed", 0)), 4):
			placed_decorations.append(index)
	var decoration_paths := ["res://assets/objects/tableware/obj_tableware_01.png", "res://assets/objects/tableware/obj_tableware_02.png", "res://assets/objects/tableware/obj_tableware_03.png", "res://assets/objects/tableware/obj_tableware_04.png"]
	_add_section_label("PERLENGKAPAN  -  TATA DI MEJA PESTA", Vector2(32, 218), Vector2(700, 26))
	for index in 4:
		var column_x := 79.0 + index * 228.0
		_add_target(Vector2(column_x, 278), Vector2(210, 92), "decor_%d" % index, Color("d8efc9"), true)
		if not placed_decorations.has(index):
			_add_item(decoration_paths[index], Vector2(column_x + 59.0, 326), "decor_%d" % index, {"kind": "decor", "index": index})


func _build_level_5() -> void:
	var progress := int(state.get("progress", current_progress))
	var seed_path := "res://assets/objects/garden/hero_seed.svg"
	var flower_path := "res://assets/objects/garden/hero_flower.svg"
	for index in 3:
		_add_target(Vector2(112 + index * 292, 12), Vector2(200, 58), "seed_%d" % index, Color("d9b88b"))
		if progress < index + 1:
			_add_item(seed_path, _garden_item_position(index), "seed_%d" % index, {"kind": "garden", "index": index})
	for index in 3:
		_add_target(Vector2(112 + index * 292, 80), Vector2(200, 58), "water_%d" % index, Color("bde2f2"))
		if progress < index + 4:
			var item_index := index + 3
			_add_item("res://assets/objects/garden/obj_watering_can_01.png", _garden_item_position(item_index), "water_%d" % index, {"kind": "garden", "index": item_index})
	for index in 3:
		_add_target(Vector2(112 + index * 292, 148), Vector2(200, 58), "flower_%d" % index, Color("f5c3d2"))
		if progress < index + 7:
			var item_index := index + 6
			_add_item(flower_path, _garden_item_position(item_index), "flower_%d" % index, {"kind": "garden", "index": item_index})


func _garden_item_position(index: int) -> Vector2:
	var column := index % 5
	var row := floori(float(index) / 5.0)
	return Vector2(55 + column * 195, 232 + row * 94)


func _add_section_label(text_value: String, position_value: Vector2, label_size: Vector2) -> void:
	var section_label := Label.new()
	section_label.text = text_value
	section_label.position = position_value
	section_label.size = label_size
	section_label.add_theme_font_size_override("font_size", 17)
	section_label.add_theme_color_override("font_color", Color("7f5c3e"))
	section_label.add_theme_constant_override("outline_size", 3)
	section_label.add_theme_color_override("font_outline_color", Color("fff7e4"))
	section_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interaction_area.add_child(section_label)
	section_label_nodes.append(section_label)


func _add_character(path: String, character_name: String, position_value: Vector2, _id: String) -> void:
	var image := TextureRect.new()
	var character_texture: Texture2D = load(path) as Texture2D
	image.texture = null
	image.position = position_value + Vector2(0, -5)
	image.custom_minimum_size = Vector2.ZERO
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.size = CHARACTER_SIZE
	image.clip_contents = true
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interaction_area.add_child(image)
	var visual := Sprite2D.new()
	visual.texture = character_texture
	visual.position = CHARACTER_SIZE * 0.5
	if character_texture != null:
		var texture_size: Vector2 = character_texture.get_size()
		var fit_scale: float = minf(CHARACTER_SIZE.x / texture_size.x, CHARACTER_SIZE.y / texture_size.y)
		visual.scale = Vector2.ONE * fit_scale
	image.add_child(visual)
	var label := Label.new()
	label.text = character_name
	label.position = position_value + Vector2(0, 268)
	label.size = Vector2(CHARACTER_SIZE.x, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("4b3427"))
	interaction_area.add_child(label)


func _add_target(position_value: Vector2, target_size: Vector2, target_id: String, color: Color, label_above: bool = false) -> void:
	var target := Panel.new()
	target.position = position_value
	target.size = target_size
	target.name = "Target_%s" % target_id
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color, 0.42)
	style.border_color = color.darkened(0.25)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	target.add_theme_stylebox_override("panel", style)
	interaction_area.add_child(target)
	var target_label := Label.new()
	target_label.text = _target_hint(target_id)
	target_label.position = Vector2(8, -26) if label_above else Vector2(8, target_size.y - 28)
	target_label.size = Vector2(target_size.x - 16, 24)
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_label.add_theme_font_size_override("font_size", 14 if label_above else 13)
	target_label.add_theme_color_override("font_color", Color("405a36"))
	target_label.add_theme_constant_override("outline_size", 4 if label_above else 2)
	target_label.add_theme_color_override("font_outline_color", Color("fff8e9"))
	target_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(target_label)
	target_nodes.append(target)
	target_rects.append(Rect2(position_value, target_size))
	target_ids.append(target_id)


func _add_item(path: String, position_value: Vector2, target_id: String, item_data: Dictionary) -> void:
	var item := HeroDragItem.new()
	var item_texture: Texture2D = load(path) as Texture2D
	item.texture = null
	item.custom_minimum_size = Vector2.ZERO
	item.position = position_value
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.set_size(ITEM_SIZE)
	item.clip_contents = true
	item.set_meta("target_id", target_id)
	item.set_meta("item_data", item_data)
	item.drag_finished.connect(_on_item_dropped)
	interaction_area.add_child(item)
	var visual := Sprite2D.new()
	visual.texture = item_texture
	visual.position = ITEM_SIZE * 0.5
	if item_texture != null:
		var texture_size: Vector2 = item_texture.get_size()
		var fit_scale: float = minf(ITEM_SIZE.x / texture_size.x, ITEM_SIZE.y / texture_size.y)
		visual.scale = Vector2.ONE * fit_scale
	item.add_child(visual)
	var item_kind := str(item_data.get("kind", ""))
	if item_kind in ["board", "log", "rope", "food", "decor", "garden"]:
		var item_index := int(item_data.get("index", 0))
		var item_number := item_index + 1
		if item_kind == "rope":
			item_number -= 4
		elif item_kind == "garden":
			item_number = item_index % 3 + 1
		var number_badge := Panel.new()
		number_badge.position = Vector2(ITEM_SIZE.x - 30, 2)
		number_badge.size = Vector2(28, 28)
		number_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = Color("704127")
		badge_style.border_color = Color("fff0cf")
		badge_style.set_border_width_all(2)
		badge_style.set_corner_radius_all(14)
		number_badge.add_theme_stylebox_override("panel", badge_style)
		item.add_child(number_badge)
		var number_label := Label.new()
		number_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		number_label.text = str(item_number)
		number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number_label.add_theme_font_size_override("font_size", 15)
		number_label.add_theme_color_override("font_color", Color("fff8e9"))
		number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		number_badge.add_child(number_label)
	item.setup(Rect2(0, 0, interaction_area.size.x, interaction_area.size.y))
	item_nodes.append(item)


func _on_item_dropped(item: HeroDragItem) -> void:
	var target_id := str(item.get_meta("target_id", ""))
	var item_center := item.position + item.size * 0.5
	if level_id == &"level_2":
		# Stroberi boleh dibagikan ke Lili atau Tutu, selama kotaknya belum penuh.
		target_id = _level_2_target_at(item_center)
		if target_id == "":
			item.return_home()
			status_label.text = "Letakkan stroberi di kotak Lili atau Tutu ya!"
			return
		var received_now := int(state.get("lili_count" if target_id == "lili" else "tutu_count", 0))
		if received_now >= SHARE_PER_CHILD:
			item.return_home()
			var full_name := "Lili" if target_id == "lili" else "Tutu"
			var other_name := "Tutu" if target_id == "lili" else "Lili"
			status_label.text = "%s sudah dapat %d stroberi. Bagi ke %s ya!" % [full_name, SHARE_PER_CHILD, other_name]
			return
	var target_index := target_ids.find(target_id)
	if target_index < 0 or not target_rects[target_index].grow(34.0).has_point(item_center):
		item.return_home()
		status_label.text = "Belum tepat. Geser pelan-pelan ke kotak hijau ya!"
		return
	item.locked = true
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if level_id != &"level_2":
		item.position = target_rects[target_index].get_center() - item.size * 0.5
	var item_data: Dictionary = item.get_meta("item_data", {})
	var next_state := state.duplicate(true)
	if level_id == &"level_2":
		var key := "lili_count" if target_id == "lili" else "tutu_count"
		next_state[key] = int(next_state.get(key, 0)) + 1
		var slot_index := int(next_state[key]) - 1
		var slots: Array = level2_slots.get(target_id, [])
		if slot_index < slots.size():
			# Stroberi terbang ke slot kosong lalu slot berubah jadi stroberi berwarna.
			var slot_node: Panel = slots[slot_index]
			var fly := create_tween()
			fly.tween_property(item, "position", slot_node.position + slot_node.size * 0.5 - item.size * 0.5, 0.22)
			fly.tween_callback(func() -> void:
				_fill_level_2_slot(target_id, slot_index)
				if is_instance_valid(item):
					item.queue_free()
			)
	elif level_id == &"level_3":
		var placed: Array = next_state.get("placed", [false, false, false, false, false, false])
		if placed.size() < 6:
			placed.resize(6)
			for index in 6:
				if placed[index] == null:
					placed[index] = false
		placed[int(item_data.get("index", 0))] = true
		next_state["placed"] = placed
	elif level_id == &"level_4":
		if str(item_data.get("kind", "")) == "food":
			var served: Array = next_state.get("served", [false, false, false, false, false])
			served[int(item_data.get("index", 0))] = true
			next_state["served"] = served
		else:
			var decorations: Array = next_state.get("decorations", [])
			var decoration_index := int(item_data.get("index", 0))
			if not decorations.has(decoration_index):
				decorations.append(decoration_index)
			next_state["decorations"] = decorations
			next_state["decorations_placed"] = decorations.size()
	else:
		next_state["progress"] = int(next_state.get("progress", current_progress)) + 1
	state = next_state
	current_progress += 1
	item_success.emit(state)
	_update_instruction_text()
	status_label.text = _level_2_status(target_id) if level_id == &"level_2" else _objective_summary()
	_update_progress()
	if current_progress >= target_progress:
		mission_completed.emit()


func _update_progress() -> void:
	progress_label.text = "PROGRESS  %d / %d" % [current_progress, target_progress]
	progress_bar.max_value = maxf(float(target_progress), 1.0)
	if progress_tween != null and progress_tween.is_running():
		progress_tween.kill()
	progress_tween = create_tween()
	progress_tween.tween_property(progress_bar, "value", current_progress, 0.22)


func _objective_summary() -> String:
	if level_id == &"level_2":
		return "%s  |  %s" % [_objective_count("Lili", int(state.get("lili_count", 0)), SHARE_PER_CHILD), _objective_count("Tutu", int(state.get("tutu_count", 0)), SHARE_PER_CHILD)]
	if level_id == &"level_3":
		var placed: Array = state.get("placed", [false, false, false, false, false, false])
		var boards := 0
		var ropes := 0
		for index in 4:
			if index < placed.size() and bool(placed[index]):
				boards += 1
		for index in range(4, 6):
			if index < placed.size() and bool(placed[index]):
				ropes += 1
		return "%s  |  %s" % [_objective_count("Papan", boards, 4), _objective_count("Tali", ropes, 2)]
	if level_id == &"level_4":
		var served: Array = state.get("served", [false, false, false, false, false])
		var served_count := 0
		for is_served in served:
			if bool(is_served):
				served_count += 1
		var decorations: Array = state.get("decorations", [])
		var decoration_count := decorations.size() if not decorations.is_empty() else int(state.get("decorations_placed", 0))
		return "%s  |  %s" % [_objective_count("Warga", served_count, 5), _objective_count("Perlengkapan", decoration_count, 4)]
	if level_id == &"level_5":
		var stage := 1 if current_progress < 3 else 2 if current_progress < 6 else 3
		return "Tahap %d/3  |  %d/9 selesai" % [stage, current_progress]
	return "Objektif %d/%d" % [current_progress, target_progress]


func _objective_count(label: String, current: int, target: int) -> String:
	if current >= target:
		return "%s ✓" % label
	return "%s %d/%d" % [label, current, target]


func _target_hint(target_id: String) -> String:
	if target_id == "tutu":
		return "TUTU - %d STROBERI" % SHARE_PER_CHILD
	if target_id == "lili":
		return "LILI - %d STROBERI" % SHARE_PER_CHILD
	if target_id.begins_with("board"):
		if target_id == "board_3":
			return "4. BATANG KAYU"
		return "%d. PAPAN" % (int(target_id.trim_prefix("board_")) + 1)
	if target_id.begins_with("rope"):
		return "%d. TALI" % (int(target_id.trim_prefix("rope_")) + 1)
	if target_id.begins_with("food"):
		return "%d. MAKANAN" % (int(target_id.trim_prefix("food_")) + 1)
	if target_id.begins_with("decor"):
		return "%d. PERLENGKAPAN" % (int(target_id.trim_prefix("decor_")) + 1)
	if target_id.begins_with("seed"):
		return "%d. TANAM" % (int(target_id.trim_prefix("seed_")) + 1)
	if target_id.begins_with("water"):
		return "%d. SIRAM" % (int(target_id.trim_prefix("water_")) + 1)
	if target_id.begins_with("flower"):
		return "%d. BUNGA" % (int(target_id.trim_prefix("flower_")) + 1)
	return "LETAKKAN DI SINI"


func show_completed(completed_mission_title: String) -> void:
	visible = true
	tutorial_panel.visible = false
	interaction_area.visible = false
	progress_label.text = "COMPLETED  ✓"
	progress_label.visible = true
	progress_bar.visible = false
	status_label.visible = false
	completed_title_label.text = "MISI SELESAI!"
	completed_text.text = "Hebat! Kamu berhasil menyelesaikan:\n%s" % completed_mission_title
	completion_button.text = "LANJUTKAN"
	completion_button.disabled = false
	completed_panel.position = Vector2(330, 170)
	completed_panel.visible = true
	completed_panel.scale = Vector2(0.88, 0.88)
	completed_panel.modulate.a = 0.0
	var popup_tween := create_tween()
	popup_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	popup_tween.set_parallel(true)
	popup_tween.tween_property(completed_panel, "scale", Vector2.ONE, 0.25)
	popup_tween.tween_property(completed_panel, "modulate:a", 1.0, 0.2)


func _clear_items() -> void:
	for item in item_nodes:
		if is_instance_valid(item):
			item.queue_free()
	for target in target_nodes:
		if is_instance_valid(target):
			target.queue_free()
	for section_label in section_label_nodes:
		if is_instance_valid(section_label):
			section_label.queue_free()
	for slot in slot_nodes:
		if is_instance_valid(slot):
			slot.queue_free()
	slot_nodes.clear()
	level2_slots = {"lili": [], "tutu": []}
	item_nodes.clear()
	target_nodes.clear()
	section_label_nodes.clear()
	target_rects.clear()
	target_ids.clear()
