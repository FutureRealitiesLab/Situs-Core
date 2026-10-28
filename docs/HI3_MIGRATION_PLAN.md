# Plan: Hyper-Irrealismus III auf Situs Core umstellen

Status: **nicht ausgeführt.** HI-III bleibt vorerst auf dem aktuellen Stand (Godot 4.6, `SYSTEM/`).
Voraussetzung: Situs Core ist in Godot 4.7 getestet und als `v1.0.0` getaggt.

## Befund (Stand der Analyse)

- Team-Szenen unter `_scenes/` rufen **keine** Core-API direkt auf. Sie hängen nur an `scene_hooks.gd` → `SceneManager.on_team_scene_ready()`, und diese Methode gibt es im neuen Core weiterhin.
- Einzige `res://SYSTEM/`-Referenzen außerhalb von `SYSTEM/` selbst: `project.godot`, `README.md`, `_anleitungen/*.md`, `_scenes/team_template/scene_info.cfg` (Kommentare).
- Team-Szenen verweisen auf `res://_scenes/team_template/team_scene.gd` (UID). `scene_hooks.gd` liegt im selben Ordner und bleibt dort. **`_scenes/team_template/` bleibt deshalb unverändert in HI-III.**
- `scene_registry.gd` bleibt in `_scenes/` (Default-Pfad von `modul_scene_loop`).
- Geändert gegenüber dem alten Core: `timer_tick`, `auto_advance`, `toggle_auto_advance`, `go_to_scene` wanderten aus `SceneManager` nach `SceneLoop`. Team-Code nutzt sie nicht (geprüft per grep).

## Ablauf

Alles auf einem eigenen Branch, `master` bleibt unberührt bis alles getestet ist.

1. **Branch anlegen**
   ```bash
   git checkout -b migrate/situs-core
   git remote add situs-core https://github.com/FutureRealitiesLab/Situs-Core.git
   ```
2. **Alten Core entfernen, neuen als Subtree einbinden**
   ```bash
   git rm -r SYSTEM/
   git commit -m "chore: SYSTEM/ entfernt (ersetzt durch Situs Core)"
   git subtree add --prefix=addons/situs_core situs-core dist --squash
   ```
3. **Meta Quest entfernen** (wie im Core, siehe dort Commit „Meta Quest entfernt“)
   - `addons/godot_meta_toolkit/` löschen
   - `openxr_action_map.tres`: `oculus/touch_controller` entfernen
   - `export_presets.cfg.template`: Meta-Quest-Preset und `meta_*`-Optionen entfernen
   - `project.godot`: `openxr/extensions/meta/...` entfernen
   - `addons/godotopenxrvendors/` **bleibt** (HTC)
4. **`project.godot` anpassen**
   - `config/features`: `("4.7", "GL Compatibility")`
   - `run/main_scene="res://addons/situs_core/core/main.tscn"`, Zeile `config/main_scene=` entfernen
   - Autoloads: `GameState`, `NetworkManager`, `SceneManager` auf `addons/situs_core/...`, danach `SceneLoop="*res://addons/situs_core/modules/modul_scene_loop/scene_loop.gd"` (muss **nach** `SceneManager` stehen)
   - `[editor_plugins] enabled=PackedStringArray("res://addons/situs_core/plugin.cfg")`
   - Der Input `scene_next`, `scene_loop_toggle`, `debug_toggle` bleiben wie sie sind
5. **Pfade in Doku und Kommentaren**
   - `res://SYSTEM/avatar/...` → `res://addons/situs_core/avatar/...` (u. a. `_scenes/team_template/scene_info.cfg`)
   - `README.md`, `_anleitungen/*.md`: `SYSTEM/` durch die neuen Pfade ersetzen (`core/` für main, scene_manager, cam_dolly, net_info_board), Quest-Hinweise entfernen
6. **Godot 4.7 öffnen**, Migrationsdialog bestätigen, Output auf Deprecations prüfen. Dabei werden `.uid`-Dateien erzeugt. In HI-III steht `*.uid` in der `.gitignore`: entscheiden, ob das so bleibt.
7. **Tests**
   - F5: Startmenü → Server + FPS-Spieler → Szenen laufen im Loop, Timer, N, L
   - F6 auf einer Team-Szene
   - Alle Szenen aus `scene_registry.gd` einmal durchschalten
   - Standalone: Q/E am Desktop
   - APK „Android – HTC Focus 3" bauen, auf Focus Vision testen (Co-Location, Avatare, Szenenwechsel)
8. **Merge nach `master`**, erst wenn Punkt 7 grün ist.

## Updates später

```bash
git subtree pull --prefix=addons/situs_core situs-core dist --squash
```

Änderungen am Core sollen im Situs-Core-Repo passieren (dann `dist` neu erzeugen), nicht lokal in `addons/situs_core/` von HI-III. Sonst entstehen Subtree-Konflikte.

## Risiken

| Risiko | Gegenmaßnahme |
|--------|---------------|
| Godot 4.6 → 4.7 bricht Szenen oder Skripte | eigener Branch, Output-Panel prüfen, `master` unverändert |
| Szenen im Loop laden nicht (Pfad, UID) | Registry-Szenen einzeln mit F6 öffnen, Fehler im Output lesen |
| `scene_hooks`-UID wird nicht gefunden | `_scenes/team_template/` unverändert lassen |
| Repo-Größe (4,5 GiB) wird zum Problem bei Clone | unabhängig von dieser Migration; ggf. später Git LFS |
| Core wird lokal verändert und driftet | Änderungen immer zuerst im Situs-Core-Repo |
