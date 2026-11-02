## Brandmauer – Beta für Tester:innen

Danke, dass du mittestest! Das Spiel ist eine **Beta**: Es gibt Bugs, und das Balancing ist noch nicht fertig.

### Neu in 0.3.0
- **Die Brandmauer steht jetzt auf allen vier Seiten.** Gegner:innen kommen von überall, die Arena ist größer – genug Platz für vier.
- **Zurück ins Spiel:** Spiel abgestürzt oder Verbindung weg? Im Hauptmenü bringt dich „Zurück ins Spiel“ in die laufende Koop-Runde zurück. Dein Charakter wartet, bis die Runde vorbei ist.
- **Neues Balancing:** späte Wellen und Bosse sind deutlich härter, Koop ist nicht mehr leichter als solo. Bosse haben eine zweite Phase.
- **Kürzer im Späti:** weniger, dafür stärkere Level-ups (1 → 2 → 3 pro Besuch, mit Seltenheit wie bei Items), höhere Preise, Level-ups kann man neu würfeln. Es gibt immer eine passende Waffe für deinen Build.
- **Reichensteuer (Koop):** Wer in einer Welle viel mehr Pfand sammelt als die anderen, gibt etwas an die Ärmsten ab.
- **Alle Umfrage-Stufen** sind sofort wählbar. Neu: **Boss-Wiederholung** als Option in der Lobby.
- **Drei neue Waffen:** Demo-Fahnenstange, Bierkiste vom Späti, Straßenkreide.
- **Umverteilung (Lebensraub)** funktioniert jetzt wie in Brotato: 1 Punkt = 1 % Chance pro Treffer auf 1 Leben.
- Critical Mass macht unverwundbar, nach jeder Welle gibt’s kurz „Feierabend!“, „Bereit“ ist jetzt deutlich zu sehen, und vieles mehr.
- **Wichtig für Koop:** Alle brauchen diese Version, ältere können nicht mitspielen.

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
