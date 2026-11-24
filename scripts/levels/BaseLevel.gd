class_name BaseLevel
extends Node2D

const LILI_SCENE := preload("res://scenes/characters/Lili.tscn")
# Posisi tanah (jalan setapak) beda di tiap background, jadi baseline dibuat per level.
const GROUND_BY_LEVEL := {
	&"level_1": 864.0,
	&"level_2": 891.0,
	&"level_3": 790.0,
	&"level_4": 896.0,
	&"level_5": 850.0,
}
const OBJECT_OFFSET_ABOVE_GROUND := 60.0

# Nama dibiarkan sama supaya Level1.gd - Level5.gd tidak perlu diubah.
var GROUND_BASELINE := 790.0
var OBJECT_CENTER_Y := 730.0

@export var level_id: StringName = &"level_1"
@export var level_title := "Level"
@export var lesson_text := "Kebaikan"
@export var npc_name := "Tutu"
@export var npc_color := Color("67ad5b")
@export var npc_request := "Maukah kamu membantuku?"

var player: Lili
var mission_npc: NpcCharacter
var backdrop: LevelBackdrop
var hud: CanvasLayer
var gameplay_top_bar: Control
var mission_label: Label
var mission_hud_progress: ProgressBar
var mission_hud_progress_tween: Tween
var interaction_hint: Label
var interaction_hint_control: Control
var interaction_hint_outline: Polygon2D
var interaction_hint_fill: Polygon2D
var interaction_hint_gloss: Polygon2D
var dialogue_art: TextureRect
var dialogue_title: Label
var dialogue_text: Label
var dialogue_choices: HBoxContainer
var interaction_hint_message := ""
var accept_button: Button
var decline_button: Button
var pause_panel: Control
var pause_overlay: ColorRect
var mission_window: Control
var mission_title_label: Label
var mission_instruction_label: Label
var mission_progress_label: Label
var mission_progress_bar: ProgressBar
var mission_back_button: Button
var button_hover_tweens: Dictionary = {}
var interaction_hint_pulse: Tween
var mission_continue_button: Button
var mission_completed_panel: PanelContainer
var mission_portrait: TextureRect
var hero_window: HeroMissionWindow
var player_return_position := Vector2.ZERO
var mission_started := false
var level_finished := false
var dialogue_available := true
var interactables: Array[WorldObject] = []


func _ready() -> void:
	GROUND_BASELINE = GROUND_BY_LEVEL.get(level_id, 790.0)
	OBJECT_CENTER_Y = GROUND_BASELINE - OBJECT_OFFSET_ABOVE_GROUND
	AudioManager.play_full_game_music()
	GameManager.resume_gameplay()
	LevelManager.set_current_level(level_id)
	_build_world()
	_build_interface()
	DialogueManager.choice_made.connect(_on_dialogue_choice)
	MissionManager.mission_started.connect(_on_mission_started)
	MissionManager.mission_progress_changed.connect(_on_mission_progress)
	MissionManager.mission_completed.connect(_on_mission_completed)
	call_deferred("_restore_mission_checkpoint")


func _restore_mission_checkpoint() -> void:
	var checkpoint := SaveManager.get_mission_checkpoint()
	if str(checkpoint.get("level_id", "")) != String(level_id):
		return
	var state: Variant = checkpoint.get("state", {})
	if state is Dictionary and state.has("player_x"):
		player.global_position.x = clampf(float(state["player_x"]), player.world_left, player.world_right)
	player_return_position = player.global_position
	mission_started = true
	start_level_mission()
	if level_id != &"level_1":
		player.global_position = _mission_focus_position()
		_open_mission_window()


func _process(_delta: float) -> void:
	if InputManager.is_pause_pressed():
		_toggle_pause()
	if InputManager.is_interact_pressed() and GameManager.game_state in [GameManager.GameState.PLAYING, GameManager.GameState.MISSION]:
		_try_interact()
	if not mission_started and dialogue_available and GameManager.game_state == GameManager.GameState.PLAYING:
		if player.global_position.distance_to(mission_npc.global_position) < 115.0:
			_open_npc_dialogue()
	if mission_started:
		_update_mission()
	_update_interaction_hint()
	_update_world_object_feedback()


func _build_world() -> void:
	backdrop = LevelBackdrop.new()
	backdrop.background_path = _get_background_path()
	add_child(backdrop)
	player = LILI_SCENE.instantiate()
	player.position = Vector2(170, GROUND_BASELINE)
	add_child(player)
	mission_npc = NpcCharacter.new()
	mission_npc.character_name = npc_name
	mission_npc.body_color = npc_color
	mission_npc.texture_path = _get_npc_texture_path()
	mission_npc.position = Vector2(520, GROUND_BASELINE)
	mission_npc.tapped.connect(_on_npc_tapped)
	add_child(mission_npc)


func _build_interface() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var top_bar := ColorRect.new()
	top_bar.name = "GameplayTopBar"
	gameplay_top_bar = top_bar
	top_bar.color = Color("163350")
	# Lebar penuh mengikuti layar (penting di web, rasio layar bisa lebih lebar dari 1280).
	top_bar.anchor_left = 0.0
	top_bar.anchor_right = 1.0
	top_bar.anchor_top = 0.0
	top_bar.anchor_bottom = 0.0
	top_bar.offset_left = 0.0
	top_bar.offset_right = 0.0
	top_bar.offset_top = 0.0
	top_bar.offset_bottom = 82.0
	hud.add_child(top_bar)
	var title := Label.new()
	title.text = "%s — %s" % [level_title, lesson_text]
	title.position = Vector2(28, 14)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("fff0a1"))
	top_bar.add_child(title)
	mission_label = Label.new()
	mission_label.position = Vector2(30, 47)
	mission_label.size = Vector2(900, 28)
	mission_label.add_theme_font_size_override("font_size", 17)
	top_bar.add_child(mission_label)
	mission_hud_progress = ProgressBar.new()
	# Menempel ke sisi kanan bar.
	mission_hud_progress.anchor_left = 1.0
	mission_hud_progress.anchor_right = 1.0
	mission_hud_progress.offset_left = -318.0
	mission_hud_progress.offset_right = -58.0
	mission_hud_progress.offset_top = 55.0
	mission_hud_progress.offset_bottom = 69.0
	mission_hud_progress.show_percentage = false
	mission_hud_progress.visible = false
	var mission_track := StyleBoxFlat.new()
	mission_track.bg_color = Color("674a31")
	mission_track.set_corner_radius_all(7)
	mission_hud_progress.add_theme_stylebox_override("background", mission_track)
	var mission_fill := StyleBoxFlat.new()
	mission_fill.bg_color = Color("69cf35")
	mission_fill.set_corner_radius_all(7)
	mission_hud_progress.add_theme_stylebox_override("fill", mission_fill)
	top_bar.add_child(mission_hud_progress)
	var pause_button := TextureButton.new()
	pause_button.texture_normal = load("res://assets/ui/sheet/icons/icon_pause.png")
	pause_button.ignore_texture_size = true
	pause_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	# Menempel ke sisi kanan bar.
	pause_button.anchor_left = 1.0
	pause_button.anchor_right = 1.0
	pause_button.offset_left = -90.0
	pause_button.offset_right = -26.0
	pause_button.offset_top = 16.0
	pause_button.offset_bottom = 64.0
	_add_button_hover_effect(pause_button)
	pause_button.pressed.connect(_toggle_pause)
	top_bar.add_child(pause_button)
	interaction_hint_control = Control.new()
	interaction_hint_control.position = Vector2(180, 94)
	interaction_hint_control.size = Vector2(920, 64)
	interaction_hint_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interaction_hint_control.visible = false
	hud.add_child(interaction_hint_control)
	interaction_hint_outline = Polygon2D.new()
	interaction_hint_outline.color = Color("63351f")
	interaction_hint_control.add_child(interaction_hint_outline)
	interaction_hint_fill = Polygon2D.new()
	interaction_hint_fill.color = Color("fff0cf")
	interaction_hint_control.add_child(interaction_hint_fill)
	interaction_hint_gloss = Polygon2D.new()
	interaction_hint_gloss.color = Color(0.95, 0.67, 0.22, 0.34)
	interaction_hint_control.add_child(interaction_hint_gloss)
	interaction_hint = Label.new()
	interaction_hint.position = Vector2(70, 0)
	interaction_hint.size = Vector2(780, 64)
	interaction_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interaction_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var hint_font := SystemFont.new()
	hint_font.font_names = PackedStringArray(["Comic Sans MS", "Trebuchet MS"])
	hint_font.font_weight = 700
	interaction_hint.add_theme_font_override("font", hint_font)
	interaction_hint.add_theme_font_size_override("font_size", 18)
	interaction_hint.add_theme_color_override("font_color", Color("57351f"))
	interaction_hint.add_theme_constant_override("outline_size", 2)
	interaction_hint.add_theme_color_override("font_outline_color", Color("fffaf0"))
	interaction_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interaction_hint_control.add_child(interaction_hint)
	_build_touch_controls()
	_build_dialogue()
	_build_pause_panel()
	_build_mission_window()
	hero_window = HeroMissionWindow.new()
	hero_window.item_success.connect(_on_hero_item_success)
	hero_window.closed.connect(_on_hero_window_closed)
	hero_window.visible = false
	hud.add_child(hero_window)


func _build_touch_controls() -> void:
	for button_data in [["<", -1.0, 32.0], [">", 1.0, 154.0]]:
		var button := Button.new()
		button.text = button_data[0]
		button.position = Vector2(button_data[2], 625)
		button.size = Vector2(104, 70)
		button.add_theme_font_size_override("font_size", 32)
		_add_button_hover_effect(button)
		button.button_down.connect(InputManager.set_touch_direction.bind(button_data[1]))
		button.button_up.connect(InputManager.set_touch_direction.bind(0.0))
		button.add_to_group("touch_controls")
		hud.add_child(button)


func _build_dialogue() -> void:
	dialogue_art = TextureRect.new()
	dialogue_art.texture = load("res://assets/ui/dialog/dialog_template.png")
	dialogue_art.position = Vector2(260, 320)
	dialogue_art.size = Vector2(1774, 887)
	dialogue_art.scale = Vector2(760.0 / 1774.0, 380.0 / 887.0)
	dialogue_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dialogue_art.stretch_mode = TextureRect.STRETCH_SCALE
	dialogue_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_art.visible = false
	hud.add_child(dialogue_art)
	dialogue_title = Label.new()
	dialogue_title.position = Vector2(360, 369)
	dialogue_title.size = Vector2(198, 44)
	dialogue_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var dialogue_font := SystemFont.new()
	dialogue_font.font_names = PackedStringArray(["Comic Sans MS", "Trebuchet MS"])
	dialogue_font.font_weight = 700
	dialogue_title.add_theme_font_override("font", dialogue_font)
	dialogue_title.add_theme_font_size_override("font_size", 23)
	dialogue_title.add_theme_color_override("font_color", Color("fff9ee"))
	dialogue_title.add_theme_constant_override("outline_size", 6)
	dialogue_title.add_theme_color_override("font_outline_color", Color("542716"))
	dialogue_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_title.visible = false
	hud.add_child(dialogue_title)
	dialogue_text = Label.new()
	dialogue_text.position = Vector2(460, 453)
	dialogue_text.size = Vector2(490, 72)
	dialogue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.add_theme_font_override("font", dialogue_font)
	dialogue_text.add_theme_font_size_override("font_size", 19)
	dialogue_text.add_theme_color_override("font_color", Color("542716"))
	dialogue_text.add_theme_constant_override("outline_size", 5)
	dialogue_text.add_theme_color_override("font_outline_color", Color("fff8e9"))
	dialogue_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_text.visible = false
	hud.add_child(dialogue_text)
	dialogue_choices = HBoxContainer.new()
	dialogue_choices.position = Vector2(370, 547)
	dialogue_choices.size = Vector2(556, 84)
	dialogue_choices.alignment = BoxContainer.ALIGNMENT_CENTER
	dialogue_choices.add_theme_constant_override("separation", 8)
	dialogue_choices.visible = false
	hud.add_child(dialogue_choices)
	accept_button = Button.new()
	accept_button.custom_minimum_size = Vector2(274, 84)
	accept_button.tooltip_text = "Ya, bantu!"
	_style_dialogue_hit_button(accept_button, Color("48bd23"))
	accept_button.pressed.connect(func() -> void: DialogueManager.choose(true))
	dialogue_choices.add_child(accept_button)
	decline_button = Button.new()
	decline_button.custom_minimum_size = Vector2(274, 84)
	decline_button.tooltip_text = "Tidak sekarang"
	_style_dialogue_hit_button(decline_button, Color("f29418"))
	decline_button.pressed.connect(func() -> void: DialogueManager.choose(false))
	dialogue_choices.add_child(decline_button)


func _style_dialogue_hit_button(button: Button, hover_color: Color) -> void:
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(hover_color.r, hover_color.g, hover_color.b, 0.08)
	hover_style.set_corner_radius_all(36)
	button.add_theme_stylebox_override("hover", hover_style)
	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.20, 0.10, 0.03, 0.22)
	pressed_style.set_corner_radius_all(36)
	button.add_theme_stylebox_override("pressed", pressed_style)
func _style_action_button(button: Button, base_color: Color) -> void:
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = base_color.lightened(0.12) if state == "hover" else base_color.darkened(0.12) if state == "pressed" else base_color
		style.corner_radius_top_left = 14
		style.corner_radius_top_right = 14
		style.corner_radius_bottom_left = 14
		style.corner_radius_bottom_right = 14
		style.content_margin_left = 12
		style.content_margin_right = 12
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)


func _add_button_hover_effect(button: Control) -> void:
	button.mouse_entered.connect(func() -> void:
		var id := button.get_instance_id()
		if button_hover_tweens.has(id):
			(button_hover_tweens[id] as Tween).kill()
		button.pivot_offset = button.size * 0.5
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2(1.04, 1.04), 0.12)
		button_hover_tweens[id] = tween
	)
	button.mouse_exited.connect(func() -> void:
		var id := button.get_instance_id()
		if button_hover_tweens.has(id):
			(button_hover_tweens[id] as Tween).kill()
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2.ONE, 0.12)
		button_hover_tweens[id] = tween
	)


func _build_pause_panel() -> void:
	pause_overlay = ColorRect.new()
	pause_overlay.color = Color(0.03, 0.05, 0.06, 0.68)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.visible = false
	hud.add_child(pause_overlay)
	pause_panel = Control.new()
	var pause_width := 500.0
	pause_panel.position = Vector2((get_viewport_rect().size.x - pause_width) * 0.5, 15)
	pause_panel.size = Vector2(pause_width, 690)
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_panel.visible = false
	hud.add_child(pause_panel)
	var pause_art := TextureRect.new()
	pause_art.texture = load("res://assets/ui/sheet/pause_menu/panel_pause.png")
	pause_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pause_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pause_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_panel.add_child(pause_art)
	# The labels and icons are baked into panel_pause.png. These transparent
	# hit areas preserve the original actions without drawing a second UI layer.
	_add_pause_overlay_button(pause_panel, Rect2(72, 255, 356, 102), _toggle_pause)
	_add_pause_overlay_button(pause_panel, Rect2(72, 365, 356, 102), _open_pause_settings)
	_add_pause_overlay_button(pause_panel, Rect2(72, 477, 356, 102), _return_to_menu)

	var pause_style := StyleBoxFlat.new()
	pause_style.bg_color = Color("fff1d9f5")
	pause_style.border_color = Color("d39a3f")
	pause_style.set_border_width_all(3)
	pause_style.set_corner_radius_all(24)
	pause_style.shadow_color = Color(0, 0, 0, 0.35)
	pause_style.shadow_size = 14
	var settings_panel := PanelContainer.new()
	settings_panel.name = "PauseSettingsPanel"
	settings_panel.size = Vector2(680, 620)
	settings_panel.position = (get_viewport_rect().size - settings_panel.size) * 0.5
	settings_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	settings_panel.visible = false
	settings_panel.add_theme_stylebox_override("panel", pause_style)
	hud.add_child(settings_panel)
	var settings_content := VBoxContainer.new()
	settings_content.alignment = BoxContainer.ALIGNMENT_CENTER
	settings_content.add_theme_constant_override("separation", 8)
	settings_panel.add_child(settings_content)
	var settings_header := TextureRect.new()
	settings_header.texture = load("res://assets/ui/audio_settings/audio_header.png")
	settings_header.custom_minimum_size = Vector2(0, 145)
	settings_header.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	settings_header.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	settings_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_content.add_child(settings_header)
	_add_audio_slider(settings_content, "Volume Utama", "master_volume", AudioManager.set_master_volume)
	_add_audio_slider(settings_content, "Musik", "music_volume", AudioManager.set_music_volume)
	_add_audio_slider(settings_content, "Efek Suara", "sfx_volume", AudioManager.set_sfx_volume)
	var back := TextureButton.new()
	back.texture_normal = load("res://assets/ui/sheet/buttons/button_resume.png")
	back.texture_hover = load("res://assets/ui/sheet/buttons/button_resume.png")
	back.ignore_texture_size = true
	back.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	back.custom_minimum_size = Vector2(300, 86)
	back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back.pressed.connect(func() -> void:
		settings_panel.visible = false
		pause_panel.visible = true
	)
	settings_content.add_child(back)


func _add_pause_overlay_button(parent: Control, rect: Rect2, callback: Callable) -> void:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_add_button_hover_effect(button)
	button.pressed.connect(callback)
	parent.add_child(button)


func _add_audio_slider(container: VBoxContainer, title: String, setting: String, setter: Callable) -> void:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(580, 72)
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color("fff0cf")
	row_style.border_color = Color("e2b66b")
	row_style.set_border_width_all(2)
	row_style.set_corner_radius_all(24)
	row.add_theme_stylebox_override("panel", row_style)
	container.add_child(row)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	row.add_child(margin)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 14)
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(line)
	var icon := TextureRect.new()
	icon.texture = load(_audio_icon_path(setting))
	icon.custom_minimum_size = Vector2(58, 52)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(icon)
	var label := Label.new()
	label.text = "%s: %d%%" % [title, roundi(SaveManager.get_volume(setting) * 100.0)]
	label.custom_minimum_size = Vector2(180, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("6b351d"))
	line.add_child(label)
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(275, 38)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = SaveManager.get_volume(setting)
	slider.value_changed.connect(func(value: float) -> void:
		label.text = "%s: %d%%" % [title, roundi(value * 100.0)]
		setter.call(value)
	)
	var track := StyleBoxTexture.new()
	track.texture = load("res://assets/ui/audio_settings/audio_slider_track.png")
	track.texture_margin_left = 22.0
	track.texture_margin_right = 22.0
	track.texture_margin_top = 8.0
	track.texture_margin_bottom = 8.0
	slider.add_theme_stylebox_override("slider", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("62c92e")
	fill.set_corner_radius_all(18)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	slider.add_theme_icon_override("grabber", load("res://assets/ui/audio_settings/audio_slider_knob_small.png"))
	slider.add_theme_icon_override("grabber_highlight", load("res://assets/ui/audio_settings/audio_slider_knob_small.png"))
	line.add_child(slider)


func _audio_icon_path(setting_name: String) -> String:
	match setting_name:
		"master_volume": return "res://assets/ui/audio_settings/audio_icon_master.png"
		"music_volume": return "res://assets/ui/audio_settings/audio_icon_music_row.png"
		"sfx_volume": return "res://assets/ui/audio_settings/audio_icon_sfx.png"
		"voice_volume": return "res://assets/ui/audio_settings/audio_icon_voice.png"
	return "res://assets/ui/audio_settings/audio_icon_master.png"


func _open_pause_settings() -> void:
	pause_panel.visible = false
	var settings_panel := hud.get_node("PauseSettingsPanel") as PanelContainer
	settings_panel.visible = true


func _open_npc_dialogue() -> void:
	dialogue_available = false
	DialogueManager.show_choice(npc_name, npc_request)
	dialogue_title.text = npc_name
	dialogue_text.text = npc_request
	dialogue_art.visible = true
	dialogue_title.visible = true
	dialogue_text.visible = true
	dialogue_choices.visible = true


func _on_npc_tapped() -> void:
	AudioManager.play_sfx(AudioManager.SFX_UI_POP)
	if mission_started and not level_finished and level_id != &"level_1" and GameManager.game_state == GameManager.GameState.PLAYING:
		GameManager.start_mission()
		_open_mission_window()
		return
	if not mission_started and dialogue_available and GameManager.game_state == GameManager.GameState.PLAYING:
		_open_npc_dialogue()


func _on_dialogue_choice(accepted: bool) -> void:
	dialogue_art.visible = false
	dialogue_title.visible = false
	dialogue_text.visible = false
	dialogue_choices.visible = false
	if accepted:
		mission_npc.set_sad(false)
		mission_npc.play_happy_reaction()
		mission_started = true
		player_return_position = player.global_position
		start_level_mission()
		if level_id != &"level_1":
			player.global_position = _mission_focus_position()
			_open_mission_window()
	else:
		mission_npc.set_sad(true)
		mission_started = false
		LevelManager.complete_current_level()
		LevelManager.open_next_level()


func start_level_mission() -> void:
	pass


func _build_mission_window() -> void:
	mission_window = Control.new()
	mission_window.name = "HeroMissionWindow"
	mission_window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mission_window.visible = false
	mission_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(mission_window)
	var dim_overlay := ColorRect.new()
	dim_overlay.color = Color(0.025, 0.035, 0.05, 0.30)
	dim_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_window.add_child(dim_overlay)
	var mission_card := Panel.new()
	mission_card.name = "MissionCard"
	mission_card.position = Vector2(100, 92)
	mission_card.size = Vector2(1080, 536)
	mission_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("3b2b2255")
	card_style.border_color = Color("e6c277")
	card_style.set_border_width_all(3)
	card_style.set_corner_radius_all(28)
	card_style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	card_style.shadow_size = 18
	mission_card.add_theme_stylebox_override("panel", card_style)
	mission_window.add_child(mission_card)
	var card_accent := ColorRect.new()
	card_accent.position = Vector2(0, 0)
	card_accent.size = Vector2(1080, 10)
	card_accent.color = Color("f4c95d")
	card_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_card.add_child(card_accent)
	var kicker := Label.new()
	kicker.text = "PETUALANGAN MISI"
	kicker.position = Vector2(42, 28)
	kicker.size = Vector2(430, 30)
	kicker.add_theme_font_size_override("font_size", 16)
	kicker.add_theme_color_override("font_color", Color("f4d58b"))
	kicker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_card.add_child(kicker)
	mission_portrait = TextureRect.new()
	mission_portrait.name = "MissionPortrait"
	mission_portrait.position = Vector2(945, 18)
	mission_portrait.size = Vector2(82, 82)
	mission_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mission_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mission_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_card.add_child(mission_portrait)
	var how_to := Label.new()
	how_to.text = "Bantu temanmu dengan cara yang menyenangkan!"
	how_to.position = Vector2(42, 438)
	how_to.size = Vector2(700, 34)
	how_to.add_theme_font_size_override("font_size", 17)
	how_to.add_theme_color_override("font_color", Color("f9e9bd"))
	how_to.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_card.add_child(how_to)
	var top := ColorRect.new()
	top.name = "MissionHeader"
	top.color = Color("e91c2b18")
	top.position = Vector2(100, 92)
	top.size = Vector2(1080, 78)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_window.add_child(top)
	mission_title_label = Label.new()
	mission_title_label.position = Vector2(190, 16)
	mission_title_label.size = Vector2(840, 48)
	mission_title_label.add_theme_font_size_override("font_size", 30)
	mission_title_label.add_theme_color_override("font_color", Color("fff0a1"))
	top.add_child(mission_title_label)
	mission_back_button = Button.new()
	mission_back_button.text = "KEMBALI"
	mission_back_button.position = Vector2(18, 15)
	mission_back_button.size = Vector2(150, 48)
	mission_back_button.add_theme_font_size_override("font_size", 16)
	_style_action_button(mission_back_button, Color("698f68"))
	_add_button_hover_effect(mission_back_button)
	mission_back_button.pressed.connect(_close_mission_window)
	top.add_child(mission_back_button)
	var bottom := ColorRect.new()
	bottom.name = "MissionFooter"
	bottom.color = Color("e9163040")
	bottom.position = Vector2(100, 523)
	bottom.size = Vector2(1080, 105)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_window.add_child(bottom)
	mission_instruction_label = Label.new()
	mission_instruction_label.position = Vector2(134, 533)
	mission_instruction_label.size = Vector2(700, 52)
	mission_instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_instruction_label.add_theme_font_size_override("font_size", 19)
	mission_instruction_label.add_theme_color_override("font_color", Color.WHITE)
	mission_window.add_child(mission_instruction_label)
	mission_progress_label = Label.new()
	mission_progress_label.position = Vector2(850, 535)
	mission_progress_label.size = Vector2(145, 44)
	mission_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_progress_label.add_theme_font_size_override("font_size", 21)
	mission_progress_label.add_theme_color_override("font_color", Color("fff0a1"))
	mission_window.add_child(mission_progress_label)
	mission_progress_bar = ProgressBar.new()
	mission_progress_bar.position = Vector2(865, 581)
	mission_progress_bar.size = Vector2(115, 12)
	mission_progress_bar.show_percentage = false
	mission_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var progress_background := StyleBoxFlat.new()
	progress_background.bg_color = Color("294638")
	progress_background.corner_radius_top_left = 6
	progress_background.corner_radius_top_right = 6
	progress_background.corner_radius_bottom_left = 6
	progress_background.corner_radius_bottom_right = 6
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = Color("9de08e")
	progress_fill.corner_radius_top_left = 6
	progress_fill.corner_radius_top_right = 6
	progress_fill.corner_radius_bottom_left = 6
	progress_fill.corner_radius_bottom_right = 6
	mission_progress_bar.add_theme_stylebox_override("background", progress_background)
	mission_progress_bar.add_theme_stylebox_override("fill", progress_fill)
	mission_window.add_child(mission_progress_bar)
	mission_continue_button = Button.new()
	mission_continue_button.text = "LANJUTKAN PETUALANGAN"
	mission_continue_button.position = Vector2(1005, 548)
	mission_continue_button.size = Vector2(245, 48)
	mission_continue_button.add_theme_font_size_override("font_size", 17)
	_style_action_button(mission_continue_button, Color("56ad6d"))
	_add_button_hover_effect(mission_continue_button)
	mission_continue_button.pressed.connect(_continue_from_mission)
	mission_continue_button.visible = true
	mission_window.add_child(mission_continue_button)
	mission_completed_panel = PanelContainer.new()
	mission_completed_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	mission_completed_panel.position = Vector2(-230, -125)
	mission_completed_panel.size = Vector2(460, 250)
	mission_completed_panel.visible = false
	mission_completed_panel.pivot_offset = Vector2(230, 125)
	mission_window.add_child(mission_completed_panel)
	var completed_content := VBoxContainer.new()
	completed_content.alignment = BoxContainer.ALIGNMENT_CENTER
	completed_content.add_theme_constant_override("separation", 18)
	mission_completed_panel.add_child(completed_content)
	var completed_title := Label.new()
	completed_title.text = "MISI SELESAI!  * * *"
	completed_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	completed_title.add_theme_font_size_override("font_size", 30)
	completed_content.add_child(completed_title)
	var praise := Label.new()
	praise.text = "Hebat! Terima kasih sudah membantu teman-teman."
	praise.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	praise.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	completed_content.add_child(praise)
	var finish_button := Button.new()
	finish_button.text = "LANJUTKAN"
	finish_button.custom_minimum_size = Vector2(240, 52)
	_style_action_button(finish_button, Color("42b86b"))
	_add_button_hover_effect(finish_button)
	finish_button.pressed.connect(_continue_to_world)
	completed_content.add_child(finish_button)


func _open_mission_window() -> void:
	GameManager.start_mission()
	AudioManager.play_full_game_music()
	_set_gameplay_hud_visible(false)
	if hero_mode_enabled():
		mission_window.visible = false
		mission_npc.visible = false
		hero_window.open_mission(level_id, _mission_window_title(), _mission_instruction(), _mission_portrait_path(), npc_name, MissionManager.current_progress, MissionManager.get_level_state())
		_set_mission_name_labels(false)
		return
	mission_window.visible = true
	mission_window.modulate.a = 0.0
	var open_tween := create_tween()
	open_tween.tween_property(mission_window, "modulate:a", 1.0, 0.28)
	_set_mission_name_labels(true)
	mission_title_label.text = _mission_window_title()
	mission_portrait.texture = load(_mission_portrait_path()) if ResourceLoader.exists(_mission_portrait_path()) else null
	mission_instruction_label.text = _mission_instruction()
	mission_continue_button.visible = true
	mission_completed_panel.visible = false
	_update_mission_window_progress()
	mission_back_button.grab_focus()


func _close_mission_window() -> void:
	if hero_mode_enabled() and hero_window.visible:
		return
	if not mission_window.visible or level_finished:
		return
	mission_window.visible = false
	_set_gameplay_hud_visible(true)
	_set_mission_name_labels(false)
	GameManager.resume_gameplay()
	AudioManager.play_full_game_music()
	player.global_position = player_return_position
	show_notice("Misi dijeda. Dekati %s dan pilih Ya, Bantu! untuk melanjutkan." % npc_name)


func _continue_from_mission() -> void:
	_continue_to_world()


func _continue_to_world() -> void:
	if hero_mode_enabled():
		hero_window.visible = false
	mission_window.visible = false
	mission_npc.visible = true
	_set_gameplay_hud_visible(true)
	mission_npc.visible = true
	_set_mission_name_labels(false)
	AudioManager.play_full_game_music()
	if level_finished:
		show_notice("Terima kasih sudah membantu! Bersiap menuju petualangan berikutnya...")
		GameManager.resume_gameplay()
	else:
		GameManager.resume_gameplay()


func _set_gameplay_hud_visible(is_visible: bool) -> void:
	if is_instance_valid(gameplay_top_bar):
		gameplay_top_bar.visible = is_visible
	if is_instance_valid(interaction_hint_control) and not is_visible:
		interaction_hint_control.visible = false
	for control in get_tree().get_nodes_in_group("touch_controls"):
		if is_instance_valid(control):
			control.visible = is_visible


func hero_mode_enabled() -> bool:
	return level_id != &"level_1"


func _on_hero_item_success(next_state: Dictionary) -> void:
	if not hero_mode_enabled() or level_finished:
		return
	var state := next_state.duplicate(true)
	state["player_x"] = player.global_position.x
	MissionManager.save_level_state(state)
	match level_id:
		&"level_2": AudioManager.play_sfx(AudioManager.SFX_STRAWBERRY)
		&"level_3": AudioManager.play_sfx(AudioManager.SFX_WOOD_PLANK)
		&"level_4": AudioManager.play_sfx(AudioManager.SFX_CLEAN_SPARKLE)
		&"level_5": AudioManager.play_sfx(AudioManager.SFX_WATER_SPLASH)
	LevelManager.register_help_action()
	MissionManager.advance()


func _on_hero_window_closed() -> void:
	if level_finished:
		LevelManager.open_next_level()
		return
	_set_gameplay_hud_visible(true)
	GameManager.resume_gameplay()



func _mission_window_title() -> String:
	return "AYO BANTU TEMAN!"


func _mission_portrait_path() -> String:
	return _get_npc_texture_path()


func _mission_instruction() -> String:
	return "Ikuti petunjuk dan bantu warga menyelesaikan misi."


func _mission_focus_position() -> Vector2:
	return player_return_position


func _set_mission_name_labels(is_visible: bool) -> void:
	if is_instance_valid(player) and is_instance_valid(player.name_label):
		player.name_label.visible = is_visible
	for character in get_tree().get_nodes_in_group("mission_characters"):
		if is_instance_valid(character) and character.is_inside_tree():
			if character.has_method("_set_name_label_visibility"):
				character._set_name_label_visibility(is_visible)


func _update_mission_window_progress() -> void:
	if mission_progress_label != null:
		mission_progress_label.text = "%d / %d" % [MissionManager.current_progress, MissionManager.target_progress]
	if mission_progress_bar != null:
		mission_progress_bar.max_value = maxf(float(MissionManager.target_progress), 1.0)
		mission_progress_bar.value = MissionManager.current_progress


func _update_mission() -> void:
	pass


func add_interactable(world_object: WorldObject) -> void:
	interactables.append(world_object)
	add_child(world_object)


func _try_interact() -> void:
	var closest: WorldObject
	var closest_distance := INF
	for world_object: WorldObject in interactables:
		if not is_instance_valid(world_object) or world_object.draggable:
			continue
		var distance := player.global_position.distance_to(world_object.global_position)
		if distance < closest_distance:
			closest = world_object
			closest_distance = distance
	if closest != null and closest_distance < 105.0:
		closest.activate()


func _update_world_object_feedback() -> void:
	var overlays_block_input := GameManager.game_state == GameManager.GameState.PAUSED or dialogue_art.visible or mission_window.visible or (is_instance_valid(hero_window) and hero_window.visible)
	var nearest: WorldObject
	var nearest_distance := 105.0
	var nearest_draggable: WorldObject
	var nearest_draggable_distance := 105.0
	var world_objects := get_tree().get_nodes_in_group("world_objects")
	for node in world_objects:
		var world_object := node as WorldObject
		if not is_instance_valid(world_object):
			continue
		var distance := player.global_position.distance_to(world_object.global_position)
		var has_active_interaction := world_object.draggable or world_object in interactables
		var focused := not overlays_block_input and has_active_interaction and not world_object.is_collected and distance < 105.0
		if focused and world_object.draggable:
			if distance < nearest_draggable_distance:
				nearest_draggable = world_object
				nearest_draggable_distance = distance
		elif focused:
			if distance < nearest_distance:
				nearest = world_object
				nearest_distance = distance
	if not is_instance_valid(nearest):
		nearest = nearest_draggable
	for node in world_objects:
		var world_object := node as WorldObject
		if is_instance_valid(world_object):
			world_object.set_proximity_highlight(world_object == nearest)
	var near_npc := not overlays_block_input and not mission_started and player.global_position.distance_to(mission_npc.global_position) < 115.0
	mission_npc.set_interaction_indicator(near_npc)


func _update_interaction_hint() -> void:
	if not is_instance_valid(interaction_hint_control):
		return
	if GameManager.game_state == GameManager.GameState.PAUSED or dialogue_art.visible or mission_window.visible or not gameplay_top_bar.visible:
		_set_interaction_hint_visible(false)
		return
	var message := interaction_hint_message
	if message.is_empty() and not mission_started and dialogue_available:
		message = "Dekati %s untuk memulai petualangan." % npc_name
	if message.is_empty():
		_set_interaction_hint_visible(false)
		return
	var points_right := mission_npc.global_position.x >= player.global_position.x
	if points_right:
		interaction_hint_outline.polygon = PackedVector2Array([Vector2(0, 0), Vector2(838, 0), Vector2(920, 32), Vector2(838, 64), Vector2(0, 64)])
		interaction_hint_fill.polygon = PackedVector2Array([Vector2(5, 5), Vector2(836, 5), Vector2(908, 32), Vector2(836, 59), Vector2(5, 59)])
		interaction_hint_gloss.polygon = PackedVector2Array([Vector2(18, 8), Vector2(810, 8), Vector2(850, 17), Vector2(810, 18), Vector2(18, 18)])
	else:
		interaction_hint_outline.polygon = PackedVector2Array([Vector2(920, 0), Vector2(82, 0), Vector2(0, 32), Vector2(82, 64), Vector2(920, 64)])
		interaction_hint_fill.polygon = PackedVector2Array([Vector2(915, 5), Vector2(84, 5), Vector2(12, 32), Vector2(84, 59), Vector2(915, 59)])
		interaction_hint_gloss.polygon = PackedVector2Array([Vector2(902, 8), Vector2(110, 8), Vector2(70, 17), Vector2(110, 18), Vector2(902, 18)])
	interaction_hint.text = message
	_set_interaction_hint_visible(true)


func _set_interaction_hint_visible(is_visible: bool) -> void:
	if interaction_hint_control.visible == is_visible:
		return
	interaction_hint_control.visible = is_visible
	if interaction_hint_pulse != null and interaction_hint_pulse.is_running():
		interaction_hint_pulse.kill()
	if is_visible:
		interaction_hint_control.modulate.a = 1.0
		interaction_hint_pulse = create_tween().set_loops()
		interaction_hint_pulse.tween_property(interaction_hint_control, "modulate:a", 0.88, 0.7)
		interaction_hint_pulse.tween_property(interaction_hint_control, "modulate:a", 1.0, 0.7)
	else:
		interaction_hint_control.modulate.a = 1.0


func _on_mission_started(title: String, target: int) -> void:
	mission_label.text = "%s (0/%d)" % [title, target]
	mission_hud_progress.max_value = maxf(float(target), 1.0)
	mission_hud_progress.value = 0.0
	mission_hud_progress.visible = true


func _on_mission_progress(current: int, target: int) -> void:
	mission_label.text = "%s (%d/%d)" % [MissionManager.mission_title, current, target]
	mission_hud_progress.max_value = maxf(float(target), 1.0)
	if mission_hud_progress_tween != null and mission_hud_progress_tween.is_running():
		mission_hud_progress_tween.kill()
	mission_hud_progress_tween = create_tween()
	mission_hud_progress_tween.tween_property(mission_hud_progress, "value", current, 0.22)
	_update_mission_window_progress()


func _on_mission_completed() -> void:
	finish_level()


func finish_level() -> void:
	if level_finished:
		return
	level_finished = true
	for character in get_tree().get_nodes_in_group("mission_characters"):
		if is_instance_valid(character) and character.has_method("play_happy_reaction"):
			character.play_happy_reaction()
	LevelManager.register_level_helped(level_id)
	AudioManager.play_sfx(AudioManager.SFX_MISSION_COMPLETE)
	mission_started = false
	player.global_position = player_return_position
	backdrop.make_bright()
	if level_id == &"level_3":
		backdrop.set_background("res://assets/backgrounds/bg_level_03_river_repaired.png")
	if level_id == &"level_5":
		backdrop.set_background("res://assets/backgrounds/bg_level_05_garden_clean.png")
	LevelManager.complete_current_level()
	GameManager.show_dialogue()
	mission_window.visible = false
	_set_gameplay_hud_visible(false)
	hero_window.show_completed(MissionManager.mission_title)


func show_notice(message: String) -> void:
	interaction_hint_message = message
	_update_interaction_hint()


func _get_background_path() -> String:
	return {
		&"level_1": "res://assets/backgrounds/bg_level_01_forest.png",
		&"level_2": "res://assets/backgrounds/bg_level_02_meadow.png",
		&"level_3": "res://assets/backgrounds/bg_level_03_river.png",
		&"level_4": "res://assets/backgrounds/bg_level_04_festival.png",
		&"level_5": "res://assets/backgrounds/bg_level_05_garden_dirty.png",
	}.get(level_id, "")


func _get_npc_texture_path() -> String:
	if npc_name.contains("Tutu"):
		return "res://assets/characters/tutu/tutu_01.png"
	if npc_name.contains("Momo"):
		return "res://assets/characters/momo/momo_01.png"
	if npc_name.contains("Rusa"):
		return "res://assets/characters/villagers/deer/deer_01.png"
	return ""


func _toggle_pause() -> void:
	GameManager.toggle_pause()
	pause_panel.visible = GameManager.game_state == GameManager.GameState.PAUSED
	if pause_overlay != null:
		pause_overlay.visible = pause_panel.visible


func _return_to_menu() -> void:
	if hero_mode_enabled() and is_instance_valid(hero_window) and hero_window.visible:
		return
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", "res://scenes/Main.tscn")
