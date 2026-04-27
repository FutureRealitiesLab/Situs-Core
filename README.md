# Hyper-Irrealismus III

Multiplayer VR exhibition template. Up to 8 XR clients (Meta Quest 2/3/Pro, HTC Focus 3) + desktop server, connected over LAN via ENet UDP.

Built with **Godot 4.6** — GL Compatibility renderer, OpenXR.

---

## Dokumentation

| Dokument | Für wen |
|----------|---------|
| [BETRIEB_UND_WORKFLOW.md](BETRIEB_UND_WORKFLOW.md) | Design-Teams, Pablo (Developer), Cassiopeia (Operator) |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Developer — vollständige technische Referenz (Dateien, Module, Einstellungen, Changelog) |

---

## Schnellstart

**Lokal testen (PC, kein Headset):**
```
1. project.godot in Godot 4.6 öffnen
2. F5 → Startmenü → "Als Server starten"
3. Zweite Instanz: Debug → Run Multiple Instances → "Als Spieler starten (First Person)"
```

**Server-IP konfigurieren** (vor APK-Build):
```
server_ip.txt  →  IP des Server-PCs eintragen, z. B.  192.168.1.100
```
`network_manager.gd` **nicht** anfassen — die IP wird automatisch aus `server_ip.txt` geladen.

**APK bauen:**
```
Project → Export → "Android – Meta Quest"   → Hyper-Irrealismus-III-Quest.apk
Project → Export → "Android – HTC Focus 3"  → Hyper-Irrealismus-III-Focus3.apk
```
Export-Presets einrichten: `export_presets.cfg.template` als `export_presets.cfg` kopieren (gitignored, lokal).

---

## Für Design-Teams

Ihr arbeitet ausschließlich in `scenes/team_X/` und tragt euren Eintrag in `scenes/scene_registry.gd` ein.
Alle anderen Dateien sind mit `# TEMPLATE CORE – nicht verändern` markiert.

→ Vollständige Anleitung: [BETRIEB_UND_WORKFLOW.md → Abschnitt 1](BETRIEB_UND_WORKFLOW.md)
