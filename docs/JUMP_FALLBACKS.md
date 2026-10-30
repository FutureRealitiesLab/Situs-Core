# Sprung: Fallback-Ansätze für die Erkennung

Stand 2026-10-30. Der Boost-Sprung (`xr_player.gd`: `start_boost()`) wird von zwei Auslösern gestartet:

1. B-Taste, nur rechter Controller (`_on_right_button`).
2. Hocke, dann Hochspringen (`_detect_jump`, erste Version).

Stand nach dem ersten Brillentest des Boost-Sprungs: Die Körpererkennung (Hocke, Hochspringen) löst aus, die B-Taste nicht, obwohl der Controller beim Drücken weiß aufblitzt, die Taste also ankommt. Vermutlich hat die Taste auf der Brille einen anderen Namen als `by_button`. Beim Drücken zeigt ein Hinweis im Blickfeld den Namen (Setting *Situs Core → Jump → Show Button Names*), der Name wird unter *Situs Core → Jump → Button* eingetragen. Falls die Hocke später nicht zuverlässig auslöst, stehen diese Ansätze bereit. Der Code liegt in der Git-Historie (`git show <Commit>:addons/situs_core/player/xr_player.gd`).

## Tastennamen (OpenXR und Godot)

- In OpenXR gibt es keine Tasten namens „secondary button". Die Spezifikation benennt Eingaben nach ihrem Pfad (`/user/hand/right/input/b/click`). „primary" und „secondary" sind in der Godot-Action-Map die beiden Thumbsticks (Vector2), keine Knöpfe.
- Godot meldet `button_pressed` mit dem Namen der **Aktion aus unserer Action Map**: B und Y heißen `by_button`, A und X `ax_button` (Typ bool, im Profil `htc/vive_focus3_controller` an `b/click`, `y/click`, `a/click`, `x/click` gebunden).
- Offene Vermutung: Nutzt die Brille ein anderes Profil (z. B. `khr/simple_controller`), gibt es dort nur `select_button` und `menu_button`, B existiert dann gar nicht, und der Controller blitzt trotzdem bei Trigger oder Menü. Der Hinweis im Blickfeld zeigt deshalb neben dem Tastennamen auch das aktive Profil (Setting *Show Button Names*).

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
