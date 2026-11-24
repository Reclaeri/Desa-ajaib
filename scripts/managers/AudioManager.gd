extends Node
## AudioManager - Desa Ajaib (For Mother)
## Versi ramah anak SD kelas 1-3:
## - Musik otomatis mengecil (ducking) saat suara narasi/voice diputar
## - Efek suara punya variasi pitch kecil supaya tidak membosankan
## - Footstep dibatasi supaya tidak "spam"
## - Transisi musik tidak bentrok (tween lama dihentikan)
## - Fungsi pendek siap pakai: play_click(), play_success(), dst.

const MUSIC_THEMES := {
	&"menu": preload("res://assets/audio/music/music_menu.wav"),
	&"mission": preload("res://assets/audio/music/music_mission.wav"),
	&"ending": preload("res://assets/audio/music/music_ending.wav"),
}
const FULL_GAME_MUSIC := preload("res://assets/audio/music/music_studiokolomna_cute_piano.mp3")
const SFX_FOOTSTEP := preload("res://assets/audio/sfx/sfx_step.mp3")
const SFX_UI_POP := preload("res://assets/audio/sfx/sfx_button_click.mp3")
const SFX_STRAWBERRY := preload("res://assets/audio/sfx/sfx_strawberry.wav")
const SFX_WOOD_PLANK := preload("res://assets/audio/sfx/sfx_wood_plank.wav")
const SFX_CLEAN_SPARKLE := preload("res://assets/audio/sfx/sfx_clean_sparkle.wav")
const SFX_WATER_SPLASH := preload("res://assets/audio/sfx/sfx_water_splash.wav")
const SFX_MISSION_COMPLETE := preload("res://assets/audio/sfx/sfx_mission_complete.wav")

const SFX_POOL_SIZE := 8
const SILENT_DB := -48.0
const START_FADE_DB := -36.0
const FADE_OUT_TIME := 0.25
const FADE_IN_TIME := 0.6
const DUCK_DB := -9.0            # musik mengecil saat narasi berbicara
const DUCK_TIME := 0.2
const DEFAULT_PITCH_VARIATION := 0.06

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var voice_player: AudioStreamPlayer
var footstep_player: AudioStreamPlayer
var current_theme: StringName = &""
var next_sfx_player := 0

var _music_tween: Tween
var _is_ducked := false
var _walking := false


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	_bind_buttons_recursive(get_tree().root)
	music_player = _create_player("MusicPlayer", _effective_volume("music_volume"))
	for index in SFX_POOL_SIZE:
		sfx_players.append(_create_player("SfxPlayer%d" % index, _effective_volume("sfx_volume")))
	voice_player = _create_player("VoicePlayer", _effective_volume("voice_volume"))
	voice_player.finished.connect(_on_voice_finished)
	footstep_player = _create_player("FootstepPlayer", _effective_volume("sfx_volume"))
	footstep_player.stream = SFX_FOOTSTEP
	footstep_player.finished.connect(_on_footstep_finished)


func _on_node_added(node: Node) -> void:
	_bind_button_click(node)


func _bind_buttons_recursive(node: Node) -> void:
	_bind_button_click(node)
	for child in node.get_children():
		_bind_buttons_recursive(child)


func _bind_button_click(node: Node) -> void:
	if not node is BaseButton or node.has_meta("audio_click_bound"):
		return
	node.set_meta("audio_click_bound", true)
	(node as BaseButton).pressed.connect(play_click)


# ---------------------------------------------------------------- MUSIK

func play_music(stream: AudioStream) -> void:
	if stream == null:
		return
	_kill_music_tween()
	music_player.stream = stream
	music_player.volume_db = _music_target_db()
	music_player.play()


func play_theme(theme: StringName) -> void:
	if not MUSIC_THEMES.has(theme) or (current_theme == theme and music_player.playing):
		return
	var next_stream: AudioStreamWAV = MUSIC_THEMES[theme]
	_prepare_wav_loop(next_stream)
	current_theme = theme
	_crossfade_to(next_stream)


func play_full_game_music() -> void:
	if music_player.stream == FULL_GAME_MUSIC and music_player.playing:
		return
	var full_stream: AudioStreamMP3 = FULL_GAME_MUSIC
	full_stream.loop = true
	current_theme = &"full_game"
	_crossfade_to(FULL_GAME_MUSIC)


func stop_music() -> void:
	_kill_music_tween()
	music_player.stop()
	current_theme = &""


func _crossfade_to(stream: AudioStream) -> void:
	_kill_music_tween()
	_music_tween = create_tween()
	if music_player.playing:
		_music_tween.tween_property(music_player, "volume_db", SILENT_DB, FADE_OUT_TIME)
		_music_tween.tween_callback(_start_music.bind(stream))
	else:
		_start_music(stream)
	_music_tween.tween_property(music_player, "volume_db", _music_target_db(), FADE_IN_TIME)


func _start_music(stream: AudioStream) -> void:
	music_player.stream = stream
	music_player.volume_db = START_FADE_DB
	music_player.play()


@warning_ignore("integer_division")
func _prepare_wav_loop(stream: AudioStreamWAV) -> void:
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	# Pastikan titik akhir loop valid supaya musik tidak berhenti / patah.
	if stream.loop_end <= 0:
		var bytes_per_sample := 2 if stream.format == AudioStreamWAV.FORMAT_16_BITS else 1
		var channels := 2 if stream.stereo else 1
		if stream.format != AudioStreamWAV.FORMAT_IMA_ADPCM:
			stream.loop_end = stream.data.size() / (bytes_per_sample * channels)


func _kill_music_tween() -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = null


func _music_target_db() -> float:
	var db := linear_to_db(maxf(_effective_volume("music_volume"), 0.0001))
	if _is_ducked:
		db += DUCK_DB
	return db


func _set_ducked(value: bool) -> void:
	if _is_ducked == value:
		return
	_is_ducked = value
	if not music_player.playing:
		return
	_kill_music_tween()
	_music_tween = create_tween()
	_music_tween.tween_property(music_player, "volume_db", _music_target_db(), DUCK_TIME)


# ------------------------------------------------------------------ SFX

func play_sfx(stream: AudioStream, pitch_variation: float = 0.0) -> void:
	if stream == null:
		return
	var player := sfx_players[next_sfx_player]
	next_sfx_player = (next_sfx_player + 1) % sfx_players.size()
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()


## Panggil setiap frame dari script karakter: set_walking(velocity.length() > 5.0)
## Langkah kaki diputar berulang HANYA selama karakter bergerak, dan langsung
## dihentikan saat karakter berhenti.
func set_walking(walking: bool) -> void:
	_walking = walking
	if walking:
		if not footstep_player.playing:
			_play_footstep_once()
	elif footstep_player.playing:
		footstep_player.stop()


func _play_footstep_once() -> void:
	footstep_player.pitch_scale = 1.0 + randf_range(-DEFAULT_PITCH_VARIATION, DEFAULT_PITCH_VARIATION)
	footstep_player.play()


func _on_footstep_finished() -> void:
	if _walking:
		_play_footstep_once()


## Hentikan semua efek suara yang sedang berjalan (misal saat pindah scene / pause).
func stop_all_sfx() -> void:
	_walking = false
	footstep_player.stop()
	for player in sfx_players:
		player.stop()


func play_click() -> void:
	play_sfx(SFX_UI_POP, DEFAULT_PITCH_VARIATION)


func play_pickup() -> void:
	play_sfx(SFX_STRAWBERRY, DEFAULT_PITCH_VARIATION)


func play_wood() -> void:
	play_sfx(SFX_WOOD_PLANK, DEFAULT_PITCH_VARIATION)


func play_clean() -> void:
	play_sfx(SFX_CLEAN_SPARKLE, DEFAULT_PITCH_VARIATION)


func play_splash() -> void:
	play_sfx(SFX_WATER_SPLASH, DEFAULT_PITCH_VARIATION)


func play_success() -> void:
	play_sfx(SFX_MISSION_COMPLETE)


# ---------------------------------------------------------------- VOICE

func play_voice(stream: AudioStream) -> void:
	if stream == null:
		return
	voice_player.stream = stream
	voice_player.play()
	_set_ducked(true)


func stop_voice() -> void:
	voice_player.stop()
	_set_ducked(false)


func _on_voice_finished() -> void:
	_set_ducked(false)


# -------------------------------------------------------------- VOLUME

func set_music_volume(volume: float) -> void:
	SaveManager.set_volume("music_volume", volume)
	_refresh_volumes()


func set_sfx_volume(volume: float) -> void:
	SaveManager.set_volume("sfx_volume", volume)
	_refresh_volumes()


func set_voice_volume(volume: float) -> void:
	SaveManager.set_volume("voice_volume", volume)
	_refresh_volumes()


func set_master_volume(volume: float) -> void:
	SaveManager.set_volume("master_volume", volume)
	_refresh_volumes()


func _create_player(player_name: String, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.volume_db = linear_to_db(maxf(clampf(volume, 0.0, 1.0), 0.0001))
	add_child(player)
	return player


func _effective_volume(setting_name: String) -> float:
	return SaveManager.get_volume(setting_name) * SaveManager.get_volume("master_volume", 1.0)


func _refresh_volumes() -> void:
	# Jangan timpa volume musik saat fade sedang berjalan.
	var fading := _music_tween != null and _music_tween.is_valid() and _music_tween.is_running()
	if is_instance_valid(music_player) and not fading:
		music_player.volume_db = _music_target_db()
	for player in sfx_players:
		player.volume_db = linear_to_db(maxf(_effective_volume("sfx_volume"), 0.0001))
	if is_instance_valid(footstep_player):
		footstep_player.volume_db = linear_to_db(maxf(_effective_volume("sfx_volume"), 0.0001))
	if is_instance_valid(voice_player):
		voice_player.volume_db = linear_to_db(maxf(_effective_volume("voice_volume"), 0.0001))
