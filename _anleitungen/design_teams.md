# Hyper-Irrealismus III — Anleitung für Design Teams

---

## Was ihr bekommt

Pablo gibt euch Zugang zum **Git-Repository** oder eine **ZIP des Projekts**.
Ihr arbeitet ausschließlich in eurem eigenen Ordner: `_scenes/team_X/`

Alle anderen Ordner und Dateien sind Systemdateien — **bitte nicht anfassen**.
Sie sind mit `# TEMPLATE CORE – nicht verändern` markiert.

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

---

## scene_info.cfg — Pflichtdatei

In eurem Ordner liegt bereits eine `scene_info.cfg`.
Öffnet sie mit einem Texteditor (Notepad, VS Code, …) und tragt eure Daten ein:

```ini
name       = "Team A – Euer Titel"    ← Anzeigename in der Ausstellung
duration   = 120.0                     ← Wie viele Sekunden läuft eure Szene?
scene_file = "team_a.tscn"            ← Dateiname eurer Hauptszene
team       = "Team A"                  ← Euer Teamname
```

Mehr ist nicht nötig. Pablo trägt euren Ordner dann in die Ausstellungsreihenfolge ein.

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

## Sounds hinzufügen

Sounddateien kommen ebenfalls direkt in euren Team-Ordner.

### Dateiformat
- `.ogg` bevorzugen (gut komprimiert, ideal für Loops)
- `.wav` funktioniert auch

### In Godot einbauen

**Schritt 1** — Audiodatei in euren Team-Ordner im FileSystem-Fenster ziehen

**Schritt 2** — In `team_a.tscn`: **+** (Kind hinzufügen) → `AudioStreamPlayer3D` → Name z. B. `Ambience`

**Schritt 3** — Im **Inspector**:
- **Stream** → eure `.ogg`-Datei zuweisen
- **Autoplay** → ein (für Dauerton)
- **Max Distance** → Reichweite in Metern

**Schritt 4** — In `team_a.gd`:

```gdscript
func _ready() -> void:
    $Ambience.play()

func _exit_tree() -> void:
    $Ambience.stop()
```

---

## Hintergrundfarbe / Atmosphäre einstellen

In `team_a.tscn`: **WorldEnvironment** anklicken → im Inspector auf **Environment** klicken.

- **Background → Mode**: `Color` → Farbe wählen
- **Ambient Light → Source**: `Color` → ähnliche Farbe, leicht heller
- **Ambient Light → Energy**: `0.3` – `0.6`

> Dunkle, gesättigte Farben wirken in VR atmosphärischer als helle.

---

## ★ Fortgeschritten: Trigger-Zonen (optional)

Trigger reagieren wenn ein anderer Spieler in eine Zone tritt — z. B. Sound an/aus, Licht wechseln.

1. Im FileSystem: `triggers/interaction_zone.tscn` → Rechtsklick → **Duplicate**
   → Zielordner: `_scenes/team_a/` → Name: z. B. `mein_trigger.tscn`
2. `triggers/interaction_zone.gd` ebenfalls duplizieren → `_scenes/team_a/mein_trigger.gd`
3. `mein_trigger.tscn` öffnen → Script-Feld auf `mein_trigger.gd` umstellen
4. In `mein_trigger.gd` anpassen:

```gdscript
func _on_avatar_entered(avatar: Node3D) -> void:
    $Ambience.play()

func _on_avatar_exited(avatar: Node3D) -> void:
    $Ambience.stop()
```

5. Trigger-Instanz in eure Szene einbauen → im 3D-Viewport positionieren

---

## Euren Stand hochladen

### ⭐ Bevorzugt: Git mit GitHub Desktop

**Was ihr braucht:**
1. **GitHub-Account erstellen** (kostenlos): [github.com/join](https://github.com/join)
2. Pablo schickt euch eine Einladungs-E-Mail → Link anklicken und annehmen
3. **GitHub Desktop herunterladen**: [desktop.github.com](https://desktop.github.com)

**Einmalige Einrichtung:**
1. GitHub Desktop → **Sign in to GitHub.com**
2. **File → Clone Repository** → „Hyper-Irrealismus-III" suchen → **Clone**
3. Lokalen Zielordner wählen → `project.godot` in Godot öffnen

**Täglicher Workflow:**
1. GitHub Desktop → **Fetch origin** (immer zuerst — neusten Stand holen)
2. Dateien in `_scenes/team_a/` bearbeiten
3. In GitHub Desktop: eure geänderten Dateien erscheinen links
4. Nur Dateien in `_scenes/team_a/` abhaken
5. Kurze Notiz schreiben → **Commit to main** → **Push origin**

> Nur euren eigenen Ordner committen. Template-Core-Dateien nicht anfassen.

---

### Fallback: ZIP-Abgabe

Euren Ordner `_scenes/team_a/` als ZIP packen und an Pablo schicken.
Die `scene_info.cfg` muss in der ZIP enthalten sein.

---

## Abgabe-Checkliste

- [ ] `scene_info.cfg` ausgefüllt (name, duration, scene_file, team)
- [ ] Szene läuft mit F6 ohne Fehler
- [ ] 3D-Assets und Sounds sind im Team-Ordner (nicht in einem anderen Ordner)
- [ ] Stand via Git gepusht oder ZIP abgegeben
