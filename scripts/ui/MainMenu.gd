extends Control

@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton
@onready var status_label: Label = %StatusLabel

var popup_panel: PanelContainer
var popup_dim: ColorRect
var cloud_time := 0.0
var music_muted := false
var button_hover_tweens: Dictionary = {}


func _ready() -> void:
	AudioManager.play_full_game_music()
	continue_button.disabled = not SaveManager.has_saved_progress()
	_build_reference_menu()
	_build_popup()
	_style_menu_buttons()


func _build_reference_menu() -> void:
	# Use the supplied finished village illustration as the menu backdrop.
	var village_background := get_node_or_null("VillageBackground") as TextureRect
	if village_background != null:
		village_background.texture = load("res://assets/ui/main_menu_reference/fantasy_village_menu.png")
		village_background.visible = true
		village_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		village_background.stretch_mode = TextureRect.STRETCH_SCALE
	for node_name in ["Sky", "Atmosphere", "Meadow", "MenuSafeShade", "CloudLeft", "CloudRight"]:
		var node := get_node_or_null(node_name) as Control
		if node != null:
			node.visible = false
	var old_container := get_node_or_null("CenterContainer") as Control
	if old_container != null:
		old_container.visible = false

	var root := Control.new()
	root.name = "ReferenceMenu"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)
	# Coordinates follow the project's 1280x720 design canvas. Do not scale
	# them by the embedded editor viewport; that makes the buttons oversized.
	var button_width := 440.0
	var button_height := 98.0
	var button_x := 145.0
	var button_y := 290.0
	var button_gap := 6.0
	var play_button := _add_reference_button(root, "res://assets/ui/main_menu_reference/play.png", Rect2(button_x, button_y, button_width, button_height), _on_start_pressed, true)
	_add_reference_button(root, "res://assets/ui/main_menu_reference/settings.png", Rect2(button_x, button_y + (button_height + button_gap), button_width, button_height), _on_settings_pressed, true)
	_add_reference_button(root, "res://assets/ui/sheet/buttons/button_guide.png", Rect2(button_x, button_y + 2.0 * (button_height + button_gap), button_width, button_height), _on_guide_pressed, true)
	_add_reference_button(root, "res://assets/ui/main_menu_reference/exit.png", Rect2(button_x, button_y + 3.0 * (button_height + button_gap), button_width, button_height), _on_exit_pressed, true)
	_add_reference_button(root, "", Rect2(975, 18, 82, 82), _on_settings_pressed, true)
	_add_reference_button(root, "", Rect2(1065, 18, 82, 82), _toggle_music, true)
	_add_reference_button(root, "", Rect2(1155, 18, 82, 82), _on_exit_pressed, true)
	play_button.grab_focus()


func _add_reference_button(parent: Control, texture_path: String, rect: Rect2, callback: Callable, enabled: bool) -> Button:
	var visual := TextureRect.new()
	if not texture_path.is_empty():
		visual.texture = load(texture_path)
	visual.position = rect.position
	visual.size = rect.size
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_SCALE
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.visible = false
	parent.add_child(visual)

	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.flat = true
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _process(delta: float) -> void:
	cloud_time += delta
	var left_cloud := get_node_or_null("CloudLeft") as Control
	var right_cloud := get_node_or_null("CloudRight") as Control
	if left_cloud != null:
		left_cloud.position.x = 72.0 + sin(cloud_time * 0.08) * 18.0
	if right_cloud != null:
		right_cloud.position.x = -330.0 + cos(cloud_time * 0.07) * 20.0


func _style_menu_buttons() -> void:
	var button_colors := {
		"StartButton": Color("b78650"),
		"ContinueButton": Color("698b66"),
		"SettingsButton": Color("7e9b79"),
		"ExitButton": Color("9a6f57"),
	}
	for button_name in button_colors:
		var button := get_node_or_null("CenterContainer/MenuPanel/Content/%s" % button_name) as Button
		if button == null:
			continue
		button.add_theme_color_override("font_color", Color("fff8df"))
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_disabled_color", Color(1.0, 1.0, 1.0, 0.42))
		for state in ["normal", "hover", "pressed", "disabled"]:
			var style := StyleBoxFlat.new()
			style.bg_color = button_colors[button_name]
			if state == "hover":
				style.bg_color = style.bg_color.lightened(0.12)
			elif state == "pressed":
				style.bg_color = style.bg_color.darkened(0.12)
			elif state == "disabled":
				style.bg_color = Color("56685a")
			style.corner_radius_top_left = 12
			style.corner_radius_top_right = 12
			style.corner_radius_bottom_left = 12
			style.corner_radius_bottom_right = 12
			style.content_margin_top = 10
			style.content_margin_bottom = 10
			button.add_theme_stylebox_override(state, style)


func _on_start_pressed() -> void:
	GameManager.start_new_game()


func _on_continue_pressed() -> void:
	GameManager.continue_game()


func _on_settings_pressed() -> void:
	_show_settings()


func _on_guide_pressed() -> void:
	_clear_popup()
	popup_panel.size = Vector2(1040, 660)
	popup_panel.position = (get_viewport_rect().size - popup_panel.size) * 0.5
	var inset := MarginContainer.new()
	for margin_name in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		inset.add_theme_constant_override(margin_name, 28)
	popup_panel.add_child(inset)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	inset.add_child(content)

	var title_panel := PanelContainer.new()
	title_panel.custom_minimum_size = Vector2(0, 88)
	var title_style := StyleBoxFlat.new()
	title_style.bg_color = Color("e89535")
	title_style.border_color = Color("753b1e")
	title_style.set_border_width_all(4)
	title_style.set_corner_radius_all(28)
	title_style.shadow_color = Color(0.27, 0.12, 0.04, 0.35)
	title_style.shadow_size = 8
	title_panel.add_theme_stylebox_override("panel", title_style)
	content.add_child(title_panel)
	var title := Label.new()
	title.text = "Panduan Bermain"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("fff7e8"))
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_color_override("font_outline_color", Color("63351f"))
	var display_font := SystemFont.new()
	display_font.font_names = PackedStringArray(["Trebuchet MS", "Arial"])
	display_font.font_weight = 700
	title.add_theme_font_override("font", display_font)
	title_panel.add_child(title)

	_add_guide_row(content, "Bergerak dengan A / D atau tombol arah.", "", ["A", "D"])
	_add_guide_row(content, "Dekati warga untuk memulai misi.", "res://assets/ui/tutorial_hand.svg")
	_add_guide_row(content, "Gunakan E atau sentuh objek untuk berinteraksi.", "res://assets/ui/sheet/icons/icon_star.png", ["E"])
	_add_guide_row(content, "Ikuti petunjuk di setiap level dan bantu warga Desa Ajaib!", "res://assets/objects/mission/obj_fruit_basket_01.png")

	var done := Button.new()
	done.text = "Selesai"
	done.custom_minimum_size = Vector2(420, 72)
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done.add_theme_font_override("font", display_font)
	done.add_theme_font_size_override("font_size", 30)
	done.add_theme_color_override("font_color", Color("fff8e9"))
	done.add_theme_constant_override("outline_size", 3)
	done.add_theme_color_override("font_outline_color", Color("315220"))
	done.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]:
		var button_style := StyleBoxFlat.new()
		button_style.bg_color = Color("7fce35")
		if state == "hover" or state == "focus":
			button_style.bg_color = Color("98dc48")
		elif state == "pressed":
			button_style.bg_color = Color("65ac2c")
		button_style.border_color = Color("28551f")
		button_style.set_border_width_all(4)
		button_style.set_corner_radius_all(36)
		done.add_theme_stylebox_override(state, button_style)
	done.pressed.connect(_hide_popup)
	content.add_child(done)
	_show_popup_layer()


func _add_guide_row(container: VBoxContainer, description: String, icon_path: String, key_labels: Array[String] = []) -> void:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 96)
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color("ffdfa0")
	row_style.border_color = Color("edc274")
	row_style.set_border_width_all(2)
	row_style.set_corner_radius_all(38)
	row.add_theme_stylebox_override("panel", row_style)
	container.add_child(row)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	row.add_child(margin)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 28)
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(line)
	var visual := HBoxContainer.new()
	visual.custom_minimum_size = Vector2(210, 0)
	visual.alignment = BoxContainer.ALIGNMENT_CENTER
	visual.add_theme_constant_override("separation", 8)
	line.add_child(visual)
	for index in range(key_labels.size()):
		_add_guide_key(visual, key_labels[index], Color("e45c44") if index == 0 else Color("438ae4"))
	if not icon_path.is_empty():
		var icon := TextureRect.new()
		icon.texture = load(icon_path)
		icon.custom_minimum_size = Vector2(76, 76)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.add_child(icon)
	var text := Label.new()
	text.text = description
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_override("font", SystemFont.new())
	text.add_theme_font_size_override("font_size", 25)
	text.add_theme_color_override("font_color", Color("63351f"))
	text.add_theme_constant_override("outline_size", 2)
	text.add_theme_color_override("font_outline_color", Color("fff4dc"))
	line.add_child(text)


func _add_guide_key(container: HBoxContainer, key_text: String, key_color: Color) -> void:
	var key_panel := PanelContainer.new()
	key_panel.custom_minimum_size = Vector2(62, 62)
	var key_style := StyleBoxFlat.new()
	key_style.bg_color = key_color
	key_style.border_color = Color("63351f")
	key_style.set_border_width_all(4)
	key_style.set_corner_radius_all(14)
	key_style.shadow_color = Color(0.2, 0.1, 0.04, 0.28)
	key_style.shadow_size = 4
	key_panel.add_theme_stylebox_override("panel", key_style)
	container.add_child(key_panel)
	var key_label := Label.new()
	key_label.text = key_text
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 34)
	key_label.add_theme_color_override("font_color", Color.WHITE)
	key_label.add_theme_constant_override("outline_size", 3)
	key_label.add_theme_color_override("font_outline_color", Color("63351f"))
	key_panel.add_child(key_label)


func _on_exit_pressed() -> void:
	get_tree().quit()


func _toggle_music() -> void:
	music_muted = not music_muted
	if music_muted:
		AudioManager.stop_music()
	else:
		AudioManager.play_full_game_music()


func _build_popup() -> void:
	popup_dim = ColorRect.new()
	popup_dim.color = Color(0.02, 0.04, 0.05, 0.62)
	popup_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_dim.visible = false
	add_child(popup_dim)
	popup_panel = PanelContainer.new()
	popup_panel.size = Vector2(680, 600)
	popup_panel.position = (get_viewport_rect().size - popup_panel.size) * 0.5
	popup_panel.visible = false
	var popup_style := StyleBoxFlat.new()
	popup_style.bg_color = Color("fff1d9f5")
	popup_style.border_color = Color("d39a3f")
	popup_style.set_border_width_all(3)
	popup_style.set_corner_radius_all(24)
	popup_style.shadow_color = Color(0, 0, 0, 0.4)
	popup_style.shadow_size = 16
	popup_panel.add_theme_stylebox_override("panel", popup_style)
	add_child(popup_panel)


func _show_settings() -> void:
	_clear_popup()
	popup_panel.size = Vector2(680, 600)
	popup_panel.position = (get_viewport_rect().size - popup_panel.size) * 0.5
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(620, 0)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 8)
	popup_panel.add_child(content)
	var audio_header := TextureRect.new()
	audio_header.texture = load("res://assets/ui/audio_settings/audio_header.png")
	# Keep the complete supplied sign visible, with enough vertical room for its
	# lettering and wood edge at the popup's rendered width.
	audio_header.custom_minimum_size = Vector2(0, 145)
	audio_header.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	audio_header.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	audio_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(audio_header)
	_add_volume_slider(content, "Volume Utama", "master_volume", AudioManager.set_master_volume)
	_add_volume_slider(content, "Musik", "music_volume", AudioManager.set_music_volume)
	_add_volume_slider(content, "Efek Suara", "sfx_volume", AudioManager.set_sfx_volume)
	_add_popup_button(content, "Kembali", _hide_popup)
	_show_popup_layer()


func _add_popup_title(container: VBoxContainer, text_value: String) -> void:
	var title := Label.new()
	title.text = text_value
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	container.add_child(title)


func _add_volume_slider(container: VBoxContainer, label_text: String, setting_name: String, callback: Callable) -> void:
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
	icon.texture = load(_audio_icon_path(setting_name))
	icon.custom_minimum_size = Vector2(58, 52)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(icon)
	var label := Label.new()
	label.text = "%s: %d%%" % [label_text, roundi(SaveManager.get_volume(setting_name) * 100.0)]
	label.add_theme_font_size_override("font_size", 19)
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
	slider.value = SaveManager.get_volume(setting_name)
	slider.value_changed.connect(func(value: float) -> void:
		label.text = "%s: %d%%" % [label_text, roundi(value * 100.0)]
		callback.call(value)
	)
	_style_audio_slider(slider)
	line.add_child(slider)


func _audio_icon_path(setting_name: String) -> String:
	match setting_name:
		"master_volume": return "res://assets/ui/audio_settings/audio_icon_master.png"
		"music_volume": return "res://assets/ui/audio_settings/audio_icon_music_row.png"
		"sfx_volume": return "res://assets/ui/audio_settings/audio_icon_sfx.png"
		"voice_volume": return "res://assets/ui/audio_settings/audio_icon_voice.png"
	return "res://assets/ui/audio_settings/audio_icon_master.png"


func _style_audio_slider(slider: HSlider) -> void:
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


func _add_popup_button(container: VBoxContainer, text_value: String, callback: Callable) -> void:
	if text_value == "Kembali":
		var back := TextureButton.new()
		back.texture_normal = load("res://assets/ui/sheet/buttons/button_home.png")
		back.texture_hover = load("res://assets/ui/sheet/buttons/button_home.png")
		back.ignore_texture_size = true
		back.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		back.custom_minimum_size = Vector2(300, 86)
		back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_add_button_hover_effect(back)
		back.pressed.connect(callback)
		container.add_child(back)
		return
	if text_value == "Selesai":
		var done := TextureButton.new()
		done.texture_normal = load("res://assets/ui/audio_settings/audio_done_button.png")
		done.ignore_texture_size = true
		done.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		done.custom_minimum_size = Vector2(300, 72)
		done.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_add_button_hover_effect(done)
		done.pressed.connect(callback)
		container.add_child(done)
		return
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(260, 55)
	button.add_theme_font_size_override("font_size", 20)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("6b956a")
	style.set_corner_radius_all(14)
	button.add_theme_stylebox_override("normal", style)
	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = hover_style.bg_color.lightened(0.16)
	button.add_theme_stylebox_override("hover", hover_style)
	var pressed_style := style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = pressed_style.bg_color.darkened(0.12)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	_add_button_hover_effect(button)
	button.pressed.connect(callback)
	container.add_child(button)


func _add_button_hover_effect(button: Control) -> void:
	button.mouse_entered.connect(func() -> void:
		var id := button.get_instance_id()
		if button_hover_tweens.has(id):
			(button_hover_tweens[id] as Tween).kill()
			button.pivot_offset = button.size * 0.5
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2(1.045, 1.045), 0.12)
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


func _clear_popup() -> void:
	for child: Node in popup_panel.get_children():
		child.queue_free()


func _hide_popup() -> void:
	popup_panel.visible = false
	popup_dim.visible = false


func _show_popup_layer() -> void:
	popup_dim.visible = true
	popup_panel.visible = true
