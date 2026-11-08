extends TestCase
## "Spenden" in the main menu (GDD §19a, D-166): the button opens a dialog
## that names where the money goes, and only "Zu Ko-fi" opens the Ko-fi page.

const AREAS := ["ui"]  # ci-cd.md §2a

var _opened: Array = []


func _root() -> Window:
	return (Engine.get_main_loop() as SceneTree).root


func _find_button(n: Node, text: String) -> Button:
	if n is Button and (n as Button).text == text:
		return n
	for c in n.get_children():
		var b := _find_button(c, text)
		if b:
			return b
	return null


func _texts(n: Node, out: Array) -> Array:
	if n is Label:
		out.append((n as Label).text)
	for c in n.get_children():
		_texts(c, out)
	return out


func test_menu_button_opens_the_donate_dialog() -> void:
	var menu := MainMenu.new()
	_root().add_child(menu)
	var b := _find_button(menu, TranslationServer.translate("MENU_DONATE"))
	assert_true(b != null, "Spenden button in the main menu")
	if b:
		b.pressed.emit()
		var overlay := menu.get_child(menu.get_child_count() - 1)
		assert_true(overlay is DonateDialog, "Spenden opens the DonateDialog")
	menu.free()


func test_dialog_says_where_the_money_goes_before_the_link() -> void:
	var dlg := DonateDialog.new()
	dlg.open_url = func(u: String) -> void: _opened.append(u)
	_opened.clear()
	_root().add_child(dlg)
	var texts := _texts(dlg, [])
	for key in ["DONATE_WHERE", "DONATE_TEXT"] + DonateDialog.ORGS:
		var t := TranslationServer.translate(key)
		assert_true(t != key, "%s is translated" % key)
		assert_true(t in texts, "%s shown" % key)
	assert_true(_opened.is_empty(), "nothing opens before the button is pressed")
	var go := dlg.find_child("go", true, false) as Button
	assert_true(go != null, "Zu Ko-fi button")
	if go:
		go.pressed.emit()
	assert_eq(_opened, ["https://ko-fi.com/brandmauer"])
	if is_instance_valid(dlg) and not dlg.is_queued_for_deletion():
		dlg.free()
