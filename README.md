# Hyper-Irrealismus III

Multiplayer VR Ausstellungstemplate. Bis zu 8 XR-Clients (HTC Vive Focus Vision, HTC Focus 3, Meta Quest 2/3/Pro)
+ Desktop-Server, verbunden über LAN via ENet UDP.

Gebaut mit **Godot 4.6** — GL Compatibility Renderer, OpenXR.

**Standalone-Modus:** Alle Clients (VR-Brillen und FPS-Desktop) laufen auch ohne Server — Szenenwechsel automatisch per Timer oder manuell per Button/Taste.

---

## Dokumentation

| Dokument | Für wen |
|----------|---------|
| [Design Teams](_anleitungen/design_teams.md) | Szenen erstellen, Assets importieren, Git-Workflow |
| [Venue Team](_anleitungen/venue_team.md) | Server starten, Brillen starten, Troubleshooting |
| [Dev Team](_anleitungen/dev_team.md) | Team-Szenen integrieren, APK bauen, Ausstellungsvorbereitung |
| [ARCHITECTURE.md](_anleitungen/ARCHITECTURE.md) | Technische Vollreferenz: Module, Einstellungen, Changelog |

---

## Schnellstart

**Lokal testen (PC, kein Headset):**
```
1. project.godot in Godot 4.6 öffnen
2. F5 → Startmenü → „Als Server starten"
3. Zweite Instanz: Debug → Run Multiple Instances → „Als Spieler starten (First Person)"
```

**Einzelne Szene testen (F6 Solo):**
```
_scenes/team_X/team_X.tscn im Editor öffnen → F6
```

**Server-IP konfigurieren** (vor APK-Build):
```
SYSTEM/networking/network_manager.gd  →  Zeile 24:  var server_ip: String = "192.168.1.100"
```

**APK bauen:**
```
Project → Export → „Android – Meta Quest"   → Hyper-Irrealismus-III-Quest.apk
Project → Export → „Android – HTC Focus 3"  → Hyper-Irrealismus-III-Focus3.apk
```
(Focus Vision verwendet denselben APK wie Focus 3.)

---

## Steuerung

**VR-Controller (HTC Vive Focus Vision / Meta Quest) — beide Controller gleichwertig:**

| Taste | Funktion |
|-------|---------|
| A oder X | Standalone-Modus aktivieren |
| B oder Y | Nächste Szene |
| Thumbstick Y | Bewegung vor/zurück |
| Thumbstick X | Drehung links/rechts |

**FPS-Desktop-Client (PC ohne Headset):**

| Taste | Funktion |
|-------|---------|
| Q | Vorherige Szene (+ Standalone aktivieren) |
| E | Nächste Szene (+ Standalone aktivieren) |
| WASD / Pfeiltasten | Bewegung |
| Maus | Umsehen |
| Leertaste | Springen |
| ESC | Maus freigeben |

**Standalone-Modus** — läuft ohne Server:
- VR: beliebigen Button drücken → Standalone aktiv, Szenen laufen per Timer durch
- FPS: Q oder E drücken → Standalone aktiv, Szenen manuell navigierbar

---

## Ordnerstruktur

```
_anleitungen/            ← Dokumentation für alle Gruppen
_scenes/                 ← Alle Szenen — nur Design Teams arbeiten hier
  team_template/         ← Vorlage: duplizieren für jeden Team-Ordner
  team_X/                ← Team-Ordner: scene_info.cfg + Szene + Assets
  scene_registry.gd      ← Ausstellungsreihenfolge (nur Dev Team)
SYSTEM/                  ← Core-System (nur Dev Team)
  avatar/                ← Avatar-Varianten
  networking/            ← Netzwerk-Autoloads (GameState, NetworkManager)
  player/                ← FPS + XR Player
  cam_dolly.gd
  main.gd / main.tscn    ← Root-Szene
  openxr_action_map.tres ← Controller-Belegung
  scene_manager.gd       ← Autoload SceneManager
project.godot            ← Godot Projektdatei
```
