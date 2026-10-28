# Situs Core

Co-located Multiuser-VR-Template für **Godot 4.7** (GL Compatibility, OpenXR).
Bis zu 8 XR-Clients im selben physischen Raum plus Desktop-Server, verbunden über LAN (ENet UDP, Port 7777).

**Hardware:** HTC Vive Focus Vision, HTC Focus 3 · *Pico 4 Ultimate: geplant* · Meta Quest wird nicht mehr unterstützt.

Situs Core entstand aus dem Projekt [Hyper-Irrealismus III](https://github.com/FutureRealitiesLab/Hyper-Irrealismus-III) und ist ein Godot-Plugin (`addons/situs_core/`), das in beliebige Projekte eingebunden wird.

---

## Was der Core kann

- Startmenü: Server, Spieler (First Person), XR-Client (automatisch, wenn OpenXR läuft)
- Netzwerk: ENet-Relay, Spieler-Positionen, Farben, automatischer Reconnect
- Spieler: XR-Player (Thumbstick-Bewegung, Walk-Area) und FPS-Player (Desktop)
- Avatare: Remote-Avatare mit Varianten (Dynamic Cone, Box, Capsule, Sphere, Ghost)
- Fade-Übergang zwischen Szenen, Server-HUD, Netzwerk-Diagnose (Tab)
- Ohne Module läuft **eine** Szene (`situs_core/default_scene`, Standard: `templates/team_scene.tscn`)

## Module

Module liegen unter `addons/situs_core/modules/` und sind optional: Ordner löschen oder in den Project Settings deaktivieren.
Das Plugin registriert ihre Autoloads automatisch.

| Modul | Zweck |
|-------|-------|
| [`modul_scene_loop`](addons/situs_core/modules/modul_scene_loop/README.md) | Mehrere Szenen nacheinander abspielen: Registry, Timer, Auto-Wechsel, Standalone-Navigation |

Weitere Module folgen.

---

## Einbinden in ein Projekt (git subtree)

Das Plugin liegt im Repo unter `addons/situs_core/`. Für Projekte gibt es den Branch **`dist`**, der nur diesen Ordnerinhalt enthält.

```bash
git remote add situs-core git@github.com:futurerealitieslab/situs-core.git
git subtree add --prefix=addons/situs_core situs-core dist --squash
```

Dann in Godot: *Project → Project Settings → Plugins → Situs Core → Enable*.
Das Plugin trägt die Autoloads ein. Außerdem im Projekt nötig:

1. `project.godot`: `Rendering → Renderer: GL Compatibility`, OpenXR aktivieren, `openxr/action_map="res://openxr_action_map.tres"`.
   Außerdem `XR → OpenXR → Startup Alert` ausschalten (`openxr/startup_alert=false`), sonst erscheint am PC ohne Headset bei jedem Start eine Fehlermeldung.
2. `openxr_action_map.tres` ins Projekt-Root kopieren (Godot verlangt sie dort).
3. `export_presets.cfg.template` als `export_presets.cfg` kopieren.
4. Plugin [Godot OpenXR Vendors](https://github.com/GodotVR/godot_openxr_vendors) nach `addons/godotopenxrvendors/` installieren (HTC-Support).
5. Hauptszene: `res://addons/situs_core/core/main.tscn`.

**Update einspielen:**

```bash
git subtree pull --prefix=addons/situs_core situs-core dist --squash
```

**`dist` aktualisieren** (im situs-core-Repo, nach Änderungen auf `main`):

```bash
git subtree split --prefix=addons/situs_core -b dist
git push origin dist
```

---

## Schnellstart (dieses Repo als Demo-Projekt)

```
1. Godot 4.7 starten, project.godot öffnen
2. addons/godotopenxrvendors/ installieren (siehe oben), sonst fehlt der Android/OpenXR-Support
3. F5 → „Als Server starten"
4. Zweite Instanz (Debug → Run Multiple Instances): „Als Spieler starten (First Person)"
```

**Server-IP** vor dem APK-Build: `addons/situs_core/networking/network_manager.gd` → `server_ip`.

**APK:** `export_presets.cfg.template` → `export_presets.cfg`, dann *Project → Export → „Android – HTC Focus 3"* (gilt auch für Focus Vision).

## Steuerung

**VR-Controller (HTC):** A/X Standalone aktivieren · B/Y nächste Szene (Szenen-Modul) · Thumbstick Y Bewegung · Thumbstick X Drehung

**FPS-Desktop:** WASD/Pfeile Bewegung · Maus Umsehen · Leertaste Springen · Q/E Szene zurück/vor (Szenen-Modul) · ESC Maus freigeben · Tab Netzwerk-Diagnose

---

## Ordnerstruktur

```
addons/situs_core/
  plugin.cfg, plugin.gd     ← Plugin: Autoloads + Inputs
  core/                     ← main.tscn/.gd, scene_manager, cam_dolly, net_info_board
  networking/               ← GameState, NetworkManager (Autoloads)
  player/                   ← xr_player, fps_player
  avatar/                   ← remote_avatar + variants/
  templates/                ← scene_hooks.gd, team_scene.tscn (kopieren)
  modules/
    modul_scene_loop/       ← optionales Modul
docs/                       ← Architektur und Anleitungen (stammen aus Hyper-Irrealismus III)
project.godot               ← Demo-Host
openxr_action_map.tres      ← Controller-Belegung (muss im Projekt-Root liegen)
```

> **Hinweis zu `docs/`:** Die Dokumente stammen aus dem Ursprungsprojekt. Pfade wurden mechanisch angepasst, die Texte sind noch nicht auf die Modul-Struktur überarbeitet.
