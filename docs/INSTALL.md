# Install and Configuration

Diese Anleitung richtet Situs Core auf einem neuen Windows-Rechner so ein, dass das Projekt in Godot läuft und als APK für die HTC Vive Focus 3 oder Focus Vision exportiert werden kann.

## Auf einem neuen Rechner

1. **Godot 4.7.2 laden** (Standardversion, nicht .NET) von [godotengine.org/download](https://godotengine.org/download). Einmal starten und wieder schließen. Dabei legt Godot seine Einstellungen an.
2. **Git installieren** und das Repo klonen:

```powershell
git clone https://github.com/FutureRealitiesLab/Situs-Core.git
```

3. **Setup-Skript ausführen.** Godot muss dabei geschlossen sein. PowerShell im Repo-Ordner öffnen:

```powershell
powershell -ExecutionPolicy Bypass -File tools\setup_android.ps1
```

   Das dauert eine Weile und lädt mehrere GB aus dem Internet. Das Skript installiert alles, was für den Android-Export nötig ist (siehe unten) und akzeptiert dabei die Android-SDK-Lizenzen. Man kann es gefahrlos erneut starten, Vorhandenes wird übersprungen.
4. **Projekt in Godot öffnen:** Godot starten, den Repo-Ordner importieren. Beim ersten Öffnen importiert Godot die Dateien.
5. **Testen:** F5 drücken, *Als Server starten*. Für eine zweite Instanz *Debug → Run Multiple Instances* und *Als Spieler starten (Lokal / 127.0.0.1)* wählen.

Damit läuft das Projekt auf dem PC. Für die Brille:

6. **Server-IP eintragen:** *Project Settings → Situs Core → Network → Server Ip* auf die LAN-IP des Server-PCs setzen (`ipconfig`).
7. **Firewall am Server-PC freigeben** (Admin-PowerShell), damit sich die Brillen verbinden können:

```powershell
New-NetFirewallRule -DisplayName "Situs ENet 7777" -Direction Inbound -Protocol UDP -LocalPort 7777 -Action Allow
```

8. **Brille vorbereiten:** Entwicklermodus aktivieren, per USB verbinden, `adb devices` muss sie anzeigen.
9. **APK exportieren und installieren.** `JAVA_HOME` und der Exportbefehl stehen am Ende der Skriptausgabe. `Godot` steht für den Pfad zur Godot-exe (z. B. `& "$HOME\Desktop\Godot_v4.7.2-stable_win64.exe"`):

```powershell
$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot"
```

```powershell
Godot --headless --path . --export-debug "Android – HTC Focus 3" build/SitusCore-Focus3.apk
```

```powershell
adb install -r build/SitusCore-Focus3.apk
```

   Alternativ im Editor: *Projekt → Exportieren*. Das Preset gilt für Focus 3 und Focus Vision. Nach einer Änderung an Server-IP, Raumgröße oder Drehung muss die APK neu exportiert werden.

Wenn der Export fehlschlägt, nennt die Meldung meist den fehlenden Teil. Prüfe dann die Liste im nächsten Abschnitt.

---

## Was das Skript installiert (für Interessierte)

Das Skript `tools/setup_android.ps1` richtet den Rechner für den Android-Export ein. Es ist idempotent und braucht Windows mit `winget`.

| Komponente | Wofür | Woher |
|------------|-------|-------|
| **OpenJDK 17** | Wird vom Gradle-Build der APK und zum Signieren (`keytool`) gebraucht | winget (`Microsoft.OpenJDK.17`) |
| **Android SDK** (Command-line Tools, `platform-tools`, Platform 36, Build-Tools 36.1.0, NDK 29.0.14206865, CMake 3.22.1) | Baut aus dem Godot-Export die APK. `platform-tools` enthält `adb` zum Installieren auf der Brille. Das NDK und CMake brauchen die nativen Teile | Google (`dl.google.com`) |
| **Godot-Export-Vorlagen 4.7.2** | Basis jedes Exports. Für die Brille zählt `android_source.zip` | godot-builds auf GitHub |
| **Android-Build-Vorlage** im Projekt (`android/build`) | Das Gradle-Projekt, in das Godot Spiel und Plugins einsetzt | Aus den Export-Vorlagen entpackt |
| **Godot OpenXR Vendors 5.1.0** (`addons/godotopenxrvendors`) | Bindet die HTC-Brillen über OpenXR auf Android an | GitHub (GodotVR) |
| **Debug-Keystore** | Signiert die Debug-APK, ohne Signatur lässt sie sich nicht installieren | Mit `keytool` erzeugt |
| **Godot-Editor-Einstellungen** | Trägt Java-Pfad, SDK-Pfad und Keystore ein, damit der Export sie findet | `%APPDATA%\Godot\editor_settings-4.7.tres` |
| **`export_presets.cfg`** | Wird aus `export_presets.cfg.template` angelegt, falls sie fehlt | Dieses Repo |

**Was manuell bleibt (das Skript tut es nicht):**

- Godot selbst und Git installieren.
- Entwicklermodus an der Brille aktivieren und `adb` verbinden (USB oder WLAN).
- Die Server-IP in den Project Settings setzen und die Firewall freigeben.
- Bei anderen Godot-Versionen die Versionsnummern im Skript anpassen. Die Android-Versionen (Platform, Build-Tools, NDK) hängen an der Godot-Version.

---

## Referenz: Einstellungen für HTC Vive Focus 3 und Vision

Die Werte stammen aus Projekten, in denen der Export auf der Focus Vision funktioniert hat (Godot 4.7.2). Das Skript und `export_presets.cfg.template` setzen sie bereits. Diese Tabellen sind für den Fall, dass du ein Projekt selbst einrichtest.

**Project Settings**

| Setting | Wert |
|---------|------|
| Rendering → Renderer → Rendering Method (und `.mobile`) | `gl_compatibility` |
| Rendering → Textures → VRAM Compression → Import ETC2 ASTC | an |
| XR → OpenXR → Enabled | an |
| XR → Shaders → Enabled | an |
| XR → OpenXR → Startup Alert | aus (sonst erscheint am PC ohne Headset eine Fehlermeldung) |
| Situs Core → Network → Server Ip | IP des Server-PCs |

**Export-Preset (Android)**

| Bereich | Einstellung |
|---------|-------------|
| Gradle Build | *Use Gradle Build* **an**, Export Format *APK* |
| Architekturen | nur **arm64-v8a** |
| Paket | *Unique Name* je Projekt eindeutig (z. B. `org.firma.projekt`), *Signed* an |
| XR Features | *XR Mode* **OpenXR**, *Enable Khronos Plugin* **an** |
| Khronos XR Features | im Situs-Template zusätzlich `vendors=1` (HTC). Auf der Focus Vision lief auch ein Preset ohne diesen Wert |
| Bildschirm | *Immersive Mode* an |
| Berechtigungen | *Internet*, *Access Network State*, *Access Wifi State* an (nötig für ENet und UDP) |
| Meta | *Enable Meta Plugin* aus |

*Runnable* ist im Template aus (nur für den Ein-Klick-Start auf der Brille nötig), und *Unique Name* ist ein Platzhalter.

**Export-Vorlagen von Hand** (falls du das Skript nicht nutzt): *Editor → Export-Vorlagen verwalten*. Seit Godot 4.7 wählst du einzelne Vorlagen aus. Für die Brille genügt **Mobil → Android → `android_source.zip`**. `android_debug.apk` und `android_release.apk` brauchst du nur ohne Gradle-Build. Windows-Vorlagen nur für einen `.exe`-Export des Servers.

## Häufige Meldungen

| Meldung | Bedeutung |
|---------|-----------|
| `Unable to open Android 'build-tools' directory` beim Start von Godot | Der Android-SDK-Pfad in den Editor-Einstellungen zeigt auf einen Ordner ohne SDK. Skript ausführen oder den Pfad leeren. Betrifft nur den Export, nicht das Spielen am PC |
| Brille meldet keine Verbindung und versucht `127.0.0.1:7777` | Die APK enthält noch die Standard-IP. *Project Settings → Situs Core → Network → Server Ip* auf die LAN-IP des Server-PCs setzen (`ipconfig`), APK neu exportieren und installieren |
| Export bricht ab | Meist fehlt ein Teil: Export-Vorlagen, *Android SDK Path*, *Java SDK Path*, Build-Vorlage (`android/`) oder `addons/godotopenxrvendors` |
| `OpenXR was requested but failed to start` | Kein Headset am PC. Mit *Startup Alert* aus erscheint der Dialog nicht mehr |
