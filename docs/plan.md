# Situs Core: Plan und TODO

Stand 2026-10-30. Version im Repo: 1.1.0 (noch nicht getaggt).

**Meilenstein 2026-10-30:** In Spatial_Insights läuft Situs Core auf den Brillen im Netzwerk. Ein Server verteilt MATLAB-Daten, die Brille verbindet sich über die konfigurierte Server-IP und sieht die zweite Brille.

## Stand

- Repo extrahiert aus Hyper-Irrealismus III (gefilterte Historie), Godot 4.7, nur GL Compatibility.
- Plugin `addons/situs_core/` über Branch `dist` per git subtree einbindbar.
- Optionales Modul `modul_scene_loop`. Ohne Module läuft eine Szene (`situs_core/default_scene`).
- Einstellungen in den Project Settings: Server-IP, Raumbreite und -länge, Rotation (am XR-Ursprung).
- Setup-Skript und Anleitung: `tools/setup_android.ps1`, `docs/INSTALL.md`.
- Erster echter Einsatz: Spatial Insights (Repo `Spatial_Insights`, ehemals MatLab_CommTest, `main`). Dort ist ein Datenkanal-Modul entstanden, das später hierher wandert.

**Auf Hardware bestätigt:** Verbindung Brille ↔ Server über die Server-IP aus den Project Settings, Avatare, Datenverteilung (im CommTest-Projekt).

**Noch nicht geprüft:** Rotationsvorzeichen, Android-Override der Server-IP, Betrieb mit 4 und 8 Brillen, das Setup-Skript im Situs-Repo (nur Syntax geprüft, das CommTest-Original lief).

## TODO-Liste

### Nach den Tests in Spatial_Insights

Siehe `Spatial_Insights/docs/plan.md`. Davon hängen hier ab:

- [x] Test mit 2 Brillen im Netzwerk bestanden (2026-10-30).
- [ ] Multiplayer-Test mit 4 und 8 Brillen bestanden.
- [ ] Rotationsvorzeichen und Android-Override bestätigt, Texte in `README.md` angepasst.
- [ ] Tags `v1.0.0` und `v1.1.0` setzen, `dist` neu bauen (`git subtree split --prefix=addons/situs_core -b dist`, danach pushen).
- [ ] Uncommittete Änderung an `project.godot` klären (committen oder verwerfen).

### Setup und Dokumentation

- [ ] `tools/setup_android.ps1` auf einem frischen Rechner komplett durchlaufen lassen.
- [ ] Das Skript nur an einer Stelle pflegen. Aktuell gibt es Kopien in Situs und in Spatial_Insights. Idee: Kopie im Plugin, Projekte rufen sie auf.
- [ ] Neue, kurze Architekturbeschreibung für Situs schreiben (Autoloads, Netzwerk, Szenen-Hooks, Settings, Module). Die alten HI-III-Anleitungen sind entfernt.

### Neue Module und Funktionen

- [ ] `modul_data_channel` aus Spatial_Insights übernehmen: Ordner nach `addons/situs_core/modules/`, Eintrag in `MODULE_AUTOLOADS` in `plugin.gd`, README ergänzen.
- [ ] Jitter-Puffer im Datenkanal (Serverzeit liegt im Frame).
- [ ] Einstellungen anderer Module im Editor registrieren (z. B. `sim/udp_port`, `sim/udp_on_clients`).
- [ ] Weitere Module (Liste im README ergänzen).

### Hardware

- [ ] **Server automatisch im LAN finden** statt fester Server-IP (Server ist immer ein PC). Das soll der Standard sein, die feste IP bleibt als Option in den Project Settings. Ansatz: Server antwortet auf einen UDP-Broadcast der Clients, ersatzweise periodischer Broadcast des Servers. Auf der Brille und im WLAN testen (Broadcast kann vom Access Point geblockt werden).
- [ ] Pico 4 Ultimate: Export-Preset und Plugin-Support (Vendors-Plugin).
- [ ] Marker-Ausrichtung der Brillen (`docs/plan_marker_ausrichtung.md`).

### Migration

- [ ] Hyper-Irrealismus III auf Situs umstellen (Plan: `docs/HI3_MIGRATION_PLAN.md`). Bewusst zurückgestellt, HI-III bleibt bis dahin unverändert.


### Avatar (Cone-Avatar, Paket für sich)

Stand: Die Kopfrotation (`head_rot`) wird schon an alle Clients übertragen, der Kopf ist aber eine Kugel und zeigt die Blickrichtung nicht.

- [x] Kopf bleibt eine Kugel (abstrahierter Kopf), davor sitzt ein Würfel als Brille (HMD), damit man die Blickrichtung sieht. Rotation kommt aus `head_rot` (`avatar_dynamic_cone.gd`). Auf der Brille noch zu sichten.
- [x] Controller sehen und übertragen: zwei kleine längliche Quader (15 cm lang, 4 cm breit und tief). `send_player_state` überträgt zwei Controller-Posen plus Tracking-Maske, Avatare mit `update_hands()` zeigen sie. Auf der Brille noch zu sichten. Achtung: Die RPC-Signatur hat sich geändert, alle Geräte brauchen denselben Stand.
- [x] Schleppe nach dem Vorbild von Spatial Encounters: ein träger Bodenpunkt folgt dem Kopf, die Ringe liegen gleichmäßig dazwischen (`trail_mode = LINEAR`, zeitbasiert). Dazu flache unbeleuchtete Bänder und Farbverlauf (unten dunkler), beides im Inspektor abschaltbar (`flat_rings`, `color_gradient`).
- [ ] **Prüfen auf der Brille:** Sieht LINEAR besser aus als DAMPED? Wenn ja, den gedämpften Modus (`TrailMode.DAMPED`, `damping_*`) komplett entfernen.
- [x] Sprung-Effekt: Hocke, dann Hochspringen (Erkennung in `xr_player.gd`, Werte `jump_crouch_drop` und `jump_speed`). Der Avatar fliegt nach oben und wächst, an der echten Position bleibt ein durchsichtiger Geist. Abschaltbar über Project Settings *Situs Core → Avatar → Jump Enabled* und `jump_enabled` am Avatar. Erster Test: Hocke und Sprung lösten nicht aus, daraufhin die Erkennung überarbeitet (relative Standhöhe, Geschwindigkeit über 0.2 s, pro Bild). Mit `jump_debug` (Log: `[Sprung] …`) die Schwellen auf der Brille justieren, danach `jump_debug` ausschalten.
- [ ] Explodierender Ring als Effekt (aus Spatial Encounters, `explodingRing.js`): ein Ring dehnt sich aus und verblasst, z. B. beim Beitritt oder Sprung.
- Quelle und Lizenz der Vorlage: `docs/THIRD_PARTY.md`.

### Neue Module (werden in Spatial_Insights integriert)

Beide sind eigene Module unter `addons/situs_core/modules/` und brauchen Controller-Posen aus dem Avatar-Paket. Ansätze existieren in anderen Projekten.

- [ ] **Objekte greifen, skalieren, rotieren, repositionieren** (zuerst die Simulationskörper aus Spatial_Insights). Zustand muss für alle Brillen synchron sein.
- [ ] **Kollaboratives Sketching:** gemeinsam im Raum zeichnen, Striche an alle Brillen verteilen, Late Join.

### Branches

- `main`: Entwicklung.
- `dist`: wird aus `addons/situs_core/` mit `git subtree split` erzeugt und kann nicht in `main` gemergt werden. Projekte ziehen daraus per subtree.