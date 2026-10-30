# Changelog

Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/). Versionen von `addons/situs_core/plugin.cfg`. Die Tags `v1.0.0` und `v1.1.0` sind noch nicht gesetzt.

## [Unreleased]

### Hinzugefügt
- Kontrolle: Beim Drücken einer Controller-Taste blitzt der eigene Controller-Quader kurz weiß auf.
- Boost-Sprung: B-Taste (rechts) oder Hocke und Hochspringen hebt die eigene Sicht auf einstellbare Höhe (Project Settings *Situs Core → Jump*: Höhe 5 m, Aufstieg 0,4 s, Gleiten 5 s) und gleitet langsam zurück, in der Luft gesperrt. Der Körper des Avatars bleibt am Boden, die Ringsäule streckt sich bis zum Kopf, Ringe kommen mit der Höhe dazu (`max_ring_spacing`, `max_rings`). Kein Netzwerk-Ereignis nötig. Fallbacks der Erkennung: `docs/JUMP_FALLBACKS.md`.

### Entfernt
- Gedämpfter Schleppen-Modus (`TrailMode.DAMPED`, `damping_bottom`, `damping_curve`): Die lineare Schleppe passt.
- Erster Sprung-Ansatz mit Ghost und RPC (siehe Git-Historie).

### Hinzugefügt
- Sprung: Rückmeldung für den Springenden selbst (Vibration beider Controller). Mit `jump_debug` zeigt ein Hinweis im Blickfeld Anstieg, Sprung und den Namen jeder gedrückten Taste.
- Controller in Spielerfarbe (Avatar und eigene Controller). Controller werden nur gezeigt, wenn sie aktiv getrackt sind (ausgeschaltete lagen in der Raummitte).
- Sprung: zusätzlicher Auslöser per Controller-Taste (Project Setting `situs_core/avatar/jump_button`, Standard `by_button`), Körpererkennung neu (Anstieg und Abstieg des Kopfes, ohne Hocke und ohne Wartezeit). Schleppe dreimal länger (`lazy_follow_rate` 1.0).
- Lokale Controller im XR-Spieler sind jetzt Quader (wie im Avatar) statt Kugeln. Sprung-Erkennung überarbeitet (funktioniert mit Tracking-Raum am Boden oder am Kopf, Log mit `jump_debug`).
- Avatar `avatar_dynamic_cone` nach dem Vorbild von Spatial Encounters (Lizenz in `docs/THIRD_PARTY.md`): lineare Schleppe mit trägem Bodenpunkt (`trail_mode`, der gedämpfte Modus bleibt zum Vergleich), flache unbeleuchtete Bänder (`flat_rings`), Farbverlauf (`color_gradient`).
- Sprung-Effekt: Erkennung (Hocke, dann Hochspringen) in `xr_player.gd`, RPC `send_jump()`, Avatar fliegt und wächst, ein durchsichtiger Geist bleibt an der echten Position. Project Setting `situs_core/avatar/jump_enabled`.
- Avatar `avatar_dynamic_cone`: Kopfkugel mit Brillen-Würfel davor (Blickrichtung), Controller als Quader (`update_hands()`). `NetworkManager.send_player_state()` überträgt optional zwei Controller-Posen und eine Tracking-Maske. **Die RPC-Signatur hat sich geändert: alle Geräte müssen denselben Stand haben.**
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
