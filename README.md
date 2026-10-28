# Situs Core

Co-located Multiuser-VR-Template für **Godot 4.7** (GL Compatibility, OpenXR).
Bis zu 8 XR-Clients im selben physischen Raum plus Desktop-Server, verbunden über LAN (ENet UDP, Port 7777).

**Hardware:** HTC Vive Focus Vision, HTC Focus 3 · *Pico 4 Ultimate: geplant* · Meta Quest wird nicht mehr unterstützt.

**Neu auf einem Rechner?** Siehe [Installation und Konfiguration](docs/INSTALL.md).

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
3. `export_presets.cfg.template` als `export_presets.cfg` kopieren (das Setup-Skript macht das, siehe [docs/INSTALL.md](docs/INSTALL.md)).
4. Plugin [Godot OpenXR Vendors](https://github.com/GodotVR/godot_openxr_vendors) nach `addons/godotopenxrvendors/` installieren (HTC-Support). Das Setup-Skript erledigt das.
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

## Einstellungen

Das Plugin legt im Editor unter *Project Settings → Situs Core* diese Felder an. Die Werte stehen in `project.godot` und sind damit in der APK. Sie gelten auch beim Play im Editor, ein Export ist dafür nicht nötig. Nach einer Änderung an Server-IP, Raum oder Drehung muss die APK neu exportiert werden.

| Setting | Bedeutung | Default |
|---------|-----------|---------|
| `situs_core/network/server_ip` | IP des Servers, zu der sich Clients verbinden | `127.0.0.1` |
| `situs_core/room/width_m` | Breite der Spielfläche (Weltachse x) in m | `4.0` |
| `situs_core/room/length_m` | Länge der Spielfläche (Weltachse z) in m | `8.0` |
| `situs_core/room/rotation_deg` | Drehung des Tracking-Raums der Brillen gegenüber der Welt, in Grad | `0` |

- **Rotation:** Sie wird auf den XR-Ursprung angewendet, nicht auf die Szenen. Alle Szenen passen sich automatisch an. Damit lässt sich die Ausrichtung des Raums korrigieren, ohne die Brillen neu auszurichten. Ein Wert gilt für alle Brillen.
- **Andere IP nur für die APK:** Bei der Einstellung *Override For…* → `android` wählen. Dann gilt im Editor weiter der Standardwert.
- **Spielfläche:** Sie begrenzt die Bewegung (Thumbstick und FPS) und wird aus Breite und Länge erzeugt. Szenen lesen die Werte über `SitusSettings` (`addons/situs_core/core/situs_settings.gd`, z. B. `get_room_size()`).

## Installation und Konfiguration

Einrichtung auf einem neuen Rechner (Godot, Android-Export, Brille) und was das Setup-Skript installiert: **[docs/INSTALL.md](docs/INSTALL.md)**.

Kurz: Godot 4.7.2 installieren, `tools/setup_android.ps1` ausführen, Projekt öffnen, F5. Für die Brille zusätzlich Server-IP setzen und die APK exportieren (Preset „Android – HTC Focus 3“, gilt auch für Focus Vision).

**Lokal testen:** F5, *Als Server starten*. Zweite Instanz (*Debug → Run Multiple Instances*): *Als Spieler starten (First Person)*.

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
docs/                       ← INSTALL.md sowie Architektur und Anleitungen (stammen aus Hyper-Irrealismus III)
tools/setup_android.ps1     ← richtet einen Rechner für den Android-Export ein
project.godot               ← Demo-Host
openxr_action_map.tres      ← Controller-Belegung (muss im Projekt-Root liegen)
```

> **Hinweis zu `docs/`:** Die Dokumente stammen aus dem Ursprungsprojekt. Pfade wurden mechanisch angepasst, die Texte sind noch nicht auf die Modul-Struktur überarbeitet.
