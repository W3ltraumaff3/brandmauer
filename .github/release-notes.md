## Brandmauer – Beta für Tester:innen

Danke, dass du mittestest! Das Spiel ist eine **Beta**: Es gibt Bugs, und das Balancing ist noch nicht fertig.

### Neu in 0.4.1
- **Die Remigrantin ist jetzt die Abschlussprüfung:** mehr Lebenspunkte und drei neue Angriffe. Die **Ansturm-Kette** reißt Windräder um. Bei **Reichweite** bist du nur vor intakter Brandmauer sicher (Löcher reparieren lohnt sich!). In Phase 3 laden **Briefkastenfirmen** ihren Schild auf, bis alle zerstört sind. Ab 150 s Kampfdauer legt die **Hochrechnung** zu.
- **Rote Items gewinnen jetzt Runs:** acht überarbeitet, u. a. Genossenschaftsanteil (Dividende statt Zinsdeckel, kein Kauflimit mehr), Kritische Masse, Entlassungsurkunde, Wurfmaschine, Doppelwumms, Tarnkappe und Robin-Hood-Kostüm. Cum-Ex-Erstattung, Doppelwumms, Brandmauer-Fertigputz und Entlassungsurkunde tauchen jetzt auch wirklich im Späti auf.
- **Waffenstufen in Farbe:** Stufe I grün, II blau, III lila, IV rot – wie die Items.
- **Controller:** Im Späti springt der Fokus nach einem Kauf zum nächsten Angebot statt zu „Statistik“. Links/rechts bei den Level-ups bleibt in der Reihe (kein versehentliches Neu würfeln mehr). In der Lobby wechseln LB/RB zwischen Einstellungen, Charakteren und Bereit.
- **Wichtig für Koop:** Alle brauchen diese Version, ältere können nicht mitspielen.

### Neu in 0.4.0
- **Acht neue Status- und Beschwörungswaffen:** Kleine Anfrage, Faktencheck, Soli-Sticker, Lobbyregister, Menschenkette, Pappkamerad, Demo-Sanis und Lauti – dazu drei neue Statuseffekte: In Bearbeitung, Aktenkundig und Rolle rückwärts.
- **Beschwörungen treffen mehrere:** Flugblätter vom Infostand springen zum nächsten Ziel weiter, Weiße Overalls reißen beim Aufprall die Umstehenden mit. Infostände sind kleiner, schneller aufgebaut, und höhere Stufen halten mehr Stände (2/2/3/4 pro Waffe).
- **Bodenwaffen landen besser:** Kleber, Kartoffelbrei und Ziegel landen in der dichtesten Gruppe; wer mit Straßenkreide stehen bleibt, malt einen wachsenden Kreidekreis.
- **Bosse sind härter und eigener:** mehr Lebenspunkte, Pressekonferenz beim Phasenwechsel, zufällige Ziele, „Standfest“ gegen Dauerbetäubung, Angriffe lassen sich mit Betäubung unterbrechen, neue Fähigkeiten wie Abstimmung (Plenum-Kreise besetzen!) und Kahlschlag.
- **Option „Eigene Effekte“:** macht deine Waffen, Beschwörungen und Effekte durchsichtig, damit du gegnerische Geschosse besser siehst.
- **Balancing:** Ehrenamtskarte wirkt auf alle Ehrenamt-Waffen, Krankenschein heilt etwas weniger, Nahkampf trifft Bosse härter. Mehrere Bugs behoben (u. a. Betäubung bei Reichsbürger:innen, Gift-Zuordnung, gestapelte Ziegel).
- **Wichtig für Koop:** Alle brauchen diese Version, ältere können nicht mitspielen.

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
