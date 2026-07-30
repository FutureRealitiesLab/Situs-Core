## scene_hooks.gd
## ════════════════════════════════════════════════════════════════
##  Optionales Lifecycle-Script für Team-Szenen.
##
##  Zweck:
##    Bietet _ready()- und _exit_tree()-Hooks für szenenspezifischen
##    Code (Sounds starten/stoppen, Animationen, Timer usw.).
##
##    F6-Testmodus und ServerCamera-Positionierung werden automatisch
##    vom SceneManager übernommen — kein Boilerplate nötig.
##
##  Verwendung:
##    Script an die Root-Node der Team-Szene hängen.
##    _ready() und _exit_tree() nach Bedarf befüllen.
## ════════════════════════════════════════════════════════════════

extends Node3D


func _ready() -> void:
	SceneManager.on_team_scene_ready(self)

	# ── Eigener Code beim Laden der Szene ──────────────────────
	# $Sounds/Ambience.play()


func _exit_tree() -> void:
	# ── Eigener Code beim Entladen der Szene ───────────────────
	# $Sounds/Ambience.stop()
	pass
