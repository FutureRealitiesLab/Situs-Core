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

Design Teams bekommen **Git-Zugang** — Einladung via GitHub.

1. GitHub-Repo → **Settings → Collaborators → Add people**
   → Jedes Team per GitHub-Username oder E-Mail einladen (Write-Zugriff)
2. Jedes Team bekommt eine Einladungs-E-Mail von GitHub
3. Repo-Link + `_anleitungen/design_teams.md` an Teams schicken

Teams arbeiten ausschließlich in `_scenes/team_X/` — ihre `scene_info.cfg` liegt darin.

> **Ruleset aktiv:** Write-Zugang erlaubt kein direktes Pushen auf master.
> Teams pushen auf ihren Branch (`team-a`, `team-b`, …) — du mergst (→ Abschnitt B).

---

## B) Abgegebene Team-Szenen integrieren

### Schritt 1 — Branch prüfen und mergen

1. GitHub → **Branches** → Branch des Teams anklicken (z. B. `team-a`)
2. GitHub zeigt: *„This branch is X commits ahead of master"* → **„Compare & pull request"** klicken
3. Im Diff prüfen: sind **ausschließlich** Dateien in `_scenes/team_X/` geändert?
   - Ja → **Merge pull request**
   - Nein → nicht mergen, Team kontaktieren und Korrektur anfordern
4. Lokal: `git pull` → Godot reimportiert automatisch beim nächsten Öffnen

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
  → Export Project → _apks/Hyper-Irrealismus-III-Quest.apk

Preset „Android – HTC Focus 3":
  → Export Project → _apks/Hyper-Irrealismus-III-Focus3.apk
```

### Installation

**Meta Quest (2 / 3 / Pro):**
```bash
adb install -r _apks/Hyper-Irrealismus-III-Quest.apk
# oder per SideQuest (Drag & Drop)
```
Auf dem Headset: **Apps → Alle Apps → „Unbekannte Quellen"**

**HTC Focus 3:**
```bash
adb devices                                         # Headset per USB verbinden
adb install -r _apks/Hyper-Irrealismus-III-Focus3.apk
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
- [ ] Quest-APK auf alle Meta Quest Headsets installiert (`_apks/Hyper-Irrealismus-III-Quest.apk`)
- [ ] Focus3-APK auf alle HTC Focus 3 Headsets installiert (`_apks/Hyper-Irrealismus-III-Focus3.apk`)
- [ ] `hyper3_server.exe` + `start_server.bat` auf Server-PC Desktop
- [ ] Headsets voll geladen
- [ ] Venue Team eingewiesen (→ `_anleitungen/venue_team.md`)

---

## Technische Referenz

→ [`ARCHITECTURE.md`](ARCHITECTURE.md) — vollständige Dokumentation aller Module, Einstellungen und Changelog
