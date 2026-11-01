class_name OptionsScreen
extends UIScreen
## Options: music/SFX volume, window mode, speech bubble opacity, target mode,
## player name. Usable from the main menu, the pause menu and the Späti.

## Save option `window_mode` (architecture §11), in OptionButton order.
const WINDOW_MODES := ["fullscreen", "maximized", "windowed"]
const WINDOW_MODE_KEYS := ["OPTIONS_WINDOW_FULLSCREEN", "OPTIONS_WINDOW_MAXIMIZED", "OPTIONS_WINDOW_WINDOWED"]
const BUBBLE_DEFAULT := 0.7

var _music: HSlider
var _sfx: HSlider
var _bubbles: HSlider
var _bubbles_label: Label
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
	grid.add_theme_constant_override("v_separation", 14)
	card.add_child(UIKit.margin(grid, 16, 12, 16, 12))

	grid.add_child(UIKit.label(tr("OPTIONS_MASTER"), 24))
	var master := _slider(float(UIApi.option("master", 0.7)))
	master.name = "master"
	master.value_changed.connect(_on_master)
	focus_target = master
	grid.add_child(master)

	grid.add_child(UIKit.label(tr("OPTIONS_MUSIC"), 24))
	_music = _slider(float(UIApi.option("music", 0.5)))
	_music.name = "music"
	_music.value_changed.connect(_on_music)
	grid.add_child(_music)

	grid.add_child(UIKit.label(tr("OPTIONS_SFX"), 24))
	_sfx = _slider(float(UIApi.option("sfx", 0.8)))
	_sfx.name = "sfx"
	_sfx.value_changed.connect(_on_sfx)
	grid.add_child(_sfx)

	grid.add_child(UIKit.label(tr("OPTIONS_WINDOW_MODE"), 24))
	var wm := OptionButton.new()
	wm.name = "window_mode"
	for key in WINDOW_MODE_KEYS:
		wm.add_item(tr(key))
	wm.selected = maxi(0, WINDOW_MODES.find(saved_window_mode()))
	wm.item_selected.connect(_on_window_mode)
	UINav.step_option(wm)
	grid.add_child(wm)

	var bl := UIKit.label(tr("OPTIONS_BUBBLES"), 24)
	bl.mouse_filter = MOUSE_FILTER_PASS
	bl.tooltip_text = tr("OPTIONS_BUBBLES_TIP")
	grid.add_child(bl)
	var brow := UIKit.hbox(12)
	_bubbles = _slider(UIKit.option_float("bubble_opacity", BUBBLE_DEFAULT))
	_bubbles.name = "bubble_opacity"
	_bubbles.custom_minimum_size.x = 300
	_bubbles.tooltip_text = tr("OPTIONS_BUBBLES_TIP")
	_bubbles.value_changed.connect(_on_bubbles)
	brow.add_child(_bubbles)
	_bubbles_label = UIKit.label("", 22, UITheme.INK_SOFT)
	_bubbles_label.custom_minimum_size.x = 68
	_bubbles_label.size_flags_vertical = SIZE_SHRINK_CENTER
	brow.add_child(_bubbles_label)
	_update_bubbles_label(_bubbles.value)
	grid.add_child(brow)

	grid.add_child(UIKit.label(tr("OPTIONS_TARGET"), 24))
	var tm := OptionButton.new()
	tm.name = "target_mode"
	for key in ["OPTIONS_TARGET_CLOSEST", "OPTIONS_TARGET_MOST_HP", "OPTIONS_TARGET_LEAST_HP"]:
		tm.add_item(tr(key))
	tm.selected = clampi(int(UIApi.option("target_mode", 0)), 0, 2)
	tm.tooltip_text = tr("OPTIONS_TARGET_TIP")
	tm.item_selected.connect(_on_target_mode)
	UINav.step_option(tm)
	grid.add_child(tm)

	grid.add_child(UIKit.label(tr("MENU_NAME"), 24))
	var name_edit := LineEdit.new()
	name_edit.name = "player_name"
	name_edit.text = str(UIApi.option("name", tr("MENU_DEFAULT_NAME")))
	name_edit.max_length = 20
	name_edit.custom_minimum_size.x = 380
	name_edit.text_changed.connect(_on_name)
	grid.add_child(name_edit)

	var hint := UIKit.para(tr("OPTIONS_HINT"), 18, UITheme.INK_SOFT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(hint)
	var keys := UIKit.para("", 16, UITheme.GREY)
	keys.name = "input_hint"
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	InputGlyphs.bind(keys, "text", func() -> String:
		return InputGlyphs.fmt("OPTIONS_KEYS_HINT", ["ui_cancel"]))
	body.add_child(keys)


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


func _on_master(v: float) -> void:
	UIApi.set_option("master", v)
	UIApi.call_opt(UIApi.audio(), "set_master_volume", [v])


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


## Fx reads the option every frame, so this applies live during a wave.
func _on_bubbles(v: float) -> void:
	UIApi.set_option("bubble_opacity", v)
	_update_bubbles_label(v)


func _update_bubbles_label(v: float) -> void:
	if _bubbles_label:
		_bubbles_label.text = tr("OPTIONS_BUBBLES_OFF") if v <= 0.001 else "%d %%" % int(round(v * 100.0))


func _on_window_mode(i: int) -> void:
	var m: String = WINDOW_MODES[clampi(i, 0, WINDOW_MODES.size() - 1)]
	UIApi.set_option("window_mode", m)
	apply_window_mode(m)


## The saved window mode; falls back to the old `fullscreen` bool.
static func saved_window_mode() -> String:
	var m = UIApi.option("window_mode", null)
	if m is String and WINDOW_MODES.has(m):
		return m
	return "fullscreen" if bool(UIApi.option("fullscreen", false)) else "windowed"


static func apply_window_mode(m: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	match m:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"maximized":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


## Old entry point (bool); kept for callers that still pass fullscreen on/off.
static func apply_fullscreen(on: bool) -> void:
	apply_window_mode("fullscreen" if on else "windowed")


func _on_target_mode(i: int) -> void:
	UIApi.set_option("target_mode", i)
	UIApi.call_opt(UIApi.game(), "send_target_mode")


func _on_name(t: String) -> void:
	if t.strip_edges() != "":
		UIApi.set_option("name", t.strip_edges())
