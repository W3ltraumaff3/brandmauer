class_name DonateDialog
extends UIDialog
## "Spenden" (GDD §19a, D-166): says where the money goes, then opens the
## Ko-fi page in the browser. The game never handles payments itself.

const URL := "https://ko-fi.com/brandmauer"
const ORGS := ["DONATE_ORG_1", "DONATE_ORG_2", "DONATE_ORG_3", "DONATE_ORG_4"]

## Opens the URL; tests swap it for a recorder so no browser starts.
var open_url: Callable = OS.shell_open


func build() -> void:
	width = 600.0
	card.custom_minimum_size.x = width
	auto_focus = false
	content.add_child(UIKit.heading(tr("DONATE_TITLE"), 36))
	content.add_child(UIKit.para(tr("DONATE_WHERE"), 22))
	content.add_child(UIKit.para(tr("DONATE_TEXT"), 20, UITheme.INK_SOFT))
	var list := UIKit.vbox(2)
	for key in ORGS:
		list.add_child(UIKit.para(tr(key), 20))
	content.add_child(UIKit.margin(list, 16, 0, 0, 0))
	var row := UIKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_END
	var cancel := UIKit.button(tr("UI_CANCEL"), close)
	cancel.name = "cancel"
	var go := UIKit.button(tr("DONATE_GO"), _on_go)
	go.name = "go"
	row.add_child(cancel)
	row.add_child(go)
	content.add_child(row)
	UIKit.focus_later(go)


func _on_go() -> void:
	open_url.call(URL)
	ToastLayer.show_text(tr("DONATE_OPENED"))
	close()
