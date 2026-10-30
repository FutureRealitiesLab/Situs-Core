# Entwicklungsprotokoll (KI-Chats)

Zusammenfassungen der Arbeitssitzungen mit Claude: was besprochen, entschieden und erreicht wurde. Keine Mitschrift. Neueste Einträge unten. Technische Änderungen stehen zusätzlich im [Changelog](../CHANGELOG.md).

## 2026-10-28: Extraktion aus Hyper-Irrealismus III

**Ziel:** Aus dem manuell duplizierten Projekt Hyper-Irrealismus III (HI-III) ein eigenes, versioniertes, öffentliches Template machen.

**Entschieden**
- Neues Repo statt Fork, Historie gefiltert (`filter-branch`, weil `git-filter-repo` fehlte).
- Layout „B“: Plugin `addons/situs_core/`, Auslieferung über den Branch `dist` per git subtree.
- Nur GL Compatibility, Godot 4.7, HTC Focus 3/Vision. Meta Quest entfällt, Pico 4 Ultimate kommt später.
- Szenenfolge (Registry, Timer) ist für das Multiplayer-Template nicht nötig und wird als optionales Modul `modul_scene_loop` ausgelagert. Weitere Module sind geplant.
- HI-III bleibt unverändert, die Umstellung ist nur als Plan beschrieben (`HI3_MIGRATION_PLAN`).

**Erreicht:** Repo angelegt, `SYSTEM/` zu `addons/situs_core/` umstrukturiert, Modul abgespalten und headless geprüft, `dist` gebaut. UID-Dateien nachgezogen, nachdem Godot beim Einbinden `invalid UID` meldete.

**Probleme:** Parse-Fehler im Plugin beim ersten Einbinden (Typ-Inferenz auf Variant). OpenXR-Dialog am PC ohne Headset wurde durch `startup_alert=false` abgestellt; Tests laufen mit `--xr-mode off`.

## 2026-10-29: Einstellungen und Integration in MatLab_CommTest

**Ziel:** Situs in das Projekt MatLab_CommTest (MATLAB → UDP → Godot) integrieren, mit einfacher Konfiguration.

**Entschieden**
- Konfiguration über Project Settings („Option A“): Server-IP, Raumbreite und -länge, Rotation in Grad. Die Werte stecken in `project.godot`, gelten im Editor wie in der APK, und eine Änderung braucht einen neuen Export.
- Rotation wird auf den XR-Ursprung angewendet, nicht auf Szenen. Dadurch folgen alle Szenen automatisch.
- Datenkanal für Simulationsdaten entsteht im CommTest-Projekt als gekapseltes Modul (`modul_data_channel`) und kann später nach Situs wandern.

**Erreicht:** Situs 1.1.0 mit Settings, Integration per subtree, Datenkanal und Relay, Serveransicht mit Maussteuerung (Headless-Test mit synthetischen MATLAB-Paketen).

## 2026-10-29/30: Export, Setup und Dokumentation

**Ziel:** Ein neuer Rechner soll ohne Vorwissen zum Export für die Vive Focus kommen.

**Erreicht:** `tools/setup_android.ps1` und `docs/INSTALL.md` (Schritte für neuen Rechner, Inhalt des Skripts, was manuell bleibt, Referenz der Einstellungen). Seit Godot 4.7 werden Export-Vorlagen einzeln gewählt; für die Brille zählt `android_source.zip`. Die Meldung `Unable to open Android 'build-tools' directory` ging nach dem Skript weg. READMEs aufgeräumt.

## 2026-10-30: Meilenstein im Netzwerk

**Ereignis:** Die Brille meldete „keine Verbindung“ und versuchte `127.0.0.1:7777`. Ursache: Die Server-IP stand noch auf dem Standard. Nach dem Eintragen der LAN-IP und neuem Export verbindet sich die Brille, MATLAB-Daten kommen im Netzwerk an, die zweite Brille ist sichtbar.

**Erreicht:** Plan- und Statusdateien aktualisiert, Hinweis zur Server-IP in README und INSTALL.

**Offen:** siehe [plan.md](plan.md): Tests mit 4 und 8 Brillen, Rotationsvorzeichen, Avatar-Verbesserungen, Module für Greifen und Sketching.
