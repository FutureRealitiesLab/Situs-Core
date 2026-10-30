# Changelog

Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/). Versionen von `addons/situs_core/plugin.cfg`. Die Tags `v1.0.0` und `v1.1.0` sind noch nicht gesetzt.

## [Unreleased]

### Hinzugefügt
- Avatar `avatar_dynamic_cone`: Kopf als Würfel mit Nase (Blickrichtung) statt Kugel, Controller als Quader (`update_hands()`). `NetworkManager.send_player_state()` überträgt optional zwei Controller-Posen und eine Tracking-Maske. **Die RPC-Signatur hat sich geändert: alle Geräte müssen denselben Stand haben.**
- `docs/INSTALL.md` (Einrichtung auf neuem Rechner, Skript-Inhalt, Referenz für Focus 3/Vision) und `tools/setup_android.ps1`.
- `docs/plan.md` (Stand und TODO-Liste), `docs/HI3_MIGRATION_PLAN.md` und `.html` (Plan für die spätere Umstellung von Hyper-Irrealismus III, dort wird bis dahin nichts geändert).
- `docs/ai-chat-log.md` (Entwicklungsprotokoll) und dieser Changelog.
- Hinweis in der README: Der Standard `127.0.0.1` für die Server-IP funktioniert auf der Brille nicht.

### Geändert
- `.gitignore`: `build/` (APK-Ausgabe) wird ignoriert.
- README gekürzt und auf `docs/INSTALL.md` verwiesen. Die Herkunft aus Hyper-Irrealismus III steht als Fußnote.

### Entfernt
- Veraltete HI-III-Dokumente aus `docs/`: `ARCHITECTURE.md`, `design_teams.md`, `dev_team.md`, `venue_team.md` (Godot 4.6, Szenen-Teams, Meta Quest). Sie liegen in der Git-Historie.

### Meilenstein 2026-10-30
- Im Einsatz bestätigt (MatLab_CommTest): Brillen verbinden sich im Netzwerk mit dem Server, Avatare sind sichtbar, MATLAB-Daten werden verteilt.

## [1.1.0]

### Hinzugefügt
- Project Settings unter *Situs Core*: `network/server_ip`, `room/width_m`, `room/length_m`, `room/rotation_deg` (Zugriff über `SitusSettings`). Die Werte stehen in `project.godot` und gelten im Editor wie in der APK.
- Raumdrehung wird auf den XR-Ursprung angewendet, nicht auf die Szenen. Die Spielfläche wird aus Breite und Länge erzeugt.
- `scene_provider`, `request_scene()` und das Signal `scene_step_requested` im `SceneManager`.

### Geändert
- `NetworkManager.server_ip` liest die Einstellung statt eines festen Werts.
- `plugin.gd` trägt die Einstellungen ein und registriert die Autoloads der Module.

### Behoben
- Parse-Fehler im Plugin (Variant-Inferenz bei `var key := ...`).

## [1.0.0]

### Hinzugefügt
- Eigenes Repo, aus Hyper-Irrealismus III extrahiert (gefilterte Historie, kein Fork). Branch `dist` enthält nur `addons/situs_core/` für git subtree.
- Optionales Modul `modul_scene_loop` (Registry, Timer, Auto-Wechsel). Ohne Module läuft eine Szene (`situs_core/default_scene`).
- `.gd.uid`-Dateien werden committet, damit UIDs im geteilten Plugin stabil sind.
- `export_presets.cfg.template` (Preset „Android – HTC Focus 3“).

### Geändert
- Godot 4.7, nur GL Compatibility.
- `SYSTEM/` heißt jetzt `addons/situs_core/`.
- `openxr/startup_alert=false`, damit am PC ohne Headset kein Dialog erscheint.

### Entfernt
- Meta Quest (Preset, Plugin-Optionen, Action-Map-Profil).
