# Plan: Marker-basierte Ausrichtung (VO + MBL) für Hyper-Irrealismus-III

| | |
|---|---|
| Stand | 2026-10-22 |
| Status | Planung. Es wurde kein Code geändert. |
| Geltungsbereich | Nur dieses Repo (Hyper-Irrealismus-III). Das MatLab-Projekt kommt später und kann den Alignment-Teil danach übernehmen. |
| Kurzname | Marker-Ausrichtung |

Sicherheitsgrade in diesem Dokument: **CONFIRMED** (in einer Primärquelle gesehen), **LIKELY** (plausibel, nicht direkt belegt), **UNCERTAIN** (nicht gefunden oder nur am Gerät klärbar).

---

## 1. Ziel und Randbedingungen

Statt pro Brille einen LBE-Scan zu erstellen, soll ein ArUco-Marker auf dem Boden genügen. Die Brillen finden ihn zur Laufzeit und richten die Szene daran aus. Alternativ, wenn kein Marker-Zugriff möglich ist, genügt eine Low-Tech-Variante mit zwei Klebekreuzen.

- Immer Standalone Android (Vive Focus Vision, Focus 3, Quest). Keine PC-VR-Lösung.
- **Dieselbe APK für beide Modi:** LBE (Scan vorhanden, Ursprung wie heute) und Marker bzw. Kreuze (schnell, ohne Scan).
- Godot-OpenXR-App (Khronos-Vendors-Flavor), keine Wave-SDK-App.

## 2. Kurzfazit

Das Ziel ist umsetzbar, aber nicht auf dem Weg, den die Gemini-Skizze beschreibt. Ob der Marker-Weg über OpenXR auf der Focus Vision überhaupt offen ist, entscheidet nur ein Test am Gerät. Dafür ist **keine Migration auf Godot 4.7 nötig**. Die ausrichtende Logik (Alignment-Kern) ist für alle Wege identisch und kann vorab gebaut werden. Der Zwei-Kreuze-Weg (C) braucht weder Kamera noch LBSS und funktioniert auf jeder Brille. Seine Kalibrierung gilt aber nur pro Sitzung: Nach Standby, App-Neustart oder Recenter ist vermutlich eine neue nötig (Abschnitt 8).

| Weg | Idee | Aufwand | Stand |
|---|---|---|---|
| **A** | Khronos-Erweiterung `XR_EXT_spatial_marker_tracking` über Godot (`OpenXRSpatialMarkerTrackingCapability`), reines GDScript | klein | Belege für die VIVE-Runtime fehlen. Gerätetest entscheidet |
| **B1** | LBSS-Parameter über Wave-Native (`WVR_GetParameters/SetParameters`), HTC richtet den Ursprung aus | hoch | Nur für Wave-Apps dokumentiert. Braucht Business+/LBSS. Liefert keine Pose zurück |
| **B2** | Wave-Marker-API (`wvr/wvr_marker.h`), Ausrichtung in der App | hoch | Beta, nur Wave. Aus einem OpenXR-Prozess ungeklärt |
| **C** | Zwei-Kreuze-Kalibrierung mit den Controllern (Low-Tech) | klein | Eigener Vorschlag. Geräteunabhängig. Genauigkeit am Gerät messen |
| **D** | `XR_HTC_anchor`, persistente Anker exportieren und importieren | hoch | Nur Focus Vision/XR Elite. Kein Godot-Wrapper gefunden |
| **S** | LBSS-Systemfunktionen (`markers_list.json`, Drift Prevention, Advanced Relocation) | klein (Konfiguration) | Für reine OpenXR-Apps ungeklärt. Braucht Business+ |
| E | Eigener Kamera-Detektor (OpenCV) | sehr hoch | Wahrscheinlich gesperrt: HTC gibt keine Rohbilder frei |

## 3. Was HTC tatsächlich dokumentiert

- **Visual-Odometry-Modus (VO):** Ein System-Tracking-Modus der Headsets (LBSS über VIVE Business+), kein App-Schalter. 6DoF startet sofort nach dem Aufsetzen. Blickrichtung und Ursprung kommen aus der aktuellen Ausrichtung, es wird keine Karte gespeichert. CONFIRMED.
- **Marker-Based Location Sharing (MBLS):** Ein oder zwei ArUco-Marker, in Räumen bis 150 m². Zwei Marker erhöhen die Genauigkeit, kosten aber Latenz. Es braucht keinen LBE-Scan und kein Map-Sharing, weil es auf VO aufbaut. Eine maximale Brillenzahl nennt die Seite nicht. CONFIRMED.
- **Unterstützte Brillen laut Requirements-Seite:** Focus Vision, Focus 3, XR Elite. Dazu VIVE Business+ (Einschreiben, Konfigurationspakete) und VIVE Manager. Marker erzeugt der "VIVE ArUco Marker Generator". CONFIRMED.
- **API für Standalone-Brillen (AIO):** Gilt laut HTC nur für "AIO VR apps built with the VIVE Wave VR SDK". Sie besteht aus String-Schlüsseln an `WVR_GetParameters` (Get) und `WVR_SetParameters` (Set) auf dem HMD. CONFIRMED.

| Schritt | Schlüssel | Aufruf | Zweck |
|---|---|---|---|
| Marker konfigurieren | `PLAYER00InitMA` + JSON | Get | Rückgabe `InitErr` bei Fehler |
| Recenter löschen | `ClearRecenterXform` | Set | vor dem Scan |
| Scan starten | `PLAYER00StartScan` | Get | Marker-Erkennung |
| Status | `PLAYER00CheckMA` | Get | höchstens 2 Mal pro Sekunde. `CTdone` = alle gescannt, `CTpass` = erster von zwei Markern gescannt |
| Scan beenden | `PLAYER00StopScan` | Get | setzt die Kopfposition zurück |

  - JSON für einen Marker: `{"marker1": {"id": 66, "behavior": 3, "size": 0.280}}` (Größe in Metern). Bei zwei Markern kommen `isMainMarker` und `pairMarkerID` dazu, und die Ausrichtung startet erst nach dem zweiten Scan.
  - Nach App-Neustart: `PLAYER00CheckMA` pollen. Bei `CTdone` einmal `ClearRecenterXform` aufrufen, dann stellt die Brille die Position aus den letzten Daten wieder her.
  - **Es gibt keinen Aufruf, der die Marker-Pose an die App zurückgibt.** Die Ausrichtung passiert intern im Tracking.
  - Nicht dokumentiert: Permissions, SDK-Versionen, OpenXR-Einbindung.
- **Wave-Marker-API (B2):** Header `wvr/wvr_marker.h` mit `WVR_StartMarker`, `WVR_StartMarkerDetection`, `WVR_GetArucoMarkers`, `WVR_GetArucoMarkerData`, `WVR_*TrackableMarker*` u. a. Manifest-Eintrag `<uses-feature android:name="wave.feature.marker" android:required="true" />`, vorher `WVR_GetSupportedFeatures` prüfen. Laut Doku Beta, ArUco 4x4 mit 100 IDs, Größe in cm. Die Funktionsseiten (Signaturen, Pose) wurden nicht gelesen. CONFIRMED / UNCERTAIN.
- **"OpenXR Space Calibrator"** hat nichts mit Markern zu tun. Er richtet das Headset-Tracking an einem VIVE Tracker über ein SteamVR-Overlay aus (PC). CONFIRMED.
- **Kamerazugriff:** HTC lehnt rohe Kamerabilder aus Datenschutzgründen ab (Aussagen 2021/2022 zur Focus 3, nur Passthrough Underlay/Overlay). Für Focus Vision keine neuere Aussage gefunden, deshalb LIKELY dieselbe Richtlinie. Firmware 7.0.999.344 brachte eine Enterprise-"Camera calibration API", aber das ist Kartenkalibrierung, kein Bildzugriff. CONFIRMED / LIKELY.

### Korrekturen an der Gemini-Skizze

- Die Java-Klasse `com.htc.vr.sdk.WVR_Marker` existiert in der Doku nicht. Wave ist eine C-API. Der Manifest-Eintrag `wave.feature.marker` ist dagegen echt.
- `startMarkerTracking()` ruft nichts auf und gibt immer `true` zurück.
- `.gdap` ist das alte Plugin-Format. Godot 4 nutzt Android-Plugin v2 (AAR mit Manifest-Metadaten).
- "Die Koordinaten gleichen sich automatisch an" stimmt nur, wenn das HTC-System ausrichtet (B1). Das ist ein anderer Weg als ein App-seitiger Marker-Zugriff.

## 4. Recherche zu Weg A (OpenXR-Marker auf Focus Vision)

- Es gibt **keinen Beleg**, dass die VIVE-OpenXR-Runtime `XR_EXT_spatial_entity` oder `XR_EXT_spatial_marker_tracking` anbietet: weder im Khronos-Extension-Inventar (HTC listet nur Focus 3, 18 Erweiterungen, keine `XR_EXT_spatial_*`) noch in den VIVE-OpenXR-2.5.1-Release-Notes noch in den Focus-Vision-Firmware-Notes bis 7.0.999.389 (27.8.2026). CONFIRMED als Fehlen von Belegen, nicht als Beweis des Gegenteils.
- HTC-Forum, 7.10.2024: Marker über OpenXR sei "under roadmap planning", Ziel Ende 2024. Keine Folgeaussage gefunden. CONFIRMED.
- Laut Khronos-Inventar unterstützen Marker-Tracking: Android XR, Quest 3, Quest 3S. Auf Quest 3 laut einem Forenbericht eventuell nur QR statt ArUco (LIKELY). Pico 4 Ultra: Spatial Entity, Anker und Plane, aber kein Marker.
- Eine HTC-Marker-Extension gibt es im OpenXR-Registry nicht. HTC-Marker laufen nur über das Wave-SDK.
- UNCERTAIN: Die Gerätefirmware kann Erweiterungen anbieten, die in keinen Release Notes stehen. Nur ein Test am Gerät entscheidet.
- **Godot:** Spatial Entities samt Marker-Tracking sind seit **Godot 4.6** dabei (PR 107391, gemergt am 28.9.2025). Das Projekt ist auf 4.6.1, **die Probe geht also ohne Migration**. In 4.7 wurde die API für GDScript/GDExtension umgebaut (PR 118128), die Klasse bleibt Experimental.
- **Project Settings (4.6):** `xr/openxr/extensions/spatial_entity/enabled`, `.../enable_marker_tracking`, `.../enable_builtin_marker_tracking`, `.../aruco_dict` (Default 7x7_1000, muss zum Druck passen). Prüffunktionen: `is_aruco_supported()`, `is_qrcode_supported()`, `is_april_tag_supported()`. Die Erweiterungen werden optional angefordert: Fehlen sie, startet die App trotzdem.
- **Export-Permissions für HTC:** nicht dokumentiert. Das Vendors-Plugin setzt für Khronos/HTC keine Spatial-Permissions (für Meta, Pico und Android XR schon).
- **Weitere HTC-OpenXR-Erweiterungen:** `XR_HTC_anchor` (nur Focus Vision/XR Elite, ab VIVE-OpenXR-Plugin 2.5.0 und ROM 7.0.999.228, persistent und zwischen Geräten exportierbar, keine Marker), `XR_EXT_plane_detection` (Wände aus dem MR-Room-Setup), `XR_HTC_passthrough` (nur Rendering). `XR_MSFT_scene_understanding` gibt es auf den Standalone-Brillen nicht.

## 5. Godot-4.7.x-Migration

- **4.7.2 ist real.** 4.7 erschien am 18.6.2026, 4.7.1 am 14.7., **4.7.2 am 18.8.2026** (aktuell stabil). 4.8 ist in beta1 (15.10.2026), ohne Stable-Termin. 4.6.3 (20.5.2026) war der letzte 4.6.x-Patch, weitere sind nicht angekündigt (LIKELY). CONFIRMED sonst.
- **Offizielle Migrationsseite:** "relatively safe". Für das Projekt relevant:
  - **GDScript:** überschreibende Methoden mit geerbtem Rückgabetyp brauchen ein explizites `return` (z. B. `return null`). Packed-Array-Setter-Änderung. 36 `.gd`-Dateien im Projekt.
  - **XR/OpenXR:** nur zwei Randänderungen (`_on_register_metadata`, `create_new_anchor`), die das Projekt nicht nutzt. Reference Space und Foveation unverändert.
  - **Android:** compile/targetSdk 36 (vorher 35), NDK 29, build-tools 36.1.0. AGP 8.6.1, Gradle 8.11.1, JDK 17 unverändert. Die Doku ist an der Stelle veraltet, der Quellcode zählt.
  - **Build-Template:** Der Identifier ist die volle Version (`4.7.2.stable`), sonst bricht der Export mit "Android build version mismatch" ab. `res://android/build` muss vorher gelöscht werden. Danach `AndroidManifest.xml` (headtracking-Feature, 3 Permissions) und `gradle.properties` (`Xmx8192m`, `daemon=false`, `caching=false`) per `git diff` neu einspielen. Das 4.7-Manifest hat nur `supportsPictureInPicture` zusätzlich.
  - **Shader Baker** wird mit GL Compatibility nicht unterstützt. Das Focus-Preset hat `shader_baker/enabled=true`, auf `false` prüfen.
  - `config/features` steht auf `("4.6", "Forward Plus")`, obwohl der Renderer gl_compatibility ist. Beim Speichern wird daraus "4.7".
- **Bekannte Risiken 4.7.x (Android, XR, Compatibility):**
  - Issue 124258 (offen, Ziel 4.8): unbegrenzt wachsender Native-Speicher bei Android + Compatibility + 3D-MSAA + `scaling_3d_scale` unter 1.0. Das Projekt nutzt `msaa_3d=1` und eine XR-Render-Skalierung (0.6/0.7 in `main.gd`). Ob derselbe Pfad greift, ist UNCERTAIN. Speicher über mehr als 10 Minuten testen.
  - Issue 121992 (SSAO in VR) und 120767 (Toon-Omni-Flackern): nur relevant, falls genutzt.
  - Issue 119018 (Weißbild Compatibility-XR in 4.7-dev5) ist vor 4.7-Stable gefixt (LIKELY).
  - Vendors-Issue 484: Focus 3, Plugin 4.3, Godot 4.6.2: A/B/X/Y kommen nicht an, weil die Runtime das Oculus-Touch-Profil wählt. Passt vermutlich zum offenen Punkt `left-controller-by-button` in ARCHITECTURE.md.
- **Vendors-Plugin:** installiert ist 4.3.0 (`compatibility_minimum` 4.4). Es lädt in 4.7 vermutlich ohne Neubau (LIKELY). 4.3.1 (14.5.2026) enthält den Space-Warp-Fix für 4.7 (nur Meta). 5.1.0 (19.5.2026) verlangt Godot 4.6+ und benennt Klassen um, das trifft das Projekt nicht (keine Vendor-Klassen im Projekt). Kein Release nennt 4.7 ausdrücklich als Ziel. Focus Vision steht nirgends im Plugin-Repo, nur Focus 3 und XR Elite.
- **Meta Toolkit:** letztes Release 1.0.3 (29.7.2025), keine 4.7-Aussage (UNCERTAIN). Für Focus Vision nicht nötig. Nur im Quest-Preset aktiv. Die `.bin` fehlt lokal (gitignored).

## 6. Architektur: eine APK, beide Modi

**Kernidee:** Ein einziger Transform `world_from_tracking` auf dem `XROrigin3D` in `xr_player.gd`.

- **LBE-Modus:** Der Transform ist die Identität, genau wie heute.
- **Marker- oder Kreuze-Modus:** Er wird aus gemessenen Referenzpunkten berechnet. Es zählen nur **Position und Yaw**. Die Schwerkraft (Hochrichtung) kommt weiter aus dem Tracking, die Bodenhöhe aus dem Reference Space.
- **Netzwerk bleibt unverändert**, weil `_broadcast_position()` ([xr_player.gd:102](../SYSTEM/player/xr_player.gd)) schon Weltkoordinaten sendet. Die Avatare der anderen erscheinen automatisch am richtigen Ort.
- **Autoload `Alignment`** (z. B. `SYSTEM/alignment/alignment_manager.gd`) mit drei Modi:
  - `LBE`: Referenzen werden ignoriert.
  - `MARKER` (bzw. `KREUZE`): Anzeige "Marker suchen" bzw. "Kreuz A", sammelt etwa 30 stabile Messungen, mittelt, sperrt, blendet die Meldung aus.
  - `AUTO`: startet wie LBE und richtet nur bei bewusster Kalibrierung neu aus, mit Totzone (z. B. unter 3 cm und 1 Grad ignorieren). Sonst würde eine falsch liegende Referenz eine korrekte LBE-Ausrichtung verschlechtern.
- **Modus-Quelle:** Konfiguration (`command_line/extra_args` im Export-Preset oder Config-Datei) plus Controller-Menü.
- **Neuzentrieren** (`pose_recentered`, z. B. durch langes Drücken der Home-Taste) ändert den Tracking-Ursprung und löst eine neue Ausrichtung aus (Details zu Standby, Drift und Statusmaschine in Abschnitt 8). Die Ausrichtung wird **nicht** über App-Neustarts gespeichert, weil im VO-Modus der Ursprung bei jedem Start neu entsteht.
- **Provider-Schnittstelle:** liefert "Referenzpose(n) im Tracking-Raum". Provider: Fake (PC-Test), Controller-Zwei-Punkt (immer verfügbar), Spatial Marker (nur wenn die Probe positiv ist). B1 (Wave-LBSS) passt nicht in dieses Schema, weil es den Ursprung im System verschiebt.
- **Venue-Konfiguration** definiert die Weltposition der Referenzen: Marker-ID, Größe und Weltpose bzw. die Weltkoordinaten der beiden Kreuze.
- **Zu ändern:** Die dokumentierte Invariante "XROrigin3D strikt auf (0,0,0)" in ARCHITECTURE.md. Die Thumbstick-Locomotion ist im Multiplayer ohnehin gesperrt, der Standalone-Clamp an `XRWalkArea` bleibt unberührt.
- **Genauigkeit:** 1 Grad Yaw-Fehler sind 7 cm auf 4 m Abstand zur Referenz. Deshalb zwei Referenzen im Abstand von 4 bis 5 m (HTC empfiehlt für MBLS ebenfalls zwei Marker).

## 7. Low-Tech-Variante: Zwei-Kreuze-Kalibrierung (Weg C)

Eigener Vorschlag, nicht recherchiert. Er braucht weder Kamera noch LBSS noch Erweiterungen und läuft in derselben APK auf jeder Brille.

**Aufbau im Raum**
- Zwei Klebekreuze (Malerkrepp oder Gaffa) am Boden, **Kreuz A** (Ursprung) und **Kreuz B**, im Abstand von etwa 4 bis 5 m entlang der langen Raumachse. Das 3,5 x 6 m große `XRWalkArea` reicht dafür.
- Beschriftung "A" und "B", damit die Reihenfolge nicht verwechselt wird.
- Die Weltkoordinaten der Kreuze stehen in der Venue-Konfiguration, z. B. A bei (0, 0, 0) und B in Richtung -Z (Godot-Vorwärts) bei (0, 0, -4).

**Ablauf pro Brille (etwa 20 bis 30 Sekunden)**
1. Anzeige im Raum: "Controller-Spitze auf Kreuz A, Trigger drücken".
2. Beim Trigger werden über rund 0,5 Sekunden mehrere Positionen der Controller-Pose gesammelt und gemittelt.
3. Dasselbe für Kreuz B. Danach "Ausrichtung gesperrt".
4. Neu kalibrieren: beide Grip-Tasten 2 Sekunden halten (Kombination noch festlegen).

**Mathematik (Weg C und alle anderen Provider)**
- Messpunkte im Tracking-Raum sind die lokalen Koordinaten des Controllers relativ zum `XROrigin3D` (`origin.to_local(hand.global_position)`), nur X und Z.
- `dir_t = B_t - A_t`, `dir_w = B_w - A_w` (jeweils X/Z). Der Yaw `θ` dreht `dir_t` auf `dir_w`.
- Neuer Origin-Transform: Rotation um Y mit `θ`, Translation `t = A_w - R * A_t`. Die Höhe bleibt aus dem Reference Space (Boden).
- **Plausibilitätsprüfung:** Der Abstand `|B_t - A_t|` muss zu `|B_w - A_w|` passen. Weichen sie um mehr als einen Grenzwert (Vorschlag 3 cm) ab, wurde ein Kreuz verfehlt oder das Tracking ist ungenau: Meldung anzeigen und wiederholen.
- **Yaw-Fehler:** Ein Messfehler von 2 cm an einem Kreuz bei 4 m Basis ergibt nur etwa 0,3 Grad. Das ist deutlich besser als ein einzelner Marker.

**Varianten**
- **Startplatz (noch einfacher, ungenauer):** Jede Brille wird auf ein markiertes Fußfeld mit Blick zur Wand gesetzt und löst dort die Kalibrierung aus. Der Yaw hängt dann von der Kopfhaltung ab, vermutlich einige Grad. Nur für Demos geeignet.
- **Controller-Auflage:** Controller flach auf das Kreuz legen und Trigger drücken (weniger Wackeln als freihändig, dafür bückt man sich).

**Grenzen**
- Der Bediener muss pro Brille 20 bis 30 Sekunden investieren. Beim Marker-Weg ginge es automatisch.
- Die Genauigkeit (vermutlich 1 bis 2 cm) ist **nicht gemessen**. Der Feldtest ist Pflicht.
- Nach Tracking-Verlust oder Neuzentrieren muss neu kalibriert werden. Im VO-Modus vermutlich auch nach Standby und Aufsetzen (Abschnitt 8).

## 8. Drift, Standby und Recenter

**Kernaussage:** Die Kalibrierung ist eine Eigenschaft der laufenden Sitzung, keine dauerhafte Einstellung. Sie gilt nur, solange der Ursprung des Tracking-Raums derselbe bleibt. Recherche vom 2026-10-22. Ob die Focus Vision ihren Ursprung beim Aufwecken oder Aufsetzen im VO-Modus neu setzt, ist **nicht dokumentiert** und wird in Phase 0b am Gerät gemessen (Abschnitt 8.5).

### 8.1 Was HTC dokumentiert

- **VO-Modus:** Das 6DoF-Tracking startet "right after the user puts on their headset", Blickrichtung und Koordinatenursprung werden aus der Ausrichtung des Nutzers gesetzt, und es wird keine Karte gespeichert. Zu Standby, Wake, Recenter und Drift steht auf der Seite nichts. Ein neuer Ursprung bei jedem Aufsetzen ist deshalb LIKELY, aber nicht belegt.
- **MBLS im VO-Modus:** Bei Tracking-Verlust sollen die Marker erneut gescannt werden ("scan the ArUco markers again to reset your position"). Beim Beenden der App geht die Position verloren. HTC rechnet im VO-Modus also selbst mit einem erneuten Abgleich. CONFIRMED.
- **LBE mit Karte:** Das Headset relokalisiert sich laufend in der gespeicherten Karte. Im Hybrid-Modus bleiben die Kartendaten nach dem Standby erhalten, und eine Marker-Ausrichtung (Scene Alignment) wird beim Aufwachen angewendet. CONFIRMED. Das ist der Nutzen des Scans: Die Ausrichtung bleibt stabil.
- **Drift Prevention und Advanced Relocation** sind an LBE- oder Hybrid-Karten gebunden. Advanced Relocation gilt auf der Focus Vision ab Firmware 7.0.999.172. Dass eines von beiden einen VO-Ursprung stabilisiert, ist nirgends belegt. Eine App-API dafür wird nicht genannt (LIKELY: keine nötig). CONFIRMED / UNCERTAIN.
- **`ClearRecenterXform`** (Wave): "clears the recenter transform for the headset". Wann die Ausrichtung verloren geht, sagt die Doku nicht. Für reine OpenXR-Apps gibt es keinen Gegenpart. UNCERTAIN.
- **Energie:** Business+ bietet eine Einstellung für die Zeit bis zum Standby (Optionen nicht dokumentiert) und einen Kiosk-Modus. Power-Taste und IPD-Rad lassen sich nicht deaktivieren. Den Näherungssensor kann man laut Forenberichten weder in den Einstellungen noch in Business+ abschalten (Abkleben ist ein bekannter Hack). Ob eine Godot-App beim Absetzen pausiert, überlebt oder beendet wird, ist für die Focus Vision nicht belegt. UNCERTAIN.

### 8.2 Was die App mitbekommt (OpenXR und Godot 4.6/4.7)

- **OpenXR:** `XrEventDataReferenceSpaceChangePending` ist Pflicht bei System-Recenter (LOCAL) und bei Neudefinition des Raums (STAGE). Bei Tracking-Verlust gibt es kein Pflicht-Event, die Runtime darf Posen wieder auf den ursprünglichen Ursprung zurückschnappen lassen. Wie sich der LOCAL-Ursprung bei Relokalisierung in eine neue Karte oder beim Fortsetzen der Session verhält, regelt die Core-Spezifikation nicht. CONFIRMED / UNCERTAIN.
- **Godot ändert den `XROrigin3D` nie.** Die Alignment-Transform bleibt stehen, stimmt aber nicht mehr, wenn das Tracking darunter wegspringt. CONFIRMED (Quelltext 4.6 und 4.7.2).
- **`pose_recentered`** feuert einmal für jede Raumänderung (auch bei Boundary-Änderungen), ohne Parameter. `changeTime` und `poseValid` werden ignoriert, das Signal kann deshalb ein bis zwei Frames vor dem Sprung kommen (LIKELY). `XRInterface.play_area_changed` kommt sofort. Ein eigenes Signal für Raumänderungen gibt es nicht.
- **Positions-Tracking-Verlust** erkennt Godot nicht zuverlässig: das `POSITION_TRACKED`-Bit wird nicht ausgewertet (LIKELY: `tracking_confidence` hilft nicht).
- **Sitzungssignale:** `session_begun`, `session_synchronized`, `session_visible`, `session_focussed`, `session_stopping`, `session_loss_pending`. Godot beendet die Session nicht selbst. Auf Android löst `onPause` nur `NOTIFICATION_APPLICATION_PAUSED` und die Audio-Pause aus, die Engine läuft weiter. Das Vendors-Plugin hat keine Pause- oder Resume-Handler.
- **Neu in 4.7.2:** Signal `user_presence_changed(bool)` und `is_user_present()` über das Project Setting `xr/openxr/extensions/user_presence` (Default aus). VIVE nennt `XR_EXT_user_presence` auf der Focus Vision ab ROM 7.0.999.220. Das ist ein Argument für die Migration, sobald Weg C läuft.
- **Im Projekt heute:** Keines der obigen Signale oder Benachrichtigungen wird behandelt (Suche in allen `.gd`-Dateien).

### 8.3 Drift

- Für Focus Vision gibt es keine veröffentlichten Zahlen. HTC sagt nur qualitativ, Inside-out-Systeme seien anfällig für Skalierungsfehler, weil sie keine Referenz haben.
- Messungen an der Quest 2: RMSE 2,3 bis 5,3 mm (Maximum bis 13,5 mm) in etwa zwei Minuten gegen OptiTrack. Etwa 3 bis 5 cm ATE-RMSE in einem 7x7-m-Mocap-Raum über zehn Läufe ohne Neuausrichtung. Für die Focus 3 nennt eine Zusammenfassung 0,58 cm, nur aus Suchsnippets (UNCERTAIN).
- Größe und Häufigkeit von Relokalisierungs-Sprüngen sind nirgends veröffentlicht. Die größere Gefahr sind daher einzelne Sprünge, nicht der langsame Drift.
- Muster aus Colocation-Apps: Korrektur nur bei Überschreiten eines Schwellwerts, nur Position und Yaw (der Raum bleibt waagerecht), Inhalte nahe an der Referenz, und bei fehlgeschlagener Lokalisierung den Nutzer zum Neuabgleich auffordern.

### 8.4 Folgen für den Alignment-Kern

| Ereignis | Wirkung | Reaktion der App |
|---|---|---|
| `pose_recentered`, neue Session (`session_begun` nach einer Kalibrierung), Wake nach Absetzen (`user_presence_changed` ab 4.7) | Ursprung vermutlich neu | Status `UNKALIBRIERT`, Hinweis im Raum, Meldung an den Server |
| Sprung im Kopf-Tracking (Heuristik: mehr als 0,5 m oder 30 Grad Yaw in einem Frame, am Gerät zu prüfen) | Relokalisierung möglich | Status `PRÜFEN`, Kreuz-Check anbieten |
| Langsamer Drift | Abweichung wächst unbemerkt | Kreuz-Check auf Knopfdruck, Hinweis nach z. B. 15 Minuten ohne Prüfung |

- **Statusmaschine** im Autoload `Alignment`: `UNKALIBRIERT`, `KALIBRIERT`, `PRÜFEN`. Nur `KALIBRIERT` gilt als gültig.
- **Kreuz-Check:** Controller auf Kreuz A und B, Trigger. Die App zeigt die Abweichung in cm und Grad. Unter dem Grenzwert (Vorschlag 2 cm und 1 Grad) bleibt alles, darüber wird neu ausgerichtet. Zwei Punkte sind nötig, weil ein Recenter vor allem den Yaw verändert, den ein einzelnes Kreuz nicht sieht.
- **Server-Meldung:** Der Client meldet seinen Status und das Alter der Kalibrierung. Die Server-Anzeige zeigt grün, gelb oder rot je Brille. Avatare von Clients im Status `UNKALIBRIERT` werden ausgeblendet oder markiert, damit niemand an falscher Stelle erscheint.
- **Nicht speichern:** Die Kalibrierung wird nicht über App-Neustarts hinweg gespeichert. Der Ursprung kann bei jedem Start neu entstehen.
- **Venue-Ablauf im VO-Modus:** Bei jedem Aufsetzen durch einen neuen Besucher sind 20 bis 30 Sekunden Kalibrierung einzuplanen, solange Phase 0b nicht zeigt, dass der Ursprung erhalten bleibt.
- **Alternative LBE:** LBE oder LBE Hybrid mit einmal erstelltem Scan hält die Ausrichtung dauerhaft stabil. Der Scan kauft genau das. Die Kreuze tauschen diesen Aufwand gegen eine kurze Kalibrierung pro Aufsetzen.
- **Standby-Zeit** in Business+ hochsetzen, wenn die Brillen im Raum bleiben. Für abgesetzte Brillen bleibt der Näherungssensor.

### 8.5 Origin-Stabilitätstest (Phase 0b)

Beantwortet die offene Frage am Gerät, ohne Kalibrier-Logik. Ein temporäres Debug-Skript (nicht einchecken oder hinter einem Debug-Flag) schreibt mit Zeitstempel (`Time.get_ticks_msec()`) per `print()` ins `adb logcat -s godot`:

- bei Trigger-Druck: Position der Controller-Spitze lokal zum `XROrigin3D` (x, y, z) und die Kopfposition,
- alle Signale `session_begun`, `session_synchronized`, `session_visible`, `session_focussed`, `session_stopping`, `session_loss_pending`, `pose_recentered` und `play_area_changed`,
- `NOTIFICATION_APPLICATION_PAUSED`, `NOTIFICATION_APPLICATION_RESUMED` und `NOTIFICATION_APPLICATION_FOCUS_IN/OUT`.

Aufbau: Zwei Klebekreuze A und B im Abstand von etwa 4 m. In jedem Szenario beide Kreuze nacheinander antippen. Verglichen werden die Roh-Positionen im Tracking-Raum und der Winkel der Verbindungslinie A nach B.

| Nr. | Szenario | Zweck |
|---|---|---|
| 1 | Dreimal A und B innerhalb einer Minute | Grundrauschen (Wiederholgenauigkeit) |
| 2 | Brille 10 Sekunden absetzen und wieder aufsetzen | Näherungssensor |
| 3 | Brille mehr als 3 Minuten absetzen | Standby nach Timer (bei der Focus 3 soll `OnApplicationPause` erst nach etwa 3 Minuten feuern, Forum, UNCERTAIN) |
| 4 | Power-Taste (Suspend) und wieder aufwecken | Expliziter Standby |
| 5 | App beenden und neu starten | Neuer Start |
| 6 | Recenter (Home-Taste lang bzw. Reset View) | Explizites Recenter |
| 7 | Kameras 10 Sekunden verdecken | Tracking-Verlust und Rückkehr |
| 8 | 10 Minuten durch den Raum gehen | Drift über die Zeit |

Auswertung je Szenario: ΔA in cm, Δ-Winkel der Linie A nach B in Grad, welche Signale gefeuert haben. **Entscheidungsregel:** ΔA bis 2 cm und Δ-Winkel bis 1 Grad: Ursprung erhalten. Darüber: Der Ursprung wurde verändert, das Szenario braucht eine neue Kalibrierung. Zeigen die Szenarien 2 und 4 keine Abweichung, ist die Kalibrierung pro Besucher nicht nötig. Ergebnis als Tabelle im Repo dokumentieren, mit Runtime-Version und Firmware-Stand. Möglichst in beiden Tracking-Zuständen testen (Standard und, falls über Business+ verfügbar, VO).

## 9. Reihenfolge und Entscheidungspunkt

Die Migration ist **keine Voraussetzung** für den Weg-A-Test. Deshalb:

1. **Phase 0 und 0b:** Extension-Probe auf 4.6.1 (unter einer Stunde, kein Umbau) und Origin-Stabilitätstest (Abschnitt 8.5).
2. **Gate:**
   - **Marker-Erweiterung vorhanden:** erst auf 4.7.2 migrieren, weil die Spatial-Entities-API in 4.7 umgebaut wurde und der Provider sonst zweimal geschrieben würde. Dann Phase 2 und 3.
   - **Marker-Erweiterung fehlt:** Weg C zuerst bauen (billig, geräteunabhängig). Die Migration wird eine eigene Entscheidung (Support-Ende von 4.6.x). B1/B2/D/S nur nach ausdrücklicher Entscheidung, sie sind riskant.
   - **Ergebnis Phase 0b:** Bleibt der Ursprung bei Absetzen und Standby erhalten, genügt eine Kalibrierung pro Schicht plus Kreuz-Check. Wird er zurückgesetzt, muss jede Brille bei jedem Aufsetzen neu kalibriert werden (Abschnitt 8.4), oder der LBE-Scan lohnt sich doch.
3. **Die Migration nie kurz vor einer Ausstellung** machen. Termin klären.
4. **Phase 2 (Alignment-Kern)** kann unabhängig von der Probe am PC begonnen werden, weil er für alle Provider gleich ist.

## 10. Phasen

### Phase 0: Extension-Probe (Godot 4.6.1, Weg A)
1. Lokal in `export_presets.cfg` (gitignored) für das Focus-Preset `command_line/extra_args="--verbose"` setzen, Debug-APK bauen, auf der Focus Vision installieren.
2. `adb logcat -s godot` mitschneiden. Zu lesen: "Running on OpenXR runtime: ..." (Name und Version) und die Zeilen "Found OpenXR extension ..." (laut Quelltext je angebotene Erweiterung, UNCERTAIN ob unabhängig von den Project Settings).
3. Gesucht: `XR_EXT_spatial_entity`, `XR_EXT_spatial_marker_tracking`, `XR_EXT_plane_detection`, `XR_HTC_anchor`.
4. Falls die Liste nicht reicht: in einer Wegwerf-Branch `spatial_entity/enabled` und `enable_marker_tracking` einschalten und nach dem Sessionstart `OpenXRSpatialMarkerTrackingCapability.is_aruco_supported()` loggen (nicht vor der Session-Erstellung aufrufen, sonst `false`).
5. Ergebnis (Runtime-Version, Extension-Liste) im Repo dokumentieren.

### Phase 0b: Origin-Stabilitätstest (gleiches Gerät, gleicher Build)
1. Temporäres Debug-Skript laut Abschnitt 8.5 einbauen (loggt Controller-Position lokal zum `XROrigin3D`, alle Session-Signale, `pose_recentered` und die App-Benachrichtigungen mit Zeitstempel). Nicht einchecken oder hinter einem Debug-Flag halten.
2. Zwei Klebekreuze A und B im Abstand von etwa 4 m. Szenarien 1 bis 8 aus Abschnitt 8.5 durchführen, jeweils beide Kreuze antippen.
3. Auswerten mit der Entscheidungsregel (ΔA bis 2 cm und Δ-Winkel bis 1 Grad: Ursprung erhalten) und das Ergebnis samt Firmware-Stand im Repo dokumentieren.
4. Ergebnis fließt in das Gate ein (Abschnitt 9): pro Schicht kalibrieren oder pro Aufsetzen.

### Phase 1: Migration auf Godot 4.7.2 (eigene Branch)
1. Git-Tag auf dem 4.6.1-Stand, neue Branch. 4.6.1-Editor und Templates parallel behalten (ein Rückweg über den Editor ist nicht garantiert).
2. 4.7.2-Editor und Export Templates installieren. Android SDK mit Platform 36, Build-Tools 36.1.0, NDK 29, JDK 17.
3. Vendors-Plugin auf 4.3.1 heben (Addon-Ordner löschen, Zip neu einspielen). 5.1.0 später, als eigener Schritt.
4. Projekt öffnen, reimportieren, GDScript-Meldungen beheben (`return null` bei überschriebenen Methoden).
5. `android/build` löschen, Template neu installieren, Manifest und `gradle.properties` wieder anpassen. Presets prüfen (`shader_baker`, min/target SDK leer lassen).
6. Gerätetest je Headset (Focus Vision, Quest): XR-Session startet, Controller-Profil und Buttons (Issue 484), aktuelle PCK in der APK (Daemon/Caching-Workaround), UDP-Netzwerk, Framezeit, Speicher über mehr als 10 Minuten, VR-Fade-Overlay, Schatten (offene Punkte aus ARCHITECTURE.md).
7. `ARCHITECTURE.md` und `dev_team.md` auf 4.7.2 aktualisieren.

### Phase 2: Alignment-Kern (geräteunabhängig, am PC testbar)
- Autoload `Alignment`, Modi, Transform-Mathematik und Fake-Provider (siehe Abschnitt 6).
- Provider Controller-Zwei-Punkt (Weg C, Abschnitt 7) mit Anzeige im Raum, orientiert am vorhandenen `net_info_board.gd`.
- Selbsttest per `--headless` für die Mathematik: bekannte Punkte rein, erwarteter Transform raus, Abstandsprüfung.
- Statusmaschine `UNKALIBRIERT` / `KALIBRIERT` / `PRÜFEN` mit Reaktion auf `pose_recentered`, Session-Signale, `user_presence_changed` (ab 4.7) und die Sprung-Heuristik (Abschnitt 8.4). Selbsttest der Statusübergänge.
- Kreuz-Check auf Knopfdruck mit Anzeige der Abweichung in cm und Grad, Hinweis nach einer festen Zeit ohne Prüfung.
- Statusmeldung an den Server (grün, gelb, rot je Brille) und Markierung oder Ausblendung unkalibrierter Avatare.

### Phase 3: Provider und Feldtest
- Spatial-Marker-Provider (Weg A), falls Phase 0 positiv war, sonst Weg C als Standard. Alternativen B1/B2/D/S nur nach Entscheidung.
- Feldtest mit mindestens zwei Brillen. Abweichung an einem dritten Bodenkreuz messen. Vergleich LBE-Modus gegen Kreuze-Modus.
- Venue-Workflow in `venue_team.md`, Technik in `ARCHITECTURE.md`.

## 11. Kritische Dateien

- `SYSTEM/player/xr_player.gd`: Origin-Transform, `_broadcast_position()`, `pose_recentered`
- `SYSTEM/scene_manager.gd`: Spawn des XR-Players, Szenenwechsel, Standalone-Modus
- `SYSTEM/main.gd`: Render-Skalierung, VR-Overlay, Menü
- `SYSTEM/net_info_board.gd`: Vorlage für eine "Marker suchen" bzw. "Kreuz A"-Anzeige
- `export_presets.cfg.template`, `android/build/src/main/AndroidManifest.xml`, `android/build/gradle.properties`, `project.godot`
- `_anleitungen/ARCHITECTURE.md`, `_anleitungen/venue_team.md`, `_anleitungen/dev_team.md`

## 12. Verifikation

- **Phase 0:** Logcat enthält Runtime-Name/-Version und die Extension-Liste. Die Entscheidung ist dokumentiert.
- **Phase 0b:** Die Tabelle der Szenarien 1 bis 8 (ΔA in cm, Δ-Winkel in Grad, gefeuerte Signale, Runtime- und Firmware-Stand) liegt im Repo. Es ist entschieden, ob pro Aufsetzen neu kalibriert werden muss.
- **Phase 1:** Auf beiden Headsets läuft die Szenenfolge im Standalone- und im Server-Modus wie vorher. Zehn Minuten Dauerlauf ohne Speicheranstieg. Buttons B/Y auf beiden Controllern.
- **Phase 2:** Headless-Selbsttest der Mathematik. PC-Simulation: zwei Clients mit unterschiedlichem Tracking-Ursprung sehen sich nach der Kalibrierung an derselben Stelle. Simulierter Recenter (Origin-Verschiebung) setzt den Status auf `UNKALIBRIERT`, der Kreuz-Check meldet die künstliche Abweichung korrekt.
- **Phase 3:** Zwei Brillen, eine Referenz (Marker oder Kreuzpaar). Gemessene Abweichung an einem Kontrollkreuz unter einem selbst gesetzten Grenzwert (Vorschlag: 3 cm und 1 Grad).

## 13. Offene Entscheidungen

- Wann ist die nächste Ausstellung (Zeitfenster für die Migration)?
- Gehören die Brillen zu VIVE Business+ (LBSS, Karten, `markers_list.json`)? Das braucht B1 und S.
- Reihenfolge: Probe zuerst (Empfehlung) oder Migration zuerst?
- Soll Weg C auch als dauerhafter Fallback bleiben, wenn Weg A klappt?
- Welche Tasten-Kombination startet die Neukalibrierung?
- Soll der Server Avatare unkalibrierter Brillen ausblenden oder nur markieren?
- Wie oft soll der Kreuz-Check angefordert werden (Vorschlag: nach 15 Minuten ohne Prüfung)?
- Standby-Zeit der Brillen in Business+ hochsetzen (falls vorhanden)? Nur sinnvoll, wenn die Brillen im Raum bleiben.

## 14. Arbeitsablauf und Übergabe

- Diese Datei ist der Stand der Planung. Eine neue Claude-Session auf einem anderen Gerät startet mit `git pull` und dem Auftrag "Lies `_anleitungen/plan_marker_ausrichtung.md`".
- Laufende lokale Desktop-Sessions wandern nicht von selbst zwischen Geräten. Möglich sind: Plan-Datei im Repo (robust), Cloud-Session ("Continue in cloud", benötigt GitHub-Anbindung, UNCERTAIN ob eingerichtet), private Notion- oder Docs-Seite. Remote Control passt nicht, wenn der Rechner ausgeht.
- Das Transcript lässt sich als Zip nach Downloads exportieren. Ob ein anderer Client es importieren kann, ist UNCERTAIN.

## 15. Quellen

- VIVE LBSS: [Visual Odometry Mode](https://business.vive.com/us/support/vive-lbss/category_howto/visual-odometry-(vo)-mode.html), [Marker-Based Location Sharing](https://business.vive.com/us/support/vive-lbss/category_howto/marker-based-location-sharing.html), [MBLS APIs (AIO)](https://business.vive.com/us/support/vive-lbss/category_howto/marker-based-location-sharing-apis-(aio).html), [Scene Alignment APIs (AIO)](https://business.vive.com/us/support/vive-lbss/category_howto/marker-based-scene-alignment-apis-(aio).html), [Requirements](https://business.vive.com/eu/support/vive-lbss/category_howto/requirements.html), [OpenXR Space Calibrator](https://business.vive.com/us/support/vive-lbss/category_howto/openxr-space-calibrator.html)
- Wave SDK: [WVR Marker](https://hub.vive.com/storage/docs/en-us/Sdk_WvrMarker.html), [Unity Trackable Marker](https://hub.vive.com/storage/docs/en-us/UnityXR/UnityXRTrackableMarker.html)
- VIVE OpenXR: [Release Notes](https://developer.vive.com/resources/openxr/unity/download/latest/), [Anchor](https://developer.vive.com/resources/openxr/unity/tutorials/mixed-reality/anchor/), [Plane Detection](https://developer.vive.com/resources/openxr/unity/tutorials/mixed-reality/plane-detection/), [Focus-Vision-Firmware](https://www.vive.com/release-notes/vive-focus-vision/)
- HTC-Forum: [Marker/Location Sharing, Thread 20106](https://forum.htc.com/topic/20106-marker-based-tracking-location-sharing-scene-alignment/), [OpenXR und QR/Marker, Thread 16486](https://forum.htc.com/topic/16486-openxr-and-qr-codemarker-integration/), [Kein Kamerazugriff, Thread 9661](https://forum.htc.com/topic/9661-vive-focus-3-no-camera-passthrough-access/)
- Khronos: [OpenXR-Inventory](https://github.khronos.org/OpenXR-Inventory/runtime_extension_support.html), [HTC-Runtime](https://raw.githubusercontent.com/KhronosGroup/OpenXR-Inventory/main/runtimes/htc_vive_focus.json), [XR_EXT_spatial_marker_tracking](https://developer.android.com/develop/xr/openxr/extensions/XR_EXT_spatial_marker_tracking)
- Godot: [Spatial Entities](https://docs.godotengine.org/en/stable/tutorials/xr/openxr_spatial_entities.html), [OpenXRSpatialMarkerTrackingCapability](https://docs.godotengine.org/en/latest/classes/class_openxrspatialmarkertrackingcapability.html), [Upgrade auf 4.7](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html), [4.7.2](https://godotengine.org/article/maintenance-release-godot-4-7-2/), [PR 107391](https://github.com/godotengine/godot/pull/107391), [PR 118128](https://github.com/godotengine/godot/pull/118128), [Issue 124258](https://github.com/godotengine/godot/issues/124258)
- Vendors-Plugin: [godot_openxr_vendors](https://github.com/GodotVR/godot_openxr_vendors), [Issue 484](https://github.com/GodotVR/godot_openxr_vendors/issues/484)
- Drift, Standby, Recenter: [Setup MBLS](https://business.vive.com/eu/support/vive-lbss/category_howto/setting-up-marker-based-location-sharing.html), [LBE-Modus](https://business.vive.com/eu/support/vive-lbss/category_howto/location-based-entertainment-(lbe)-mode.html), [LBE Hybrid](https://business.vive.com/eu/support/vive-lbss/category_howto/running-lbe-hybrid-mode.html), [Scene Alignment einrichten](https://business.vive.com/eu/support/vive-lbss/category_howto/setting-up-marker-based-scene-alignment.html), [Drift Prevention](https://business.vive.com/eu/support/vive-lbss/category_howto/marker-based-drift-prevention.html), [Advanced Relocation](https://business.vive.com/eu/support/vive-lbss/category_howto/marker-based-advanced-relocation.html), [OpenXR ReferenceSpaceChangePending](https://registry.khronos.org/OpenXR/specs/1.1/man/html/XrEventDataReferenceSpaceChangePending.html), [Godot-Issue 99157](https://github.com/godotengine/godot/issues/99157), [VIVE User Presence](https://developer.vive.com/resources/openxr/unity/tutorials/fundamental-components/checking-if-player-is-wearing-the-headset/), [Quest-2-Messung](https://arxiv.org/html/2412.06116v1), [Quest-2-Messung 7x7 m](https://arxiv.org/html/2509.06582v1)
