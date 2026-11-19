extends Control

@onready var trophy_panel: PanelContainer = %TrophyPanel
@onready var title_panel: PanelContainer = %Title
@onready var title_label: Label = %TitleText
@onready var stars: HBoxContainer = %Stars
@onready var award_panel: PanelContainer = %Award
@onready var award_label: Label = %AwardText
@onready var subtitle_label: Label = %Subtitle
@onready var play_again_button: Button = %PlayAgainButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	AudioManager.play_theme(&"ending")
	GameManager.show_ending()
	SaveManager.set_all_levels_completed(true)
	var rating_stars := LevelManager.get_rating_stars()
	_award_for_rating(rating_stars)
	_build_stars(rating_stars)
	_style_panel(trophy_panel, Color("fff0cf"), Color("88451f"), 38)
	_style_panel(title_panel, Color("e99131"), Color("713718"), 28)
	_style_panel(award_panel, Color("e99131"), Color("713718"), 24)
	_style_label(title_label, 38, Color("fff8e9"), Color("63351f"))
	_style_label(award_label, 34, Color("fff8e9"), Color("63351f"))
	_style_label(subtitle_label, 24, Color("63351f"), Color("fff8e9"))
	_style_button(play_again_button, Color("ed941d"), "Main Lagi", true)
	_style_button(menu_button, Color("64c92b"), "Kembali ke Menu", false)


func _award_for_rating(rating_stars: int) -> void:
	match rating_stars:
		3:
			award_label.text = "Luar Biasa!"
		2:
			award_label.text = "Bagus Sekali!"
		_:
			award_label.text = "Hebat!"


func _build_stars(count: int) -> void:
	var atlas := load("res://assets/ui/sheet/icons/icon_star.png") as Texture2D
	for index in range(count):
		var star := TextureRect.new()
		var cropped_star := AtlasTexture.new()
		cropped_star.atlas = atlas
		cropped_star.region = Rect2(0, 0, 98, 108) if index % 2 == 0 else Rect2(98, 0, 99, 108)
		star.texture = cropped_star
		star.custom_minimum_size = Vector2(108, 116)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		stars.add_child(star)
	stars.pivot_offset = Vector2(348, 62)


func _style_panel(panel: PanelContainer, fill: Color, edge: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(5)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.16, 0.08, 0.03, 0.4)
	style.shadow_size = 18
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", style)


func _style_label(label: Label, size: int, color: Color, outline: Color) -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Trebuchet MS", "Arial"])
	font.font_weight = 700
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", outline)


func _style_button(button: Button, fill: Color, text_value: String, use_home_icon: bool) -> void:
	button.text = ""
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = fill
		if state == "hover" or state == "focus":
			style.bg_color = fill.lightened(0.12)
		elif state == "pressed":
			style.bg_color = fill.darkened(0.12)
		style.border_color = Color("63351f")
		style.set_border_width_all(4)
		style.set_corner_radius_all(38)
		style.content_margin_left = 18
		style.content_margin_right = 18
		button.add_theme_stylebox_override(state, style)
	var line := HBoxContainer.new()
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line.offset_left = 14
	line.offset_right = -14
	line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	line.add_theme_constant_override("separation", 12)
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(line)
	if use_home_icon:
		var icon := TextureRect.new()
		icon.texture = load("res://assets/ui/sheet/icons/icon_home.png")
		icon.custom_minimum_size = Vector2(40, 48)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(icon)
	else:
		var menu_icon := GridContainer.new()
		menu_icon.columns = 2
		menu_icon.custom_minimum_size = Vector2(33, 33)
		menu_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		menu_icon.add_theme_constant_override("h_separation", 3)
		menu_icon.add_theme_constant_override("v_separation", 3)
		menu_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for _cell in range(4):
			var square := ColorRect.new()
			square.color = Color("fff5dd")
			square.custom_minimum_size = Vector2(15, 15)
			square.mouse_filter = Control.MOUSE_FILTER_IGNORE
			menu_icon.add_child(square)
		line.add_child(menu_icon)
	var label := Label.new()
	label.text = text_value
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("fff8e9"))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color("63351f"))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Trebuchet MS", "Arial"])
	font.font_weight = 700
	label.add_theme_font_override("font", font)
	line.add_child(label)


func _process(_delta: float) -> void:
	stars.rotation = sin(Time.get_ticks_msec() * 0.005) * 0.08


func _on_play_again_pressed() -> void:
	AudioManager.play_sfx(AudioManager.SFX_UI_POP)
	GameManager.start_new_game()


func _on_menu_pressed() -> void:
	AudioManager.play_sfx(AudioManager.SFX_UI_POP)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/Main.tscn")
