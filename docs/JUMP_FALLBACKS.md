# Sprung: Fallback-Ansätze für die Erkennung

Stand 2026-10-30. Der Boost-Sprung (`xr_player.gd`: `start_boost()`) wird von zwei Auslösern gestartet:

1. B-Taste, nur rechter Controller (`_on_right_button`).
2. Hocke, dann Hochspringen (`_detect_jump`, erste Version).

Die Körpererkennung der ersten Version konnte auf der Brille nicht bestätigt werden, weil der Sprung damals nur für die anderen sichtbar war (der eigene Avatar ist in VR ausgeblendet). Mit dem Boost-Sprung sieht man ihn selbst. Falls die Hocke nicht zuverlässig auslöst, stehen diese Ansätze bereit. Der Code liegt in der Git-Historie (`git show <Commit>:addons/situs_core/player/xr_player.gd`).

## Bekannte Schwächen der ersten Version (aktuell aktiv)

- Die Standhöhe wird nur gesetzt, wenn die Kopfhöhe im Tracking-Raum über 0.8 m liegt. Beginnt der Tracking-Raum am Kopf (Reference Space *Local* statt *Local Floor*), ist die Höhe um 0 und die Erkennung startet nie.
- Läuft im Physik-Takt, die Kopfpose kommt aber pro gerendertem Bild.
- Die Geschwindigkeit wird über einen einzelnen Schritt gemessen (anfällig für Ausreißer).

## Fallbacks (nach Aufwand)

1. **Relative Standhöhe statt Absolutwert** (`77abc4f`): Standhöhe wird nach 1.5 s gültigem Tracking gesetzt, egal wo der Tracking-Raum beginnt. Geschwindigkeit über ein Fenster von ca. 0.22 s. Auswertung in `_process`.
2. **Anstieg, dann Abfall des Kopfes, ohne Hocke** (`a876442`): Der Kopf steigt schnell (über 1.0 m/s, mindestens 0.1 m in 0.22 s) und fällt innerhalb von 0.7 s wieder. Erkennt auch Sprünge aus dem Stand und verwirft das bloße Aufrichten.
3. **Rückmeldung und Debug** (`16a00e5`): Vibration beider Controller beim Erkennen (`trigger_haptic_pulse("haptic", 0.0, 1.0, 0.3, 0.0)`), kurzer Hinweistext (Label3D an der Kamera) mit „Anstieg", „SPRUNG", dem Namen jeder gedrückten Taste und den Messwerten, Log mit Präfix `[Sprung]` (`adb logcat -s godot`).
4. **Controller-Höhen mit auswerten:** Beim Springen bewegen sich beide Hände mit dem Kopf. Nur als Plausibilitätsprüfung gegen Verbeugen, noch nicht gebaut.

## Hinweise

- Die Action Map belegt `by_button` für `/user/hand/right/input/b/click` im Profil `htc/vive_focus3_controller`. Fehlende Bindings sind also kein Grund, wenn B nicht ankommt (eine frühere Vermutung war falsch).
- Über OpenXR gibt es in Godot keinen Beschleunigungssensor der Brille.
