extends Node3D

# Exportierte Variablen für den Editor
@export var rotation_speed: Vector3 = Vector3(0, 1, 0)

func _process(delta):
	# Berechne die Rotation basierend auf der Zeit (delta)
	# Damit die Drehung unabhängig von der Framerate flüssig läuft
	rotate_x(deg_to_rad(rotation_speed.x) * delta)
	rotate_y(deg_to_rad(rotation_speed.y) * delta)
	rotate_z(deg_to_rad(rotation_speed.z) * delta)
