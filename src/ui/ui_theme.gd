class_name UITheme
## Shared look: "Doodle/Paint" on paper (GDD §20). Handwritten font for UI and
## invented lines, typewriter font for real quotes and documents.

const PAPER := Color("f4efe1")
const PAPER_DARK := Color("e6dcc3")
const INK := Color("222222")
const INK_SOFT := Color("555046")
const RED := Color("c0392b")
const GREEN := Color("3f8f4f")
const YELLOW := Color("e8b923")
const BLUE := Color("2e6db4")
const GREY := Color("8a857a")

const HAND_FONT_PATH := "res://assets/fonts/PatrickHand-Regular.ttf"
const TYPE_FONT_PATH := "res://assets/fonts/CourierPrime-Regular.ttf"
const TYPE_BOLD_PATH := "res://assets/fonts/CourierPrime-Bold.ttf"

static var _theme: Theme
static var _fonts := {}


static func font(path: String) -> Font:
	if not _fonts.has(path):
		var f: Font = load(path) if ResourceLoader.exists(path) else null
		if f == null:
			var ff := FontFile.new()
			if ff.load_dynamic_font(ProjectSettings.globalize_path(path)) == OK:
				f = ff
			else:
				f = ThemeDB.fallback_font
		_fonts[path] = f
	return _fonts[path]


static func hand() -> Font:
	return font(HAND_FONT_PATH)


static func typewriter(bold := false) -> Font:
	return font(TYPE_BOLD_PATH if bold else TYPE_FONT_PATH)


static func get_theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = hand()
	t.default_font_size = 22
	for type in ["Label", "Button", "LineEdit", "CheckBox", "OptionButton", "RichTextLabel", "ItemList"]:
		t.set_color("font_color", type, INK)
	t.set_color("default_color", "RichTextLabel", INK)
	t.set_color("font_hover_color", "Button", RED)
	t.set_color("font_pressed_color", "Button", RED)
	t.set_color("font_disabled_color", "Button", GREY)
	t.set_color("font_focus_color", "Button", RED)
	t.set_stylebox("normal", "Button", box(PAPER, INK, 2))
	t.set_stylebox("hover", "Button", box(Color("fff8e6"), RED, 3))
	t.set_stylebox("pressed", "Button", box(PAPER_DARK, RED, 3))
	t.set_stylebox("focus", "Button", focus_box())
	t.set_stylebox("focus", "LinkButton", focus_box(4))
	t.set_color("font_focus_color", "LinkButton", RED)
	t.set_stylebox("disabled", "Button", box(PAPER_DARK, GREY, 2))
	t.set_stylebox("panel", "Panel", box(PAPER, INK, 3))
	t.set_stylebox("panel", "PanelContainer", box(PAPER, INK, 3))
	t.set_stylebox("normal", "LineEdit", box(Color.WHITE, INK, 2))
	t.set_stylebox("focus", "LineEdit", box(Color.WHITE, RED, 2))
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("caret_color", "LineEdit", INK)
	t.set_stylebox("panel", "TooltipPanel", box(Color("fffbe9"), INK, 2))
	t.set_color("font_color", "TooltipLabel", INK)
	_theme = t
	return t


## Gamepad/keyboard focus frame (GDD §19b): a thick red marker line drawn a
## few pixels outside the control, uneven like the other doodle boxes. Also
## drawn by FocusTips around controls without a focus style of their own.
static func focus_box(radius := 8) -> StyleBoxFlat:
	var s := box(Color(0, 0, 0, 0), RED, 3, radius)
	s.draw_center = false
	s.expand_margin_left = 5
	s.expand_margin_top = 4
	s.expand_margin_right = 6
	s.expand_margin_bottom = 5
	s.anti_aliasing = true
	return s


## Hand-drawn looking box: slightly uneven border via different widths.
static func box(bg: Color, border: Color, width := 2, radius := 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = width
	s.border_width_top = width + 1
	s.border_width_right = width + 1
	s.border_width_bottom = width + 2
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius + 3
	s.corner_radius_bottom_right = radius
	s.corner_radius_bottom_left = radius + 2
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 6
	s.content_margin_bottom = 8
	return s
