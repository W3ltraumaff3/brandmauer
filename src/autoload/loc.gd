extends Node
## Loads every i18n/*.csv (format: "keys,de") into Godot's TranslationServer.
## Done at runtime so no editor import step is needed for translations.

const DIR := "res://i18n"


func _ready() -> void:
	load_all()
	TranslationServer.set_locale("de")


func load_all() -> void:
	var translations := {}
	for file in DirAccess.get_files_at(DIR):
		if not file.ends_with(".csv"):
			continue
		var f := FileAccess.open(DIR.path_join(file), FileAccess.READ)
		if f == null:
			continue
		var header := f.get_csv_line()
		while not f.eof_reached():
			var row := f.get_csv_line()
			if row.size() < 2 or row[0].is_empty() or row[0].begins_with("#"):
				continue
			for col in range(1, mini(row.size(), header.size())):
				var locale := header[col]
				if not translations.has(locale):
					var t := Translation.new()
					t.locale = locale
					translations[locale] = t
				translations[locale].add_message(row[0], row[col].replace("\\n", "\n"))
	for t in translations.values():
		TranslationServer.add_translation(t)
