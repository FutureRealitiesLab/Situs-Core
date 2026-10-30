# TEMPLATE CORE – nicht verändern
extends CharacterBody3D

## avatar_dynamic_cone.gd – Standard-Avatar für die Ausstellung.
##
## Stellt einen Spieler als gestapelte Ringe dar, die weich hinter der
## Kopfbewegung nachziehen — ähnlich einer Kette.
## Anzahl, Größe und Nachzieh-Verhalten sind im Inspektor einstellbar.
## Für eine eigene Variante: avatar_dynamic_cone.tscn duplizieren
## und die Inspektor-Werte überschreiben (kein Code nötig).

## Anzahl der Ringe zwischen Boden und Kopf
@export var num_rings: int = 8

## Durchmesser des untersten Rings (Meter)
@export var base_diameter: float = 1.2

## Durchmesser des obersten Rings – direkt unter dem Kopf (Meter)
@export var top_diameter: float = 0.18

## Kantenlänge des Kopf-Würfels (Meter). Der Würfel sitzt an der Brillenposition,
## die kleine Nase auf seiner Vorderseite zeigt die Blickrichtung.
## Der Kopf-Collider bleibt eine Kugel mit diesem Durchmesser.
@export var head_diameter: float = 0.25

## Dicke des Donut-Schlauchs (Meter) – wie "fett" jeder Ring ist
@export var tube_diameter: float = 0.049

## Segmente um den Schlauch-Querschnitt (Detailgrad des Röhrchens)
@export var tube_segments: int = 12

## Y-Abstand des untersten Rings vom Boden (Meter)
@export var base_y_offset: float = 0.05

## Abstand zwischen oberstem Ring und Kopf-Würfel (Meter)
@export var top_ring_gap: float = 0.05

## Responsivität des untersten Rings (1/Sekunde). Halbwertszeit ≈ ln(2)/Wert.
## 3.0 → ~0.23 s bis halbe Lücke geschlossen; sinnvoller Bereich 1.0 – 8.0.
@export var damping_bottom: float = 3.0

## Responsivität des obersten Rings (1/Sekunde).
## 14.0 → ~0.05 s; sinnvoller Bereich 8.0 – 20.0.
@export var damping_top: float = 14.0

## Krümmung der Dämpfungs-Verteilung (1.0 = linear).
## > 1.0 macht untere Ringe träger, < 1.0 macht sie responsiver.
@export var damping_curve: float = 1.0

## Controller als Quader: Länge (Z), Breite und Höhe (Meter)
@export var hand_length: float = 0.15
@export var hand_width: float = 0.04

## Versatz des gesamten Avatars nach hinten (Rücken-Richtung), Meter.
## Folgt der Kopf-Yaw-Richtung. 0.0 = kein Versatz (zentriert auf Spieler).
## Wird für Remote-Avatare auf 0.0 gelassen; set_self_mode() aktiviert 0.1 für den eigenen Avatar.
@export var body_back_offset: float = 0.0


# ── Interface: wird von SceneManager gesetzt ─────────────────────
var peer_id: int = 0:
	set(value):
		peer_id = value
		_apply_color()  # wird ggf. vor _ready() aufgerufen → Guard in _apply_color
		# peer_id auch auf Head-Collider spiegeln (falls schon erstellt)
		if is_instance_valid(_head_collider):
			_head_collider.set_meta("peer_id", value)


# ── Interne Zustandsvariablen ────────────────────────────────────
var _rings:          Array = []   # MeshInstance3D pro Ring
var _ring_pos_cur:   Array = []   # aktuelle (gedämpfte) Weltposition
var _ring_pos_tgt:   Array = []   # Zielposition (vom Netzwerk)
var _head_mesh:      MeshInstance3D = null   # Würfel, folgt Position und Rotation des Kopfes
var _head_nose:      MeshInstance3D = null   # Blickrichtung (Vorderseite = -Z)
var _head_collider:  StaticBody3D = null   # Kopf-Collider, Layer 4, Gruppe "avatar_heads"
var _head_cur:       Vector3 = Vector3.ZERO
var _head_tgt:       Vector3 = Vector3.ZERO
var _head_basis_cur: Basis = Basis.IDENTITY
var _head_basis_tgt: Basis = Basis.IDENTITY
var _hands:          Array = []   # 2 MeshInstance3D: links, rechts (nur sichtbar, wenn getrackt)
var _hand_pos_tgt:   Array = [Vector3.ZERO, Vector3.ZERO]
var _hand_basis_tgt: Array = [Basis.IDENTITY, Basis.IDENTITY]
var _hand_snap:      Array = [true, true]  # beim ersten Tracking sofort einrasten
var _self_mode:      bool = false
var _ready_done:     bool = false
var _first_update:   bool = true  # beim ersten Netzwerk-Update sofort einrasten


func _ready() -> void:
	add_to_group("remote_avatars")
	collision_layer = 4   # Layer 3: "avatars"
	collision_mask  = 0   # kein Physik-Kontakt

	_build_rings()
	_ready_done = true  # muss VOR _apply_color() stehen, sonst greift der Guard
	_apply_color()


# ── Aufbau ───────────────────────────────────────────────────────

func _build_rings() -> void:
	var tube_radius: float = tube_diameter / 2.0
	for i in range(num_rings):
		var t            = float(i) / float(max(num_rings - 1, 1))
		var ring_radius  = lerp(base_diameter, top_diameter, t) / 2.0

		var inst  := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius   = max(0.001, ring_radius - tube_radius)
		torus.outer_radius   = ring_radius + tube_radius
		torus.rings          = 24
		torus.ring_segments  = tube_segments
		inst.mesh = torus
		add_child(inst)

		_rings.append(inst)
		_ring_pos_cur.append(Vector3.ZERO)
		_ring_pos_tgt.append(Vector3.ZERO)

	# Kopf-Würfel mit Nase auf der Vorderseite (-Z, wie die Blickrichtung der Kamera)
	_head_mesh = MeshInstance3D.new()
	var box        := BoxMesh.new()
	box.size        = Vector3.ONE * head_diameter
	_head_mesh.mesh = box
	add_child(_head_mesh)

	_head_nose = MeshInstance3D.new()
	var nose       := BoxMesh.new()
	nose.size       = Vector3.ONE * head_diameter * 0.3
	_head_nose.mesh = nose
	_head_nose.position = Vector3(0.0, 0.0, -head_diameter * 0.5)
	_head_mesh.add_child(_head_nose)

	# Controller: zwei schmale Quader, Länge entlang Z
	for i in 2:
		var hand := MeshInstance3D.new()
		var hbox := BoxMesh.new()
		hbox.size = Vector3(hand_width, hand_width, hand_length)
		hand.mesh = hbox
		hand.visible = false
		add_child(hand)
		_hands.append(hand)

	# Kopf-Collider: StaticBody3D auf Layer 4, Gruppe "avatar_heads"
	# Folgt _head_cur in _process() → Area3D-Trigger können gezielt auf den Kopf reagieren.
	# Zugriff auf Spieler-ID: body.get_meta("peer_id") oder body.get_parent().peer_id
	_head_collider = StaticBody3D.new()
	_head_collider.collision_layer = 4
	_head_collider.collision_mask  = 0
	_head_collider.add_to_group("avatar_heads")
	var _hcol_shape  := CollisionShape3D.new()
	var _hcol_sphere := SphereShape3D.new()
	_hcol_sphere.radius = head_diameter / 2.0
	_hcol_shape.shape   = _hcol_sphere
	_head_collider.add_child(_hcol_shape)
	add_child(_head_collider)


# ── Netzwerk-Update (vom NetworkManager aufgerufen, ~20 Hz) ──────

func update_transform(body_pos: Vector3, head_pos: Vector3, head_rot: Vector3) -> void:
	# Horizontal-Rückwärtsvektor aus Kopf-Yaw (kein Pitch/Roll)
	var back_dir    := Vector3(sin(head_rot.y), 0.0, cos(head_rot.y))
	var back_offset := back_dir * body_back_offset

	var base        = body_pos + Vector3(0.0, base_y_offset, 0.0) + back_offset
	# Ringe enden top_ring_gap unterhalb des Kopf-Würfels.
	var ring_top    = head_pos - Vector3(0.0, top_ring_gap, 0.0) + back_offset
	for i in range(_rings.size()):
		var t = float(i) / float(max(_rings.size() - 1, 1))
		_ring_pos_tgt[i] = base.lerp(ring_top, t)

	_head_tgt = head_pos + back_offset
	_head_basis_tgt = Basis.from_euler(head_rot)

	# Beim allerersten Update: Positionen sofort einrasten (kein Slide von 0,0,0)
	if _first_update:
		_first_update = false
		for i in range(_rings.size()):
			_ring_pos_cur[i] = _ring_pos_tgt[i]
		_head_cur = head_pos + back_offset
		_head_basis_cur = _head_basis_tgt


## Controller-Posen (vom NetworkManager, ~20 Hz). hands = [links_pos, links_rot,
## rechts_pos, rechts_rot] in Weltkoordinaten, mask: Bit 0 links, Bit 1 rechts getrackt.
func update_hands(hands: PackedVector3Array, mask: int) -> void:
	if _self_mode or _hands.size() < 2 or hands.size() < 4:
		return
	for i in 2:
		var tracked: bool = (mask & (1 << i)) != 0
		_hands[i].visible = tracked
		if not tracked:
			_hand_snap[i] = true
			continue
		_hand_pos_tgt[i] = hands[i * 2]
		_hand_basis_tgt[i] = Basis.from_euler(hands[i * 2 + 1])
		if _hand_snap[i]:
			_hand_snap[i] = false
			_hands[i].global_position = _hand_pos_tgt[i]
			_hands[i].global_basis = _hand_basis_tgt[i]


# ── Smooth-Update pro Frame (delta-basiert, framerate-unabhängig) ─

func _process(delta: float) -> void:
	# Warten bis zum ersten update_transform()-Aufruf, damit die Ringe nicht kurz
	# auf Vector3.ZERO (Szenenursprung) erscheinen, bevor die echte Position ankommt.
	if _rings.is_empty() or _first_update:
		return

	# Dämpfung: linearer Gradient (mit Kurve) von bottom zu top.
	for i in range(_rings.size()):
		var t              = float(i) / float(max(_rings.size() - 1, 1))
		var responsiveness = lerp(damping_bottom, damping_top, pow(t, damping_curve))
		var smooth         = 1.0 - exp(-responsiveness * delta)
		
		_ring_pos_cur[i] = _ring_pos_cur[i].lerp(_ring_pos_tgt[i], smooth)
		_rings[i].global_position = _ring_pos_cur[i]

	if is_instance_valid(_head_mesh):
		# Kopf ist etwas responsiver als der oberste Ring (Faktor 1.5),
		# um den "Lead" zu behalten, aber fließend zum Rest.
		var head_resp = damping_top * 1.5
		_head_cur = _head_cur.lerp(_head_tgt, 1.0 - exp(-head_resp * delta))
		_head_mesh.global_position = _head_cur
		_head_basis_cur = _head_basis_cur.slerp(_head_basis_tgt, 1.0 - exp(-head_resp * delta))
		_head_mesh.global_basis = _head_basis_cur
		# Controller folgen mit derselben Glättung wie der Kopf
		var hand_smooth := 1.0 - exp(-head_resp * delta)
		for i in _hands.size():
			if _hands[i].visible:
				_hands[i].global_position = _hands[i].global_position.lerp(_hand_pos_tgt[i], hand_smooth)
				_hands[i].global_basis = _hands[i].global_basis.slerp(_hand_basis_tgt[i], hand_smooth)
		if is_instance_valid(_head_collider):
			_head_collider.global_position = _head_cur


# ── Selbst-Ansicht (eigener Körper in First-Person) ─────────────

## Schaltet den Avatar in den Selbst-Modus:
##   • Kopf-Würfel wird ausgeblendet (würde FPS-Kamera verdecken)
##   • collision_layer = 0  (löst keine Area3D-Trigger aus)
## Wird von SceneManager nach add_child() aufgerufen.
func set_self_mode(enabled: bool) -> void:
	if not enabled:
		return
	_self_mode = true
	for hand: MeshInstance3D in _hands:
		hand.visible = false  # eigene Controller sieht man ohnehin direkt
	body_back_offset = 0.1  # Ringe 10 cm hinter Brille → Hals-Position
	collision_layer = 0
	if is_instance_valid(_head_mesh):
		_head_mesh.visible = false
	if is_instance_valid(_head_collider):
		_head_collider.collision_layer = 0


# ── Farbe (Spielerfarbe aus GameState oder Szenen-Override) ─────

## Szenen-spezifischer Farb-Override. Gesetzt von SceneManager wenn
## "player_color" in scene_registry eingetragen ist.
## Color(0,0,0,0) = kein Override → individuelle GameState-Farbe.
var _force_color: Color = Color(0, 0, 0, 0)

func set_force_color(c: Color) -> void:
	_force_color = c
	_apply_color()


func _apply_color() -> void:
	if peer_id == 0 or not _ready_done:
		return

	var color: Color = _force_color if _force_color.a > 0.01 else GameState.get_color_for_id(peer_id)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness    = 0.7
	for ring in _rings:
		if is_instance_valid(ring):
			ring.set_surface_override_material(0, mat)

	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = color.lightened(0.3)
	cmat.roughness    = 0.5
	for hand: MeshInstance3D in _hands:
		hand.set_surface_override_material(0, cmat)

	if is_instance_valid(_head_mesh):
		var hmat := StandardMaterial3D.new()
		hmat.albedo_color = color.lightened(0.3)
		hmat.roughness    = 0.3
		hmat.metallic     = 0.4
		_head_mesh.set_surface_override_material(0, hmat)

		var nmat := StandardMaterial3D.new()
		nmat.albedo_color = color.lightened(0.7)
		nmat.roughness    = 0.3
		_head_nose.set_surface_override_material(0, nmat)
