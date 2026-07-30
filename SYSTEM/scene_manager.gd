# TEMPLATE CORE – nicht verändern
extends Node

## scene_manager.gd – Persistenter Szenen-Controller für die Multiplayer-Ausstellung.
##
## Architektur-Übersicht:
##
##   main.tscn (persistent, läuft immer)
##     ├── Menu          – Startmenü
##     ├── SceneContainer  – hier werden Team-Szenen rein-/rausgeladen
##     ├── PlayersContainer – Avatare leben hier; überleben Szenenwechsel!
##     └── ServerHUD      – Timer-Anzeige + "Next"-Button, nur Server
##
##   SceneManager (Autoload)
##     • liest Szenen-Liste aus scenes/scene_registry.gd
##     • Server: steuert Timer, löst Szenenwechsel via RPC aus
##     • Server: sendet aktuelle Szene an Späteinsteiger (by name/index)
##     • Server: reagiert auf N-Taste und Button-Druck
##     • Clients: empfangen Szenenwechsel-RPC, laden lokal
##     • alle: spawnen lokalen Spieler + Remote-Avatare


## Standard-Avatar – wird genutzt wenn die Szene keinen eigenen angibt
const DEFAULT_AVATAR = preload("res://SYSTEM/avatar/remote_avatar.tscn")
const XRPlayer       = preload("res://SYSTEM/player/xr_player.tscn")
const FPSPlayer      = preload("res://SYSTEM/player/fps_player.tscn")

## Index der aktuell laufenden Szene
var current_index: int = -1

## Laufzeit-Timer der aktuellen Szene (Sekunden)
var _timer: float = 0.0

## Szenen-Liste aus scene_registry.gd
var scenes_list: Array = []

## Referenzen auf Container-Nodes aus main.tscn (gesetzt via initialize())
var _scene_container:   Node3D = null
var _players_container: Node3D = null

## Aktuell geladene Team-Szene
var _current_scene: Node = null

## Lokaler Spieler dieser Instanz
var local_player: Node = null

## Eigener Avatar (Körper-Anzeige in First-Person) – nur wenn Avatar set_self_mode() unterstützt
var self_avatar: Node = null

## Remote-Avatare – bleiben über Szenenwechsel erhalten!
## peer_id (int) → RemoteAvatar-Node
## Wird direkt von networking/network_manager.gd gelesen.
var remote_avatars: Dictionary = {}

## Standalone-Modus: Szenen laufen lokal durch ohne Server (aktiviert via A-Taste am Headset)
var standalone_mode: bool = false

signal scene_changed(index: int, scene_name: String)
signal timer_tick(remaining: float, total: float)

## Wird vor dem Szenenwechsel emittiert. main.gd startet den Fade-Out
## und ruft danach confirm_scene_load(index) auf.
signal scene_about_to_change(index: int)


# ══════════════════════════════════════════════════════════════════
#  Initialisierung  (aufgerufen von main.gd nach Modus-Wahl)
# ══════════════════════════════════════════════════════════════════

## Muss vor start() aufgerufen werden.
## scene_container   → Node3D "SceneContainer" aus main.tscn
## players_container → Node3D "PlayersContainer" aus main.tscn
func initialize(scene_container: Node3D, players_container: Node3D) -> void:
	_scene_container   = scene_container
	_players_container = players_container

	var registry     = load("res://_scenes/scene_registry.gd").new()
	var folder_list: Array = registry.get_scenes()
	scenes_list = []
	for folder_path in folder_list:
		var d := _load_scene_info(folder_path)
		if not d.is_empty():
			scenes_list.append(d)
		else:
			push_warning("[SceneManager] Überspringe '%s' (scene_info.cfg fehlt oder ungültig)" % folder_path)

	if scenes_list.is_empty():
		push_warning("[SceneManager] Keine Szenen geladen – scene_registry.gd prüfen!")
		return

	NetworkManager.player_joined.connect(_on_player_joined)
	NetworkManager.player_left.connect(_on_player_left)

	if GameState.mode != GameState.Mode.SERVER:
		NetworkManager.client_connected.connect(_on_client_connected)
		NetworkManager.client_disconnected.connect(_on_client_disconnected)

	print("[SceneManager] %d Szene(n) registriert." % scenes_list.size())


## Lädt scene_info.cfg aus einem Szenen-Ordner und gibt das Scene-Dict zurück.
## Gibt leeres Dict zurück wenn die Datei fehlt oder scene_file nicht gesetzt ist.
func _load_scene_info(folder_path: String) -> Dictionary:
	var cfg_path := folder_path + "scene_info.cfg"
	var cf       := ConfigFile.new()
	if cf.load(cfg_path) != OK:
		push_error("[SceneManager] scene_info.cfg nicht gefunden: " + cfg_path)
		return {}
	var scene_file: String = cf.get_value("scene", "scene_file", "")
	if scene_file.is_empty():
		push_error("[SceneManager] 'scene_file' fehlt in: " + cfg_path)
		return {}
	var d := {
		"path":     folder_path + scene_file,
		"name":     cf.get_value("scene", "name",     "Unbenannt"),
		"duration": cf.get_value("scene", "duration", -1.0),
		"avatar":   cf.get_value("scene", "avatar",   "res://SYSTEM/avatar/variants/avatar_dynamic_cone.tscn"),
		"team":     cf.get_value("scene", "team",     ""),
		"info":     cf.get_value("scene", "info",     ""),
	}
	if cf.has_section_key("scene", "player_color"):
		d["player_color"] = cf.get_value("scene", "player_color")
	return d


## Startet das System nach initialize().
func start() -> void:
	if GameState.mode == GameState.Mode.SERVER:
		# Server lädt sofort Szene 0 und benachrichtigt alle bereits verbundenen Clients
		_load_scene_local(0)
		if multiplayer.get_peers().size() > 0:
			_rpc_change_scene.rpc(0)
	else:
		# Client: Szene 0 sofort laden – nicht auf Server-Verbindung warten.
		# Wenn der Server eine andere Szene schickt, wird per _rpc_change_scene gewechselt.
		_load_scene_local(0)


# ══════════════════════════════════════════════════════════════════
#  Timer  (läuft nur auf dem Server)
# ══════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	_update_self_avatar()

	if not standalone_mode:
		if not multiplayer.has_multiplayer_peer():
			return
		if not multiplayer.is_server():
			return

	if current_index < 0 or scenes_list.is_empty():
		return

	var duration: float = float(scenes_list[current_index].get("duration", -1.0))
	if duration <= 0.0:
		return  # Kein Auto-Advance für diese Szene

	_timer += delta
	timer_tick.emit(duration - _timer, duration)

	if _timer >= duration:
		advance_scene()


# ══════════════════════════════════════════════════════════════════
#  Szenenwechsel  (Server-seitig ausgelöst)
# ══════════════════════════════════════════════════════════════════

## Lädt die nächste Szene – aufrufbar vom Server per N-Taste oder Button,
## oder lokal im Standalone-Modus.
func advance_scene() -> void:
	if not multiplayer.is_server() and not standalone_mode:
		return
	_timer = 0.0
	var next: int = (current_index + 1) % scenes_list.size()
	print("[SceneManager] Szenenwechsel → Index %d" % next)
	scene_about_to_change.emit(next)


## Lädt die vorherige Szene — analog zu advance_scene().
func retreat_scene() -> void:
	if not multiplayer.is_server() and not standalone_mode:
		return
	_timer = 0.0
	var prev: int = (current_index - 1 + scenes_list.size()) % scenes_list.size()
	print("[SceneManager] Szenenwechsel ← Index %d" % prev)
	scene_about_to_change.emit(prev)


## Aktiviert den lokalen Standalone-Modus (kein Server nötig).
## Wird von xr_player.gd via A-Taste und fps_player.gd via Q/E ausgelöst.
func activate_standalone() -> void:
	standalone_mode = true
	_timer = 0.0
	print("[SceneManager] Standalone-Modus aktiviert.")


## Lädt eine spezifische Szene nach ihrem Index (Server-only).
func go_to_scene(index: int) -> void:
	if not multiplayer.is_server():
		return
	scene_about_to_change.emit(index)


## Aufgerufen von main.gd nach Fade-Out.
## Führt den eigentlichen Szenenwechsel aus und benachrichtigt Clients.
func confirm_scene_load(index: int) -> void:
	_load_scene_local(index)
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_rpc_change_scene.rpc(index)


# ══════════════════════════════════════════════════════════════════
#  RPC – Szene auf Clients laden
# ══════════════════════════════════════════════════════════════════

## Wird vom Server gerufen; läuft auf Clients (call_remote → nie auf Server selbst).
## Clients routen durch den gleichen Fade-Pfad wie der Server.
@rpc("authority", "reliable", "call_remote")
func _rpc_change_scene(index: int) -> void:
	if index == current_index:
		return  # Bereits geladen – verhindert Doppel-Load wenn Client kurz nach start() verbindet
	scene_about_to_change.emit(index)
	# main.gd ruft confirm_scene_load(index) nach dem Fade-Out auf.


func _load_scene_local(index: int) -> void:
	if index < 0 or index >= scenes_list.size():
		push_error("[SceneManager] Ungültiger Index: %d" % index)
		return

	current_index = index
	_timer = 0.0

	# Alte Szene entladen
	if is_instance_valid(_current_scene):
		_current_scene.queue_free()
		_current_scene = null

	# Lokalen Spieler entladen (wird neu gespawnt, Position reset)
	if is_instance_valid(local_player):
		local_player.queue_free()
		local_player = null

	if is_instance_valid(self_avatar):
		self_avatar.queue_free()
		self_avatar = null

	# Neue Szene instantiieren
	var scene_data: Dictionary = scenes_list[index]
	var packed := load(scene_data["path"]) as PackedScene
	if packed == null:
		push_error("[SceneManager] Szene nicht gefunden: " + scene_data["path"])
		return

	_current_scene = packed.instantiate()
	_scene_container.add_child(_current_scene)

	# Verbindungsstatus-Tafel in Clients injizieren (versteckt sich sobald verbunden)
	if GameState.mode != GameState.Mode.SERVER:
		_spawn_net_info_board()

	# Focus 3: Schatten weicher machen (render_scale 0.6 + PCF-Standard = pixelig)
	if _is_focus3():
		_soften_shadows(_current_scene)

	# Lokalen Spieler spawnen (nicht auf Server)
	if GameState.mode != GameState.Mode.SERVER:
		_spawn_local_player()
		_spawn_self_avatar()

	# Bereits verbundene Remote-Avatare mit dem Avatar-Typ dieser Szene neu spawnen
	_respawn_all_remote_avatars()

	var label: String = scene_data.get("name", "Szene %d" % index)
	print("[SceneManager] '%s' geladen (Index %d)" % [label, index])
	scene_changed.emit(index, label)


# ══════════════════════════════════════════════════════════════════
#  Spieler & Avatare
# ══════════════════════════════════════════════════════════════════

func _spawn_local_player() -> void:
	match GameState.mode:
		GameState.Mode.XR:
			local_player = XRPlayer.instantiate()
		GameState.Mode.FPS:
			local_player = FPSPlayer.instantiate()
	if local_player:
		_players_container.add_child(local_player)


## Spawnt einen Avatar für den eigenen Körper (First-Person-Ansicht).
## Nur wenn das Avatar-Script set_self_mode() kennt (z. B. DynamicCone).
func _spawn_self_avatar() -> void:
	var av := _get_current_avatar_scene().instantiate()
	if not av.has_method("set_self_mode"):
		av.free()
		return
	_players_container.add_child(av)
	var color_override = scenes_list[current_index].get("player_color", null) if current_index >= 0 else null
	if color_override is Color and av.has_method("set_force_color"):
		av.set_force_color(color_override)
	av.peer_id = GameState.my_id
	av.set_self_mode(true)
	self_avatar = av


## Aktualisiert den Selbst-Avatar mit der eigenen Spielerposition.
## FPS-Player: Head-Node bei y=1.6; XR-Player: XRCamera3D.
func _update_self_avatar() -> void:
	if not is_instance_valid(self_avatar):
		return
	if not is_instance_valid(local_player):
		return
	var head_node: Node3D = local_player.get_node_or_null("Head")
	if head_node == null:
		head_node = local_player.get_node_or_null("XRCamera3D")
	var head_pos: Vector3
	if head_node:
		head_pos = head_node.global_position
	else:
		head_pos = local_player.global_position + Vector3(0.0, 1.6, 0.0)
	# Basis = Kopf-XZ auf Boden-Y projiziert: Avatar folgt physischer Bewegung,
	# nicht dem fixen XROrigin-Spawn-Punkt. Für FPS kein Unterschied (Head-XZ == Body-XZ).
	var base_pos := Vector3(head_pos.x, local_player.global_position.y, head_pos.z)
	var head_rot := head_node.global_rotation if head_node != null else Vector3.ZERO
	self_avatar.update_transform(base_pos, head_pos, head_rot)


## Gibt die Avatar-Szene für die aktuelle Team-Szene zurück.
## Teams tragen optional "avatar": "res://SYSTEM/avatar/variants/..." in scene_registry.gd ein.
## Fehlt der Eintrag oder ist der Pfad ungültig → DEFAULT_AVATAR.
func _get_current_avatar_scene() -> PackedScene:
	if current_index >= 0 and current_index < scenes_list.size():
		var path: String = scenes_list[current_index].get("avatar", "")
		if path != "":
			var packed := load(path) as PackedScene
			if packed:
				return packed
			push_warning("[SceneManager] Avatar-Pfad ungültig: %s – nutze Default." % path)
	return DEFAULT_AVATAR


func _spawn_remote_avatar(peer_id: int) -> void:
	if remote_avatars.has(peer_id):
		return
	# Szene-spezifischer Farb-Override: "player_color" in scene_registry
	#   Color(r,g,b,1) → alle Spieler bekommen in dieser Szene dieselbe Farbe
	#   nicht gesetzt / null → individuelle Farbe (vom Server zugewiesen)
	var avatar: Node = _get_current_avatar_scene().instantiate()
	# add_child VOR peer_id: _ready() läuft zuerst (baut Ringe, setzt _ready_done,
	# initialisiert @onready-Nodes), danach triggert der peer_id-Setter _apply_color()
	# mit vollständig initialisiertem Avatar.
	_players_container.add_child(avatar)
	# Szenen-Override DIREKT an Avatar übergeben – GameState.player_colors bleibt
	# unberührt, damit keine Farbe in die nächste Szene blutet.
	var color_override = scenes_list[current_index].get("player_color", null) if current_index >= 0 else null
	if color_override is Color and avatar.has_method("set_force_color"):
		avatar.set_force_color(color_override)
	avatar.peer_id = peer_id
	remote_avatars[peer_id] = avatar
	print("[SceneManager] Remote-Avatar für Spieler %d gespawnt." % peer_id)


## Alle vorhandenen Remote-Avatare mit dem Avatar-Typ der neuen Szene neu spawnen.
## Wird nach jedem Szenenwechsel aufgerufen.
func _respawn_all_remote_avatars() -> void:
	var peer_ids: Array = remote_avatars.keys()
	for pid in peer_ids:
		if is_instance_valid(remote_avatars[pid]):
			remote_avatars[pid].queue_free()
	remote_avatars.clear()
	for pid in peer_ids:
		_spawn_remote_avatar(pid)


# ── Netzwerk-Callbacks ───────────────────────────────────────────

func _on_player_joined(peer_id: int) -> void:
	if GameState.mode == GameState.Mode.SERVER:
		# Späteinsteiger bekommt sofort die aktuelle Szene
		if current_index >= 0:
			_rpc_change_scene.rpc_id(peer_id, current_index)
			print("[Server] Späteinsteiger %d → Szene %d gesendet." % [peer_id, current_index])
		# Server spawnt Avatar um Positionen in der ServerView anzuzeigen
		_spawn_remote_avatar(peer_id)
		return

	# Client: Avatar für neuen Spieler spawnen
	if peer_id == multiplayer.get_unique_id():
		return
	_spawn_remote_avatar(peer_id)


func _on_player_left(peer_id: int) -> void:
	if remote_avatars.has(peer_id):
		remote_avatars[peer_id].queue_free()
		remote_avatars.erase(peer_id)
		print("[SceneManager] Remote-Avatar für Spieler %d entfernt." % peer_id)


func _on_client_connected() -> void:
	# GameState.my_id ist jetzt gesetzt. Falls self_avatar bereits gespawnt wurde
	# (während my_id noch 0 war), Farbe jetzt nachladen.
	if is_instance_valid(self_avatar):
		self_avatar.peer_id = GameState.my_id


func _on_client_disconnected() -> void:
	# Server weg → alle Remote-Avatare entfernen.
	# Nach dem Reconnect sendet der Server neue _notify_player_joined-RPCs
	# und die Avatare werden neu gespawnt.
	for pid: int in remote_avatars.keys():
		remote_avatars[pid].queue_free()
	remote_avatars.clear()
	print("[SceneManager] Alle Remote-Avatare entfernt (Verbindung verloren).")


## Aufgerufen von scene_hooks.gd._ready() jeder Team-Szene.
## Übernimmt F6-Testmodus-Erkennung und ServerCamera-Positionierung,
## damit dieser Boilerplate nicht in den Team-Szenen-Scripts steht.
func on_team_scene_ready(scene_root: Node3D) -> void:
	if scenes_list.is_empty():
		# F6-Modus: SceneManager wurde nicht von main.gd initialisiert.
		var fps := FPSPlayer.instantiate()
		scene_root.add_child(fps)
		fps.global_position = Vector3(0, 1, 0)
		print("[SceneManager] F6-Testmodus: FPS-Player gespawnt.")
		print("               WASD = Bewegen  |  Maus = Umsehen  |  ESC = Maus freigeben")
	else:
		# Spielbetrieb: ServerCamera robust per look_at() ausrichten.
		# look_at() verhindert Transform-Korruption die beim .tscn-Speichern auftreten kann.
		var cam := scene_root.get_node_or_null("ServerCamera") as Camera3D
		if cam:
			cam.global_position = Vector3(0.0, 5.0, 5.0)
			cam.look_at(Vector3(0.0, 0.5, 0.0), Vector3.UP)
		print("[SceneManager] '%s' im Spielbetrieb geladen." % scene_root.name)


## Injiziert eine Label3D-Verbindungsstatusanzeige in die aktuelle Szene.
## Das Label versteckt sich sobald die Verbindung steht (→ SYSTEM/net_info_board.gd).
func _spawn_net_info_board() -> void:
	if not is_instance_valid(_current_scene):
		return
	var board := Label3D.new()
	board.name = "NetInfoBoard"
	board.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Position: rechte Seite, Kopfhöhe, hintere Raumhälfte –
	# außerhalb des Kunstwerk-Zentrums, gut zugänglich für Cassiopeia
	board.position = Vector3(1.6, 1.5, 2.5)
	board.pixel_size = 0.005
	board.font_size = 24
	board.outline_size = 5
	board.modulate = Color(1.0, 0.45, 0.1)        # Orange – gut sichtbar im Dunkeln
	board.outline_modulate = Color(0.0, 0.0, 0.0)  # Schwarzer Rand für Lesbarkeit
	board.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board.set_script(load("res://SYSTEM/net_info_board.gd"))
	_current_scene.add_child(board)


# ══════════════════════════════════════════════════════════════════
#  Server: N-Taste für manuellen Szenenwechsel
# ══════════════════════════════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	if not multiplayer.is_server():
		return
	if event.is_action_pressed("scene_next"):
		print("[Server] Manueller Szenenwechsel via Taste N.")
		advance_scene()


# ══════════════════════════════════════════════════════════════════
#  Geräte-spezifische Performance-Optimierungen
# ══════════════════════════════════════════════════════════════════

## Weichere Schatten auf Focus 3: höheres shadow_blur reduziert den pixeligen Look
## bei render_scale 0.6. DirectionalLight → 2 Kaskaden statt 4 (günstiger + sauberer
## bei kleinen Indoor-Räumen ohne langen Schattenwurf in die Ferne).
func _soften_shadows(scene_root: Node) -> void:
	var count: int = 0
	for light in scene_root.find_children("*", "DirectionalLight3D", true, false):
		var d := light as DirectionalLight3D
		d.shadow_blur = 2.5
		d.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		count += 1
	for light in scene_root.find_children("*", "OmniLight3D", true, false):
		(light as OmniLight3D).shadow_blur = 2.0
		count += 1
	for light in scene_root.find_children("*", "SpotLight3D", true, false):
		(light as SpotLight3D).shadow_blur = 2.0
		count += 1
	if count > 0:
		print("[SceneManager] Focus 3: shadow_blur gesetzt für %d Lichtquelle(n)." % count)


## True wenn das Gerät ein HTC Focus 3 / Vive ist.
## Wird zur Laufzeit via OS.get_model_name() ermittelt.
func _is_focus3() -> bool:
	var model: String = OS.get_model_name().to_lower()
	return "focus" in model or "vive" in model


## Deaktiviert Schatten aller Lichtquellen in einer Szene.
## Focus 3: 2448×2448 px/Auge – Schatten-PCF-Taps ~66% teurer als auf Quest 2.
## Ohne Schatten: +0.8–1.2 ms Spielraum pro Frame (≈ 9–11% bei 90 Hz Budget).
func _disable_shadows(scene_root: Node) -> void:
	var lights: Array = []
	lights.append_array(scene_root.find_children("*", "DirectionalLight3D", true, false))
	lights.append_array(scene_root.find_children("*", "OmniLight3D",        true, false))
	lights.append_array(scene_root.find_children("*", "SpotLight3D",        true, false))
	for light: Node in lights:
		(light as Light3D).shadow_enabled = false
	if lights.size() > 0:
		print("[SceneManager] Focus 3: %d Lichtquelle(n) – Schatten deaktiviert." % lights.size())
