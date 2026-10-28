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

## Schnellstart (dieses Repo als Demo-Projekt)

```
1. Godot 4.7 starten, project.godot öffnen
2. addons/godotopenxrvendors/ installieren (siehe oben), sonst fehlt der Android/OpenXR-Support
3. F5 → „Als Server starten"
4. Zweite Instanz (Debug → Run Multiple Instances): „Als Spieler starten (First Person)"
```

**Server-IP** vor dem APK-Export: *Project Settings → Situs Core → Network → Server Ip*.

**APK:** `export_presets.cfg.template` → `export_presets.cfg`, dann *Project → Export → „Android – HTC Focus 3"* (gilt auch für Focus Vision). Was dafür einmalig installiert sein muss, steht im nächsten Abschnitt.

## APK-Export für HTC Vive Focus 3 und Focus Vision

Die Einstellungen stammen aus Projekten, in denen der Export auf der Focus Vision funktioniert hat (Godot 4.7.2).

### 1. Einmalig pro Rechner

| Was | Wie |
|-----|-----|
| **Export-Vorlagen** | Godot: *Editor → Export-Vorlagen verwalten → Herunterladen und installieren*. Die Version muss zur Godot-Version passen (z. B. 4.7.2 stable, etwa 1,3 GB). Offline: `Godot_v4.7.2-stable_export_templates.tpz` von [godot-builds](https://github.com/godotengine/godot-builds/releases) laden und dort *Aus Datei installieren*. Seit Godot 4.7 wählst du die Vorlagen einzeln aus: Für die Brille genügt der Haken bei **Mobil → Android → `android_source.zip`** (wir nutzen den Gradle-Build). `android_debug.apk` und `android_release.apk` brauchst du nur ohne Gradle-Build. Windows-Vorlagen brauchst du nur, wenn du den Server als `.exe` exportierst. |
| **JDK 17** | `winget install --id Microsoft.OpenJDK.17 -e` |
| **Android SDK** | Command-line Tools von Google, dann `platform-tools`, `build-tools;36.1.0`, `platforms;android-36`, `ndk;29.0.14206865`, `cmake;3.22.1` per `sdkmanager` installieren und die Lizenzen akzeptieren. Die Versionen gelten für Godot 4.7.2, bei anderen Godot-Versionen in der Godot-Doku nachsehen. |
| **Debug-Keystore** | Einmal erzeugen (Pfad und Passwörter unten bei den Editor-Einstellungen). |
| **Editor-Einstellungen** | *Editor → Editor-Einstellungen → Export → Android*: *Java SDK Path* (JDK-Ordner), *Android SDK Path* (z. B. `%LOCALAPPDATA%\Android\Sdk`), *Debug Keystore* (die erzeugte Datei), *Debug Keystore User* `androiddebugkey`, *Debug Keystore Pass* `android`. |
| **OpenXR-Vendors-Plugin** | [Godot OpenXR Vendors](https://github.com/GodotVR/godot_openxr_vendors/releases) (verwendet: `5.1.0-stable`) laden, den Ordner `asset/addons/godotopenxrvendors` nach `addons/godotopenxrvendors/` im Projekt kopieren. Dieses Plugin liegt nicht im Repo. |
| **Android-Build-Vorlage** | Im Projekt: *Projekt → Android-Build-Vorlage installieren*. Es entsteht der Ordner `android/`. |
| **Brille** | Entwicklermodus aktivieren und per USB (oder WLAN-`adb`) verbinden. `adb devices` muss sie anzeigen. |

Debug-Keystore erzeugen (Pfad anpassen, `JAVA_HOME` zeigt auf das JDK):

```powershell
& "$env:JAVA_HOME\bin\keytool.exe" -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore "$env:APPDATA\Godot\keystores\debug.keystore" -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
```

Das Skript `tools/setup_android.ps1` im Repo [MatLab_CommTest](https://github.com/FutureRealitiesLab/MatLab_CommTest) erledigt alle diese Schritte automatisch (JDK, SDK, Vorlagen, Build-Vorlage, Plugin, Keystore, Editor-Einstellungen).

### 2. Project Settings

| Setting | Wert |
|---------|------|
| Rendering → Renderer → Rendering Method (und `.mobile`) | `gl_compatibility` |
| Rendering → Textures → VRAM Compression → Import ETC2 ASTC | an |
| XR → OpenXR → Enabled | an |
| XR → Shaders → Enabled | an |
| XR → OpenXR → Startup Alert | aus (sonst erscheint am PC ohne Headset eine Fehlermeldung) |
| Situs Core → Network → Server Ip | IP des Server-PCs |

### 3. Export-Preset (*Projekt → Exportieren → Hinzufügen → Android*)

Das Preset „Android – HTC Focus 3“ in `export_presets.cfg.template` enthält Gradle, Architektur, XR und Berechtigungen bereits. *Runnable* ist dort aus (nur nötig für den Ein-Klick-Start auf der Brille), und *Unique Name* ist ein Platzhalter, den du anpasst. Falls du das Preset selbst anlegst:

| Bereich | Einstellung |
|---------|-------------|
| Allgemein | *Runnable* an, *Erweiterte Optionen* an, Exportfilter *Alle Ressourcen* |
| Gradle Build | *Use Gradle Build* **an**, Export Format *APK* |
| Architekturen | nur **arm64-v8a** |
| Paket | *Unique Name* je Projekt eindeutig (z. B. `org.firma.projekt`), *Signed* an |
| XR Features | *XR Mode* **OpenXR**, *Enable Khronos Plugin* **an** |
| Khronos XR Features | im Situs-Template zusätzlich `vendors=1` (HTC) |
| Bildschirm | *Immersive Mode* an |
| Berechtigungen | *Internet*, *Access Network State*, *Access Wifi State* an (nötig für ENet und UDP) |
| Meta | *Enable Meta Plugin* aus |

Hinweis: Auf der Focus Vision hat auch ein Preset nur mit *Enable Khronos Plugin* und ohne den Vendors-Wert funktioniert.

### 4. Exportieren und installieren

```powershell
$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot"
```

```powershell
Godot --headless --path . --export-debug "Android – HTC Focus 3" build/SitusCore-Focus3.apk
```

```powershell
adb install -r build/SitusCore-Focus3.apk
```

Alternativ im Editor: *Projekt → Exportieren → Exportieren*. Die APK ist ein Debug-Build mit dem Debug-Keystore. Eine geänderte Server-IP, Raumgröße oder Drehung wirkt erst nach einem neuen Export.

**Wenn der Export fehlschlägt:** Die Meldung nennt meist den fehlenden Teil (Export-Vorlagen nicht installiert, *Android SDK Path* leer, Build-Vorlage fehlt, `addons/godotopenxrvendors` fehlt). Prüfe diese Punkte in der Reihenfolge aus Abschnitt 1.

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
