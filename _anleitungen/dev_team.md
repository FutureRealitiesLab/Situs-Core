# Hyper-Irrealismus III — Anleitung für das Dev Team

---

## Übersicht

```
Aufgaben:
  A) Projekt an Design Teams weitergeben
  B) Abgegebene Team-Szenen integrieren
  C) Server-IP konfigurieren
  D) APKs bauen und auf Headsets installieren
  E) Server-Executable vorbereiten
```

---

## A) Projekt an Design Teams weitergeben

Design Teams bekommen **Git-Zugang** (bevorzugt) oder eine **ZIP des Projekts**.

### Git (bevorzugt)

1. GitHub-Repo → **Settings → Collaborators → Add people**
   → Jedes Team per GitHub-Username oder E-Mail einladen (Write-Zugriff)
2. Jedes Team bekommt eine Einladungs-E-Mail von GitHub
3. Repo-Link an Teams schicken

Teams pushen nur in `_scenes/team_X/` und `_scenes/scene_info.cfg` — kein Merge-Konflikt möglich.

### ZIP (Fallback)

1. Projektordner kopieren → `.godot/` Ordner löschen (Cache, ~200 MB)
2. In `_scenes/scene_registry.gd`: Platzhalter-Einträge stehen lassen
3. Als `hyper3_projekt.zip` verpacken → alle Teams bekommen dieselbe ZIP

---

## B) Abgegebene Team-Szenen integrieren

Für jede Abgabe (Git-Push oder ZIP):

### Schritt 1 — Team-Ordner einpflegen (ZIP-Weg)

```
[entpackte Abgabe]/team_a/  →  [Projekt]/_scenes/team_a/
```

Godot reimportiert automatisch.

### Schritt 2 — scene_registry.gd aktualisieren

`_scenes/scene_registry.gd` öffnen → Ordnerpfad eintragen:

```gdscript
func get_scenes() -> Array:
    return [
        "res://_scenes/team_a/",
        "res://_scenes/team_b/",
        # ...
    ]
```

Die **Reihenfolge** = Ausstellungsreihenfolge. Platzhalter entfernen sobald echte Szenen vorhanden.

### Schritt 3 — Testen

```
F5 → „Als Server starten"
Zweite Instanz → „Als Spieler starten (First Person)"
N-Taste → alle Szenen durchklicken
```

Checkliste pro Team-Szene:
- [ ] Lädt ohne Fehlermeldung
- [ ] Assets (Meshes, Sounds) sichtbar/hörbar
- [ ] Szenenwechsel funktioniert
- [ ] Remote-Avatar erscheint korrekt

---

## C) Server-IP konfigurieren

**Muss vor dem APK-Build passieren — die IP wird in die APK eingebacken.**

```
server_ip.txt  →  IP des Server-PCs eintragen, z. B.:  192.168.1.100
```

IP des Server-PCs herausfinden (auf dem Server-PC):
```
Win+R → cmd → ipconfig → „IPv4-Adresse" unter dem LAN/WLAN-Adapter ablesen
```

> `network_manager.gd` nicht anfassen — liest `server_ip.txt` automatisch ein.

---

## D) APKs für Headsets bauen

Es gibt **zwei separate APKs** (Quest und Focus 3 haben unterschiedliche Plugins).

### Einmalige Vorbereitung
- Android SDK installiert und in Godot verknüpft
- Export-Templates installiert: **Editor → Manage Export Templates**
- `export_presets.cfg` aus Template kopieren (einmalig):
  ```powershell
  Copy-Item export_presets.cfg.template export_presets.cfg
  ```
- APK-Signing-Keystore eintragen

### Export

```
Godot → Project → Export

Preset „Android – Meta Quest":
  → Export Project → Hyper-Irrealismus-III-Quest.apk

Preset „Android – HTC Focus 3":
  → Export Project → Hyper-Irrealismus-III-Focus3.apk
```

### Installation

**Meta Quest (2 / 3 / Pro):**
```bash
adb install -r Hyper-Irrealismus-III-Quest.apk
# oder per SideQuest (Drag & Drop)
```
Auf dem Headset: **Apps → Alle Apps → „Unbekannte Quellen"**

**HTC Focus 3:**
```bash
adb devices                                         # Headset per USB verbinden
adb install -r Hyper-Irrealismus-III-Focus3.apk
```
Auf dem Headset: **Apps → Alle Apps → „Unbekannte Quellen"**

> Für mehrere Headsets: jedes einzeln per USB — richtigen APK-Typ verwenden.

---

## E) Server-Executable vorbereiten

```
Godot → Project → Export → Windows Desktop
→ Export Project → hyper3_server.exe
```

Startscript auf dem Server-PC (`start_server.bat`):
```batch
@echo off
hyper3_server.exe
```

> Ohne `--headless` erscheint das Startmenü — Venue Team klickt „Als Server starten".
> Einfacher als headless für den Ausstellungsbetrieb.

---

## Checkliste vor der Ausstellung

- [ ] `server_ip.txt` auf Ausstellungs-IP gesetzt (nicht `127.0.0.1`!)
- [ ] Alle Team-Szenen in `_scenes/scene_registry.gd` eingetragen, Platzhalter entfernt
- [ ] Reihenfolge in `scene_registry.gd` korrekt, `duration` mit Teams abgestimmt
- [ ] Alle Szenen einzeln getestet (kein Importfehler, Sounds hörbar)
- [ ] Quest-APK auf alle Meta Quest Headsets installiert (`Hyper-Irrealismus-III-Quest.apk`)
- [ ] Focus3-APK auf alle HTC Focus 3 Headsets installiert (`Hyper-Irrealismus-III-Focus3.apk`)
- [ ] `hyper3_server.exe` + `start_server.bat` auf Server-PC Desktop
- [ ] Headsets voll geladen
- [ ] Venue Team eingewiesen (→ `_anleitungen/venue_team.md`)

---

## Technische Referenz

→ [`ARCHITECTURE.md`](ARCHITECTURE.md) — vollständige Dokumentation aller Module, Einstellungen und Changelog
