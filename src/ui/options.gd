class_name OptionsScreen
extends UIScreen
## Options: music/SFX volume, fullscreen, player name. Usable from the main
## menu and the pause menu.

var _music: HSlider
var _sfx: HSlider
var _sfx_timer := 0.0


func _init() -> void:
	super()
	process_mode = PROCESS_MODE_ALWAYS


func build() -> void:
	body.add_child(UIKit.title_bar(tr("OPTIONS_TITLE"), close))
	var center := CenterContainer.new()
	center.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_child(center)
	var card := UIKit.card(UITheme.PAPER, UITheme.INK, -0.8, 3)
	center.add_child(card)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 18)
	card.add_child(UIKit.margin(grid, 16, 14, 16, 14))

	grid.add_child(UIKit.label(tr("OPTIONS_MUSIC"), 24))
	_music = _slider(float(UIApi.option("music", 0.7)))
	_music.value_changed.connect(_on_music)
	grid.add_child(_music)

	grid.add_child(UIKit.label(tr("OPTIONS_SFX"), 24))
	_sfx = _slider(float(UIApi.option("sfx", 0.8)))
	_sfx.value_changed.connect(_on_sfx)
	grid.add_child(_sfx)

	grid.add_child(UIKit.label(tr("OPTIONS_FULLSCREEN"), 24))
	var fs := CheckBox.new()
	fs.text = tr("OPTIONS_FULLSCREEN_ON")
	fs.button_pressed = bool(UIApi.option("fullscreen", false))
	fs.toggled.connect(_on_fullscreen)
	grid.add_child(fs)

	grid.add_child(UIKit.label(tr("OPTIONS_TARGET"), 24))
	var tm := OptionButton.new()
	for key in ["OPTIONS_TARGET_CLOSEST", "OPTIONS_TARGET_MOST_HP", "OPTIONS_TARGET_LEAST_HP"]:
		tm.add_item(tr(key))
	tm.selected = clampi(int(UIApi.option("target_mode", 0)), 0, 2)
	tm.tooltip_text = tr("OPTIONS_TARGET_TIP")
	tm.item_selected.connect(_on_target_mode)
	grid.add_child(tm)

	grid.add_child(UIKit.label(tr("MENU_NAME"), 24))
	var name_edit := LineEdit.new()
	name_edit.text = str(UIApi.option("name", tr("MENU_DEFAULT_NAME")))
	name_edit.max_length = 20
	name_edit.custom_minimum_size.x = 380
	name_edit.text_changed.connect(_on_name)
	grid.add_child(name_edit)

	var hint := UIKit.para(tr("OPTIONS_HINT"), 18, UITheme.INK_SOFT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(hint)


func _slider(v: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = v
	s.custom_minimum_size = Vector2(380, 32)
	s.size_flags_vertical = SIZE_SHRINK_CENTER
	var track := UITheme.box(UITheme.PAPER_DARK, UITheme.INK, 1, 4)
	track.content_margin_top = 6
	track.content_margin_bottom = 6
	s.add_theme_stylebox_override("slider", track)
	var fill := UITheme.box(UITheme.RED, UITheme.INK, 1, 4)
	fill.content_margin_top = 6
	fill.content_margin_bottom = 6
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	return s


func _apply_volumes() -> void:
	UIApi.call_opt(UIApi.audio(), "set_volumes", [_music.value, _sfx.value])


func _on_music(v: float) -> void:
	UIApi.set_option("music", v)
	_apply_volumes()


func _on_sfx(v: float) -> void:
	UIApi.set_option("sfx", v)
	_apply_volumes()
	var now := Time.get_ticks_msec() / 1000.0
	if now - _sfx_timer > 0.25:
		_sfx_timer = now
		UIApi.sfx("pickup")


func _on_fullscreen(on: bool) -> void:
	UIApi.set_option("fullscreen", on)
	apply_fullscreen(on)


static func apply_fullscreen(on: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)


func _on_target_mode(i: int) -> void:
	UIApi.set_option("target_mode", i)
	UIApi.call_opt(UIApi.game(), "send_target_mode")


func _on_name(t: String) -> void:
	if t.strip_edges() != "":
		UIApi.set_option("name", t.strip_edges())
