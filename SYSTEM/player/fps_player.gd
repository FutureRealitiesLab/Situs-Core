# TEMPLATE CORE – nicht verändern
extends CharacterBody3D

## fps_player.gd – Desktop-Fallback für Tests ohne Headset.
##
## Steuerung: WASD bewegen, Maus für Umsehen, Leertaste springen, ESC Maus freigeben.
## Gleiche Netzwerk-Logik wie xr_player.gd – beide senden via NetworkManager.send_player_state().


const SPEED: float        = 4.0
const JUMP_VELOCITY: float = 4.5
const MOUSE_SENSITIVITY: float = 0.003
const SEND_RATE: float    = 0.05

@onready var head: Node3D   = $Head
@onready var camera: Camera3D = $Head/Camera3D

var _send_timer: float = 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = true
	# Layer 2 (Wert 2): "players" | Mask 1: nur mit Welt kollidieren, NICHT mit Avataren
	collision_layer = 2
	collision_mask  = 1


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Horizontale Drehung am Körper, vertikale am Kopf
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, -PI * 0.45, PI * 0.45)

	# ESC → Maus freigeben (Fenster bedienbar)
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Klick ins Fenster → Maus wieder einfangen und View-Steuerung aktiv
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	# Gravitation
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Sprung (Leertaste = ui_accept)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# WASD-Bewegung (ui_left/right/up/down = A/D/W/S per Default)
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	move_and_slide()

	# Position senden
	_send_timer += delta
	if _send_timer >= SEND_RATE:
		_send_timer = 0.0
		_broadcast_position()


func _broadcast_position() -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	NetworkManager.send_player_state(
		global_position,
		head.global_position,
		head.global_rotation
	)
