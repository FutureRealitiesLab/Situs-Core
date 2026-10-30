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

**Auf Hardware bestätigt:** Verbindung Brille ↔ Server über die Server-IP aus den Project Settings, Avatare, Datenverteilung (in Spatial Insights), Controller als Quader in Spielerfarbe, lineare Schleppe, Körpersprung (Hocke, Hochspringen).

**Noch nicht geprüft:** Rotationsvorzeichen, Android-Override der Server-IP, Betrieb mit 4 und 8 Brillen, das Setup-Skript im Situs-Repo (nur Syntax geprüft, das Original aus Spatial Insights lief), Sprungtaste B (Tastenname), Gefühl des überarbeiteten Boost-Sprungs.

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

Stand 2026-10-30: Kopfkugel mit Brillen-Würfel, Controller als Quader in Spielerfarbe (nur sichtbar, wenn aktiv getrackt, blitzen bei Tastendruck weiß auf), lineare Schleppe mit trägem Bodenpunkt, flache unbeleuchtete Ringe mit Farbverlauf, Boost-Sprung. Controller-Farbe und Schleppe auf der Brille bestätigt. Der gedämpfte Schleppen-Modus ist entfernt.

- [x] Kopf bleibt eine Kugel (abstrahierter Kopf), davor sitzt ein Würfel als Brille (HMD), damit man die Blickrichtung sieht (`avatar_dynamic_cone.gd`).
- [x] Controller als Quader (15 × 4 × 4 cm) in Spielerfarbe, übertragen über `send_player_state` (zwei Posen plus Tracking-Maske), nur sichtbar wenn aktiv getrackt. Auf der Brille bestätigt. Die RPC-Signatur hat sich geändert, alle Geräte brauchen denselben Stand.
- [x] Schleppe nach dem Vorbild von Spatial Encounters (`lazy_follow_rate` 1.0), flache Bänder (`flat_rings`), Farbverlauf (`color_gradient`). Auf der Brille bestätigt, gedämpfter Modus entfernt.
- [x] Controller-Quader blitzt bei Tastendruck weiß auf (Kontrolle, nur lokal).
- [x] **Boost-Sprung umgesetzt** (`xr_player.gd`, `start_boost()`): Auslöser Sprungtaste (Standard B, nur rechter Controller, einstellbar) oder Hocke und Hochspringen. Eigene Sicht: Aufstieg wie ein Wurf (1,2 s, Energie läuft nach oben aus) auf 4 m, danach langsames Herabsinken (6,8 s, zusammen rund 8 s Flug), in der Luft gesperrt. Andere sehen die Person hochspringen: der unterste Ring bleibt am echten Boden (Kollisionsschutz), die Ringe sind bis zum Kopf gestaffelt, mit der Höhe kommen Ringe dazu. Gilt auch für den eigenen Körper beim Hinunterschauen. Einstellungen: Project Settings *Situs Core → Jump* (Ein/Aus, Höhe, Aufstieg, Gleiten, Taste, Tastennamen anzeigen).
- [ ] **Test nächste Session (Boost-Sprung):**
  - Körpersprung (Hocke, Hochspringen) löst aus (bestätigt, Gefühl der Bewegung wurde überarbeitet: prüfen, ob Aufstieg und Sinken jetzt realistisch wirken, ggf. Höhe, Aufstieg und Gleiten in den Settings nachstellen).
  - Sprungtaste B löst **nicht** aus, obwohl die Taste erkannt wird (Controller blitzt). Vermutlich kommt die Taste mit einem anderen Namen an. Beim Drücken zeigt ein Hinweis im Blickfeld den Namen (Setting *Show Button Names*), diesen unter *Situs Core → Jump → Button* eintragen.
  - Die Flugzeit „… sek" in der Anforderung war abgeschnitten, 8 s sind angenommen: Gefühl prüfen.
  - Andere Brille: Stauchung der Ringsäule bei 4 m Höhe und der Ringanzahl (`max_ring_spacing`, `max_rings`) beurteilen.
  - Fallbacks für die Körpererkennung: `docs/JUMP_FALLBACKS.md`.
- [ ] Explodierender Ring als Effekt (aus Spatial Encounters, `explodingRing.js`): ein Ring dehnt sich aus und verblasst, z. B. beim Beitritt oder Sprung.
- Quelle und Lizenz der Vorlage: `docs/THIRD_PARTY.md`.

### Neue Module (werden in Spatial_Insights integriert)

Beide sind eigene Module unter `addons/situs_core/modules/` und brauchen Controller-Posen aus dem Avatar-Paket. Ansätze existieren in anderen Projekten.

- [ ] **Objekte greifen, skalieren, rotieren, repositionieren** (zuerst die Simulationskörper aus Spatial_Insights). Zustand muss für alle Brillen synchron sein.
- [ ] **Kollaboratives Sketching:** gemeinsam im Raum zeichnen, Striche an alle Brillen verteilen, Late Join.

### Branches

- `main`: Entwicklung.
- `dist`: wird aus `addons/situs_core/` mit `git subtree split` erzeugt und kann nicht in `main` gemergt werden. Projekte ziehen daraus per subtree.