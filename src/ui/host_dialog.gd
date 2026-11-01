class_name HostDialog
extends UIDialog
## "Koop hosten": asks whether to open the router port via UPnP.

signal confirmed(use_upnp: bool)

var _upnp: CheckBox


func build() -> void:
	auto_focus = false
	content.add_child(UIKit.heading(tr("HOST_TITLE"), 36))
	content.add_child(UIKit.para(tr("HOST_INFO") % UIApi.port(), 20, UITheme.INK_SOFT))
	_upnp = CheckBox.new()
	_upnp.text = tr("HOST_UPNP")
	_upnp.button_pressed = bool(UIApi.option("upnp", true))
	_upnp.add_theme_font_size_override("font_size", 22)
	content.add_child(_upnp)
	content.add_child(UIKit.para(tr("HOST_UPNP_HINT"), 17, UITheme.INK_SOFT))
	var row := UIKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_END
	var go := UIKit.button(tr("HOST_START"), _on_go)
	row.add_child(UIKit.button(tr("UI_CANCEL"), close))
	row.add_child(go)
	content.add_child(row)
	UIKit.focus_later(go)


func _on_go() -> void:
	UIApi.set_option("upnp", _upnp.button_pressed)
	confirmed.emit(_upnp.button_pressed)
	close()
