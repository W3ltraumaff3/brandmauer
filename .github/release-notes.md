## Brandmauer – Beta für Tester:innen

Danke, dass du mittestest! Das Spiel ist eine **Beta**: Es gibt Bugs, und das Balancing ist noch nicht fertig.

### Starten
- **Windows:** `Brandmauer-…-windows.exe` herunterladen und doppelklicken. Fertig, keine Installation nötig.
  Windows warnt eventuell („Der Computer wurde durch Windows geschützt“), weil die Datei nicht signiert ist. Dann auf **Weitere Informationen → Trotzdem ausführen** klicken.
- **Linux:** zip entpacken und `Brandmauer.x86_64` starten.
- **macOS:** zip entpacken, Rechtsklick auf die App → **Öffnen** (nicht signiert).

### Zusammen spielen (Koop, 1–4 Leute)
- Eine Person klickt **Koop hosten**. Die anderen klicken **Koop beitreten** und geben die IP des Hosts ein (im selben WLAN taucht das Spiel in der Liste auf).
- Über das Internet muss der Host **UDP-Port 24713** freigeben. Meist passiert das automatisch über UPnP; sonst im Router einstellen.

### Bugs melden
Im Hauptmenü gibt es den Knopf **„Bug melden“**. Er öffnet ein Formular auf GitHub. Die Logdatei liegt unter Windows in `%APPDATA%\Godot\app_userdata\Brandmauer\logs\godot.log`.
