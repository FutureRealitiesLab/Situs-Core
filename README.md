# Hyper-Irrealismus III

Dieses Projekt läuft mit **Godot 4.6** (Forward Plus Renderer, OpenXR aktiviert); öffnet `project.godot` im Godot Editor und drückt F5 – auf dem Vive Focus 3 wird die APK über den Android-Export ausgerollt, am Desktop erscheint ein Startmenü mit den Optionen *Spieler (First Person)* und *Server*.
**Bevor ihr startet:** In `networking/network_manager.gd` die Variable `server_ip` auf die lokale IP-Adresse eures Gaming-PCs setzen (z. B. `192.168.1.100`); der Server wird per Menü-Button oder mit dem `--headless` Flag auf dem PC gestartet.
**Ihr dürft anfassen:** `assets/` (eigene GLB-Scans rein), `triggers/interaction_zone.gd` duplizieren und anpassen, sowie Trigger-Instanzen in `world/world.tscn` platzieren – alle anderen Dateien sind mit `# TEMPLATE CORE` markiert und sollten nicht verändert werden.
