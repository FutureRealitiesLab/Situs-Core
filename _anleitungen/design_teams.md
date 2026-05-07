# Hyper-Irrealismus III — Anleitung für Design Teams

## Inhalt

1. [Euer Toolkit](#euer-toolkit)
2. [Godot installieren & Projekt öffnen](#godot-installieren-und-projekt-öffnen)
3. [Team-Ordner anlegen](#euren-team-ordner-anlegen)
4. [scene\_info.cfg ausfüllen](#scene_infocfg--pflichtdatei)
5. [Szene testen (F6)](#eure-szene-testen--f6-solo-test)
6. [3D-Scans importieren](#eigene-3d-scans-importieren)
7. [Animationen](#animationen)
8. [Sounds hinzufügen](#sounds-hinzufügen)
9. [Atmosphäre einstellen](#hintergrundfarbe--atmosphäre-einstellen)
10. [Stand hochladen](#euren-stand-hochladen)
11. [Abgabe-Checkliste](#abgabe-checkliste)

---

## Euer Toolkit

| Tool | Wozu |
|------|------|
| **Dieses Projekt** (GitHub) | Euer Arbeitsbereich — Pablo schickt euch die Einladung |
| **Godot 4.6 Standard** | Szene bauen, testen, Assets platzieren |
| **Blender** | 3D-Modellierung und Sculpting |
| **Meshy** | KI-generierte 3D-Modelle |
| **Polycam** | 3D-Scans mit dem Smartphone |

Ihr arbeitet ausschließlich in eurem eigenen Ordner: `_scenes/team_X/`
Alle anderen Dateien sind Systemdateien — **bitte nicht anfassen**.

---

## Godot installieren und Projekt öffnen

1. **Godot 4.6 Standard** herunterladen: [godotengine.org/download](https://godotengine.org/download)
   → Version „Standard" wählen (nicht „.NET / Mono" — kein C# nötig)

2. Godot starten → **Import** → Projektordner auswählen → `project.godot` öffnen

3. Beim ersten Start werden alle Assets importiert — das dauert 1–2 Minuten, bitte warten

---

## Euren Team-Ordner anlegen

Alles was ihr macht, lebt in **einem einzigen Ordner**: `_scenes/team_X/`

1. Im Godot **FileSystem-Fenster** (unten links): `_scenes/team_template/` suchen
2. Rechtsklick auf `team_template/` → **Duplicate** → Godot erstellt `team_template2/`
3. Den neuen Ordner umbenennen: Rechtsklick → **Rename** → z. B. `team_a`
4. Darin die Dateien umbenennen:
   - `team_scene.tscn` → `team_a.tscn`
   - `team_scene.gd` → `team_a.gd`
5. `team_a.tscn` öffnen → im **Inspector** das Script-Feld auf `team_a.gd` umstellen

> Ab jetzt arbeitet ihr ausschließlich in `_scenes/team_a/` — dieser Ordner ist eure Abgabe.

> **Was ist schon in der Szene?**
> - **WorldEnvironment + DirectionalLight3D** — Licht und Himmel sind voreingestellt
> - **Floor** — Boden mit Kollision; kann behalten, verschoben oder gelöscht werden
> - **ServerCamera** — wird automatisch positioniert; nicht anfassen
>
> Alles unterhalb des Trennstrich-Nodes ist euer Arbeitsbereich.

---

## scene_info.cfg — Pflichtdatei

In eurem Ordner liegt bereits eine `scene_info.cfg`.
Öffnet sie mit einem Texteditor (Notepad, VS Code, …) und tragt eure Daten ein:

```ini
name       = "Team A – Euer Titel"    ← Anzeigename in der Ausstellung
duration   = 120.0                     ← Wie viele Sekunden läuft eure Szene?
scene_file = "team_a.tscn"            ← Dateiname eurer Hauptszene
team       = "Team A"                  ← Euer Teamname

; Optional:
info         = "Kurzbeschreibung der Installation"    ← erscheint im Fade-Overlay
avatar       = "res://avatar/variants/avatar_box.tscn" ← Standard: avatar_dynamic_cone
player_color = Color(1.0, 0.0, 0.5, 1)               ← alle Spieler gleiche Farbe
													  ;  weglassen = individuelle Farben
```

Die Pflichtfelder reichen für die Abgabe. Die optionalen Felder kann Pablo auch nachträglich setzen.

---

## Eure Szene testen — F6 Solo-Test

Ihr wollt sehen wie eure Szene aussieht, Objekte platzieren, Sound hören.
**Kein Server, kein Netzwerk nötig.**

```
1. Im FileSystem-Fenster: _scenes/team_a/team_a.tscn doppelklicken
2. Taste F6 drücken  (= aktuelle Szene starten, nicht das ganze Projekt)
3. Fertig — eure Szene läuft mit Licht, Sounds und allem
   Beenden: Escape oder Fenster schließen
```

> **F5** startet immer `main.tscn` (mit Netzwerk und Menü) — das braucht ihr nicht.
> **F6** startet die gerade geöffnete Szene direkt — das ist euer Test-Werkzeug.

---

## Eigene 3D-Scans importieren

Alle 3D-Dateien kommen direkt in euren Team-Ordner `_scenes/team_a/`.

### Export aus der Scan-Software
| Software | Exportformat |
|----------|-------------|
| Polycam | GLB (Export → GLTF → GLB) |
| RealityCapture | GLB (Export Mesh → GLTF 2.0) |
| Meshy | GLB (Download → GLB) |

Empfehlung: maximal **500.000 Polygone** exportieren.

### In Godot importieren
1. GLB-Datei aus dem Explorer **in euren Team-Ordner** im FileSystem-Fenster ziehen
2. Godot importiert automatisch (Zahnrad-Symbol erscheint kurz)
3. Importierte GLB aus FileSystem in das **3D-Viewport-Fenster** ziehen
4. Im 3D-Viewport: Position, Rotation, Skalierung anpassen

> Bei sehr großen Scans: Datei im FileSystem anklicken → Reiter **„Import"** →
> **„Generate LODs"** aktivieren → **„Reimport"** klicken

---

## Animationen

### Export mit Animationen

| Software | Export |
|----------|--------|
| Blender | File → Export → glTF 2.0 (.glb) → „Include: Animations" aktiv lassen |
| Meshy | Download → GLB — Animationen bereits eingebettet |

### In Godot importieren

Gleich wie bei 3D-Scans: GLB in euren Team-Ordner ziehen → automatisch importiert → aus FileSystem in den 3D-Viewport ziehen.

### Animation abspielen — kein Code nötig

1. Importierte GLB in der Szene anklicken → Scene-Baum aufklappen
2. `AnimationPlayer`-Node darin anklicken
3. Im **Inspector**: **Autoplay** → Animationsname eintragen (z. B. `Idle`, `Walk`)
4. F6 → Animation läuft automatisch

**Optional — via Code steuern:**

```gdscript
func _ready() -> void:
	$MeinModell/AnimationPlayer.play("Idle")
```

> Animationsname muss exakt dem Namen im AnimationPlayer entsprechen (Groß-/Kleinschreibung beachten).

---

## Sounds hinzufügen

Sounddateien kommen ebenfalls direkt in euren Team-Ordner.

### Dateiformat
- `.ogg` bevorzugen (gut komprimiert, ideal für Loops)
- `.wav` + `.mp3` funktionieren auch

### In Godot einbauen

**Schritt 1** — Audiodatei in euren Team-Ordner im FileSystem-Fenster ziehen

**Schritt 2** — In `team_a.tscn`: **+** (Kind hinzufügen) → `AudioStreamPlayer3D` → Name z. B. `Ambience`

**Schritt 3** — Im **Inspector**:
- **Stream** → eure `.ogg`-Datei (oder andere Audiodatei) zuweisen
- **Autoplay** → ein (für Dauerton)
- **Max Distance** → Reichweite in Metern

---

## Hintergrundfarbe / Atmosphäre einstellen

In `team_a.tscn`: **WorldEnvironment** anklicken → im Inspector auf **Environment** klicken.

- **Background → Mode**: `Color` → Farbe wählen
- **Ambient Light → Source**: `Color` → ähnliche Farbe, leicht heller
- **Ambient Light → Energy**: `0.3` – `0.6`

> Dunkle, gesättigte Farben wirken in VR atmosphärischer als helle.

---

## Euren Stand hochladen

**Einmalig zu Beginn:** In GitHub Desktop oben „Current Branch" → „New Branch" → Namen eingeben: `team-a` (euer Teamname, ohne Leerzeichen)

**Danach jeden Tag:**

1. **Fetch origin** — immer zuerst
2. Sicherstellen dass oben `team-a` steht (nicht `main`)
3. Dateien in `_scenes/team_a/` bearbeiten
4. In GitHub Desktop: nur Dateien in `_scenes/team_a/` abhaken
5. Kurze Notiz schreiben → **Commit to `team-a`** → **Push origin**

Pablo reviewed die Branches und merged in main — ihr müsst euch darum nicht kümmern.

> Godot erzeugt für jede importierte Datei eine `.import`-Datei (z. B. `scan.glb.import`). Diese Dateien **müssen mit committed werden** — GitHub Desktop zeigt sie automatisch an, einfach zusammen mit euren Dateien abhaken.

---

## Abgabe-Checkliste

- [ ] `scene_info.cfg` ausgefüllt (name, duration, scene_file, team)
- [ ] Szene läuft mit F6 ohne Fehler
- [ ] 3D-Assets und Sounds sind im Team-Ordner (nicht in einem anderen Ordner)
- [ ] Stand auf Branch gepusht (Pablo merged)
