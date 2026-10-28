# Situs Core: Plan und TODO

Stand 2026-10-28. Version im Repo: 1.1.0 (noch nicht getaggt).

## Stand

- Repo extrahiert aus Hyper-Irrealismus III (gefilterte Historie), Godot 4.7, nur GL Compatibility.
- Plugin `addons/situs_core/` über Branch `dist` per git subtree einbindbar.
- Optionales Modul `modul_scene_loop`. Ohne Module läuft eine Szene (`situs_core/default_scene`).
- Einstellungen in den Project Settings: Server-IP, Raumbreite und -länge, Rotation (am XR-Ursprung).
- Setup-Skript und Anleitung: `tools/setup_android.ps1`, `docs/INSTALL.md`.
- Erster echter Einsatz: MatLab_CommTest (Branch `feature/situs-core`). Dort ist ein Datenkanal-Modul entstanden, das später hierher wandert.

**Nicht an echter Hardware geprüft:** Rotationsvorzeichen, Android-Override der Server-IP, Betrieb mit mehreren Brillen im WLAN, das Setup-Skript im Situs-Repo (nur Syntax geprüft).

## TODO-Liste

### Nach den Tests in MatLab_CommTest

Siehe `MatLab_CommTest/docs/plan.md`. Davon hängen hier ab:

- [ ] Multiplayer-Test mit 1, 4 und 8 Brillen bestanden.
- [ ] Rotationsvorzeichen und Android-Override bestätigt, Texte in `README.md` angepasst.
- [ ] Tags `v1.0.0` und `v1.1.0` setzen, `dist` neu bauen (`git subtree split --prefix=addons/situs_core -b dist`, danach pushen).
- [ ] Uncommittete Änderung an `project.godot` klären (committen oder verwerfen).

### Setup und Dokumentation

- [ ] `tools/setup_android.ps1` auf einem frischen Rechner komplett durchlaufen lassen.
- [ ] Das Skript nur an einer Stelle pflegen. Aktuell gibt es Kopien in Situs und in MatLab_CommTest. Idee: Kopie im Plugin, Projekte rufen sie auf.
- [ ] `docs/` (ARCHITECTURE, dev_team, venue_team, design_teams) stammt aus Hyper-Irrealismus III und ist nicht auf die Modul-Struktur überarbeitet.

### Neue Module und Funktionen

- [ ] `modul_data_channel` aus MatLab_CommTest übernehmen: Ordner nach `addons/situs_core/modules/`, Eintrag in `MODULE_AUTOLOADS` in `plugin.gd`, README ergänzen.
- [ ] Jitter-Puffer im Datenkanal (Serverzeit liegt im Frame).
- [ ] Einstellungen anderer Module im Editor registrieren (z. B. `sim/udp_port`, `sim/udp_on_clients`).
- [ ] Weitere Module (Liste im README ergänzen).

### Hardware

- [ ] Pico 4 Ultimate: Export-Preset und Plugin-Support (Vendors-Plugin).
- [ ] Marker-Ausrichtung der Brillen (`docs/plan_marker_ausrichtung.md`).

### Migration

- [ ] Hyper-Irrealismus III auf Situs umstellen (Plan: `docs/HI3_MIGRATION_PLAN.md`). Bewusst zurückgestellt, HI-III bleibt bis dahin unverändert.
