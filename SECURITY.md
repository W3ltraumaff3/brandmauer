# Security Policy / Sicherheitsrichtlinie

[Deutsch](#deutsch) · [English](#english)

## Deutsch

### Sicherheitslücke melden

Bitte melde Sicherheitslücken **nicht** über öffentliche Issues, Pull Requests oder Diskussionen.

Nutze stattdessen die private Meldung von GitHub:
**[Sicherheitslücke privat melden](https://github.com/W3ltraumaff3/brandmauer/security/advisories/new)**
(Reiter *Security* → *Report a vulnerability*).

Hilfreich sind:

- betroffene Version (Release-Tag oder Commit) und Plattform (Windows, Linux, macOS, Dedicated Server)
- Beschreibung und Auswirkung, z. B. Codeausführung, Absturz eines Hosts durch manipulierte Netzwerkpakete, Lesen oder Schreiben von Dateien außerhalb des Spielstand-Ordners
- Schritte zum Nachstellen oder ein Proof of Concept

### Was passiert danach

Brandmauer ist ein Hobbyprojekt. Wir bestätigen Meldungen in der Regel innerhalb von 7 Tagen, prüfen sie und melden uns mit einer Einschätzung. Behobene Lücken veröffentlichen wir als GitHub Security Advisory; auf Wunsch nennen wir dich dort.

### Geltungsbereich

- **Unterstützt:** der aktuelle Stand von `main` und das neueste Release.
- **Im Geltungsbereich:** der Spielcode (inklusive Netzwerkcode für Co-op und Dedicated Server), die Build- und Release-Workflows sowie die Skripte im Repository.
- **Nicht im Geltungsbereich:** Inhalte wie Zitate und Satire (bitte als normales Issue melden), Cheats im eigenen Einzelspiel und Schwachstellen in Godot selbst (bitte direkt an das [Godot-Projekt](https://github.com/godotengine/godot/security) melden).

## English

### Reporting a vulnerability

Please do **not** report security vulnerabilities through public issues, pull requests or discussions.

Use GitHub's private reporting instead:
**[Report a vulnerability privately](https://github.com/W3ltraumaff3/brandmauer/security/advisories/new)**
(*Security* tab → *Report a vulnerability*).

Please include:

- the affected version (release tag or commit) and platform (Windows, Linux, macOS, dedicated server)
- a description and the impact, e.g. code execution, crashing a host with crafted network packets, reading or writing files outside the save folder
- steps to reproduce or a proof of concept

### What happens next

Brandmauer is a hobby project. We usually acknowledge reports within 7 days, investigate them and get back to you with an assessment. Fixed vulnerabilities are published as a GitHub Security Advisory, and we're happy to credit you there.

### Scope

- **Supported:** the current state of `main` and the latest release.
- **In scope:** the game code (including the networking code for co-op and the dedicated server), the build and release workflows, and the scripts in this repository.
- **Out of scope:** content such as quotes and satire (please open a regular issue), cheating in your own single-player game, and vulnerabilities in Godot itself (please report those to the [Godot project](https://github.com/godotengine/godot/security)).
