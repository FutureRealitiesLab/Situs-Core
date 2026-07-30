# ARCHITECTURE.md — Hyper-Irrealismus III
<!-- machine-readable project documentation for AI agents and future development -->
<!-- UPDATE THIS FILE with every structural change, new module, or interface change -->

---

## META

```yaml
project:       Hyper-Irrealismus III
organization:  FutureRealitiesLab
engine:        Godot 4.6 (GL Compatibility renderer — switched from Forward Plus 2026-04-27)
language:      GDScript
type:          Multiplayer VR Exhibition Template
status:        active development
main_branch:   master
last_updated:  2026-07-30
last_commit:   "standalone VR mode + thumbstick locomotion + dual controller support"
```

### Roles
| Role | Responsibility |
|------|----------------|
| Dev Team | Template core, CI/CD, APK builds, scene_registry.gd |
| Venue Team | Exhibition day startup, hardware, monitoring |
| Design Teams | Create one team scene each; submit via Git |

---

## SYSTEM OVERVIEW

```
┌──────────────────────────────────────────────────────────────────────┐
│                        EXHIBITION SETUP                              │
│                                                                      │
│  ┌─────────────┐   ENet UDP    ┌──────────────────────────────────┐  │
│  │  Server PC  │◄──Port 7777──►│  Clients (up to 8)               │  │
│  │  (Godot     │               │  • HTC Vive Focus Vision (XR)     │  │
│  │  SERVER     │               │  • HTC Focus 3 (XR)               │  │
│  │  mode)      │               │  • Meta Quest 2/3/Pro (XR)        │  │
│  │             │               │  • Desktop PC (FPS, optional)     │  │
│  │  Shows all  │               └──────────────────────────────────┘  │
│  │  avatars    │  LAN Router (isolated network, no internet needed)  │
│  └─────────────┘                                                      │
│                                                                      │
│  STANDALONE MODE (kein Server):                                      │
│  XR-Client läuft autonom — Szenenwechsel per Timer + B/Y-Button     │
└──────────────────────────────────────────────────────────────────────┘
```

### Scene Lifecycle
```
Server Timer expires / N key / Button         Standalone: Timer or B/Y
         │                                              │
         ▼                                              ▼
SceneManager.advance_scene()             SceneManager.advance_scene()
         │                                              │
         └──────────────────────┬───────────────────────┘
                                ▼
                   scene_about_to_change.emit(next)
                                │
                                ▼
                     main.gd → _start_vr_scene_fade()
                     (or _start_fps_scene_fade on PC)
                                │
                                ▼  (after fade-out)
                   SceneManager.confirm_scene_load(index)
                                │
                                ▼
                   _load_scene_local(index)
                        ├── free old scene
                        ├── free local_player + self_avatar
                        ├── instantiate new scene → SceneContainer
                        ├── spawn local player (FPS or XR)
                        ├── spawn self_avatar (if avatar supports set_self_mode)
                        ├── _soften_shadows(scene_root)  ← Focus 3/Vision only
                        └── respawn all remote avatars (new avatar variant)
```

### Standalone Mode (kein Server)
```
XR-Client startet → kein Server erreichbar → "Keine Verbindung" Board erscheint
  │
  ▼ Beliebiger Controller-Button gedrückt
  │
  SceneManager.activate_standalone()
    → standalone_mode = true
    → _timer = 0.0
    → Board verschwindet (net_info_board.gd prüft standalone_mode)
  │
  ▼ Ab jetzt:
  _process() ignoriert multiplayer-Guards → Timer läuft
  advance_scene() ignoriert is_server()-Check → Szenen laufen durch
  confirm_scene_load() sendet keinen RPC → nur lokaler Wechsel
```

### Network State Relay (per-frame, ~20 Hz)
```
Client (XR/FPS player)
  │  send_player_state(body_pos, head_pos, head_rot)
  │  → RPC _server_receive_state() → Server
  │          ├── update server-local avatar (for ServerView display)
  │          └── relay → _client_receive_state() → all other clients
  │                           └── avatar.update_transform(...)
```

---

## FILE INDEX

Every file in the project with role and "TEMPLATE CORE" flag.

### Core (do not modify unless you are the developer)
| File | Role | Lines |
|------|------|-------|
| `SYSTEM/main.gd` | Root node: menu, mode selection, HUD, VR fade overlay | ~330 |
| `SYSTEM/main.tscn` | Root scene: containers, HUD, cameras, XRWalkArea | — |
| `SYSTEM/scene_manager.gd` | **Autoload**: scene loader, scene_info.cfg reader, avatar manager, timer, shadow softening, standalone mode | ~490 |
| `SYSTEM/networking/game_state.gd` | **Autoload**: mode, peer IDs, colors | 44 |
| `SYSTEM/networking/network_manager.gd` | **Autoload**: ENet relay, RPC chain | 183 |
| `SYSTEM/player/fps_player.gd` | FPS camera+movement controller | 92 |
| `SYSTEM/player/fps_player.tscn` | FPS player scene | — |
| `SYSTEM/player/xr_player.gd` | OpenXR tracking + thumbstick locomotion + button handling | ~115 |
| `SYSTEM/player/xr_player.tscn` | XR player scene (XROrigin3D + LeftHand + RightHand + debug spheres) | — |
| `SYSTEM/openxr_action_map.tres` | OpenXR action bindings (Quest + Focus3/Vision + khr/simple profiles) | — |
| `SYSTEM/cam_dolly.gd` | Rotations-Node (Y-Achse, 2°/s) — rotiert ServerCamera in main.tscn | ~11 |
| `SYSTEM/avatar/remote_avatar.gd` | Base remote avatar: interpolation, color | 66 |
| `SYSTEM/avatar/remote_avatar.tscn` | Legacy capsule+sphere avatar | — |
| `SYSTEM/avatar/variants/avatar_dynamic_cone.gd` | DynamicCone avatar script | ~196 |
| `SYSTEM/avatar/variants/avatar_dynamic_cone.tscn` | DynamicCone scene | — |
| `SYSTEM/avatar/variants/avatar_box.tscn` | Box avatar variant | — |
| `SYSTEM/avatar/variants/avatar_capsule.tscn` | Capsule avatar variant | — |
| `SYSTEM/avatar/variants/avatar_sphere.tscn` | Sphere avatar variant | — |
| `SYSTEM/avatar/variants/avatar_ghost.tscn` | Ghost avatar variant | — |
| `_deprecated/triggers/interaction_zone.gd` | Area3D trigger template (deaktiviert) | 178 |
| `_deprecated/triggers/interaction_zone.tscn` | Trigger zone scene (deaktiviert) | — |
| `project.godot` | Engine configuration | — |
| `.gitignore` | Git ignore rules | — |
| `export_presets.cfg.template` | APK export config template (tracked) | — |

### Team-editable
| File | Role |
|------|------|
| `_scenes/scene_registry.gd` | **Dev Team only** — ordered folder-path list; no metadata |
| `_scenes/team_X/scene_info.cfg` | **Design Teams** — per-team metadata: name, duration, scene_file, avatar, … |
| `_scenes/team_template/team_scene.gd` | Team scene base script — duplicate per team |
| `_scenes/team_template/team_scene.tscn` | Team scene base — duplicate per team |
| `_scenes/team_template/net_info_board.gd` | Injected at runtime into every scene (not in tscn, spawned by SceneManager) |

### Documentation
| File | Role |
|------|------|
| `_anleitungen/ARCHITECTURE.md` | Technical reference (this file) |
| `_anleitungen/design_teams.md` | Guide for Design Teams: scenes, assets, Git workflow |
| `_anleitungen/venue_team.md` | Guide for Venue Team: server start, headsets, troubleshooting |
| `_anleitungen/dev_team.md` | Guide for Dev Team: integration, APK builds, exhibition prep |

### Build / Ops (local only, gitignored except template)
| File | Role |
|------|------|
| `export_presets.cfg` | Local APK export config (copy from .template) |
| `android/build/src/main/AndroidManifest.xml` | VR manifest (tracked via .gitignore exception) |
| `android/build/gradle.properties` | Gradle-Build-Einstellungen (daemon=false, caching=false; tracked via .gitignore exception) |

---

## MODULE SPECIFICATIONS

### `SYSTEM/main.gd` + `SYSTEM/main.tscn`

**Purpose:** Persistent root. Always loaded. Manages startup flow, contains all containers, VR fade overlay.

**Scene tree:**
```
Main (Node, main.gd)
├── XRWalkArea (MeshInstance3D, visible=false)  ← PlaneMesh size=Vector2(3.5,6)
│                                                  locomotion boundary für XR Players
│                                                  SINGLE POINT OF TRUTH — nicht in team scenes
├── SceneContainer (Node3D)      ← team scenes loaded/unloaded here
├── PlayersContainer (Node3D)    ← local player + all avatars (persist across scenes)
├── ServerHUD (CanvasLayer, layer=10, initially hidden)
│   └── Panel → VBox
│       ├── NetworkLabel         ← IP addresses shown on start
│       ├── SceneLabel           ← "Szene: <name>"
│       ├── TimerLabel           ← "Timer: <remaining>s"
│       ├── TimerBar (ProgressBar)
│       └── BtnNext ("Nächste Szene [N]")
├── Menu (CanvasLayer, initially visible on PC)
│   └── Center → VBox
│       ├── BtnFPS  → GameState.Mode.FPS  + NetworkManager.start_client()
│       └── BtnServer → GameState.Mode.SERVER + NetworkManager.start_server()
├── FadeOverlay (CanvasLayer, layer=20, initially hidden)  ← FPS/PC only
│   ├── ColorRect (full-screen, black, alpha=0, mouse_filter=IGNORE)
│   └── SceneInfoLabel (centered, font_size=28, modulate.a=0)
└── NetDiag (CanvasLayer, Tab toggle)
    └── Panel → Label (net diagnostics)

# VR-only nodes created at runtime in _setup_vr_fade_overlay():
_vr_fade_plane (MeshInstance3D, QuadMesh 8×8m, no_depth_test, render_priority=100)
_vr_fade_label (Label3D, no_depth_test, render_priority=101)
```

**Key constants:**
```gdscript
const FADE_OUT_DURATION: float = 1.0
const TEXT_HOLD_DURATION: float = 2.5
const FADE_IN_DURATION:   float = 0.5
const VR_OVERLAY_DIST:    float = 2.0   # meters in front of camera
const VR_OVERLAY_SPEED:   float = 4.0   # lazy-follow 1/s
```

**Key functions:**
- `_ready()` — detects XR: sets VRS_XR + render_scale 0.6 (Focus/Vive devices) OR VRS_DISABLED (PC)
- `_launch()` — called after mode selection; calls SceneManager.initialize() + start()
- `_setup_vr_fade_overlay()` — creates 3D QuadMesh + Label3D for VR transitions (called in _ready for XR only)
- `_start_vr_scene_fade(index, text)` — snaps overlay to camera, then tween via `tween_method`
- `_start_fps_scene_fade(index, text)` — existing 2D CanvasLayer tween (PC only)
- `_process(delta)` — lazy-follow: moves VR overlay toward camera when visible
- `_get_xr_camera()` — returns `SceneManager.local_player.get_node_or_null("XRCamera3D")`

**Critical VRS note:**
`project.godot` sets `vrs/mode=2` (VRS_XR). Without an XR device this causes a PC black screen.
`_ready()` programmatically overrides: `get_viewport().vrs_mode = Viewport.VRS_DISABLED` for PC path.
Do NOT remove either setting — both are needed.

---

### `SYSTEM/scene_manager.gd` (Autoload: SceneManager)

**Purpose:** Central coordinator. Manages scene lifecycle, player spawning, avatar management, timer, shadow softening, and standalone mode.

**Public API:**
```gdscript
SceneManager.initialize(scene_container, players_container)  # called by main.gd
SceneManager.start()                                          # called by main.gd after initialize
SceneManager.advance_scene()                                  # next scene (server OR standalone)
SceneManager.go_to_scene(index: int)                          # jump to specific scene (server only)
SceneManager.confirm_scene_load(index: int)                   # called by main.gd after fade-out
SceneManager.activate_standalone()                            # called by xr_player.gd on button press

SceneManager.current_index     # int: index of loaded scene (-1 = none)
SceneManager.scenes_list       # Array of scene dicts from registry
SceneManager.local_player      # Node: local FPS or XR player
SceneManager.remote_avatars    # Dictionary: peer_id → avatar Node
SceneManager.self_avatar       # Node: own body avatar (FP view)
SceneManager.standalone_mode   # bool: true = XR client running without server
```

**Signals:**
```gdscript
signal scene_about_to_change(index: int)            # fires before swap → triggers fade
signal scene_changed(index: int, scene_name: String) # fires after swap
signal timer_tick(remaining: float, total: float)
```

**Standalone mode guards in `_process()`:**
```gdscript
# Timer only runs on: server, OR standalone XR client
if not standalone_mode:
    if not multiplayer.has_multiplayer_peer(): return
    if not multiplayer.is_server(): return
```

**`advance_scene()` guard:**
```gdscript
# Allowed on: server, OR standalone XR client
if not multiplayer.is_server() and not standalone_mode:
    return
_timer = 0.0  # reset immediately — prevents repeated calls during fade-out
```

**`confirm_scene_load(index)`:**
```gdscript
_load_scene_local(index)
if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
    _rpc_change_scene.rpc(index)   # standalone: no RPC sent (not server)
```

**Scene dict format** (from scene_registry.gd):
```gdscript
{
  "name":         String,   # display name (shown in ServerHUD + fade overlay)
  "path":         String,   # res:// path to .tscn
  "duration":     float,    # seconds; -1.0 = no auto-advance
  "avatar":       String,   # optional: res:// path to avatar .tscn
  "team":         String,   # optional: team name shown in fade overlay
  "info":         String,   # optional: short description shown in fade overlay
  "player_color": Color,    # optional: fixed color for ALL players in this scene
                            # not set → individual colors (server-assigned)
}
```

**Shadow softening (Focus 3/Vision only):**
```gdscript
func _soften_shadows(scene_root: Node) -> void:
    # Called in _load_scene_local() only when _is_focus3() is true.
    # GL Compat + render_scale 0.6 → pixelated shadows without blur.
    for light in scene_root.find_children("*", "DirectionalLight3D", true, false):
        d.shadow_blur = 2.5
        d.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
    # OmniLight3D and SpotLight3D: shadow_blur = 2.0
```

**`_is_focus3()` detection:**
```gdscript
var model: String = OS.get_model_name().to_lower()
return "focus" in model or "vive" in model
```
Matches: Focus 3, Focus Vision, Vive Pro, Vive XR Elite, etc.

---

### `SYSTEM/networking/game_state.gd` (Autoload: GameState)

**Purpose:** Lightweight global state. No networking logic.

```gdscript
GameState.mode          # GameState.Mode enum: XR | FPS | SERVER
GameState.my_id         # int: own ENet peer ID (set after connect)
GameState.player_colors # Dictionary: peer_id → Color
GameState.get_color_for_id(peer_id) # → Color (assigns if new)
GameState.reset()       # clears colors + id
```

**Color palette** (8 slots, server assigns round-robin, broadcast to all clients):
`Red, Blue, Green, Yellow, Magenta, Cyan, Orange, LightGray`

---

### `SYSTEM/networking/network_manager.gd` (Autoload: NetworkManager)

**Purpose:** ENet transport layer. Relay-only server (no game logic on server side, only relay + avatar update).

**Constants:**
```gdscript
PORT = 7777
MAX_CLIENTS = 8
```

**Server IP:** Hardcoded in `network_manager.gd` Zeile 24:
```gdscript
var server_ip: String = "192.168.50.29"
```
Vor dem APK-Build auf die IP des Server-PCs setzen. `server_ip.txt` ist veraltet und wird nicht eingelesen.

**Public API:**
```gdscript
NetworkManager.start_server()
NetworkManager.start_client()
NetworkManager.send_player_state(body, head_pos, head_rot)  # called ~20Hz by player scripts
NetworkManager.client_connected_flag  # bool: true once server handshake complete
NetworkManager.reconnect_attempts     # int: increments on each reconnect try
```

**Signals:**
```gdscript
signal player_joined(peer_id: int)
signal player_left(peer_id: int)
signal client_connected()
signal client_disconnected()
```

**Reconnect behavior:** ENet client retries every 5s indefinitely.

---

### `SYSTEM/player/xr_player.gd` + `xr_player.tscn`

**Purpose:** OpenXR headset controller. Thumbstick locomotion bounded to XRWalkArea. Both controllers fully symmetric.

**Scene tree:**
```
XRPlayer (XROrigin3D, xr_player.gd)
├── XRCamera3D                    ← head tracking (auto by OpenXR)
├── LeftHand (XRController3D)     tracker = "left_hand"
│   └── ControllerMesh (MeshInstance3D, SphereMesh r=0.04)  ← debug visual
└── RightHand (XRController3D)    tracker = "right_hand"
    └── ControllerMesh (MeshInstance3D, SphereMesh r=0.04)  ← debug visual
```

**Exports (Inspector-adjustable):**
```gdscript
@export var move_speed: float = 1.2        # m/s
@export var rotation_enabled: bool = true  # thumbstick X → rotation
@export var rotation_speed: float = 60.0   # deg/s
```

**Button mapping (beide Controller identisch):**
| Button | Action | Bedingung |
|--------|--------|-----------|
| Beliebiger Button | `SceneManager.activate_standalone()` | nur wenn nicht bereits aktiv |
| `by_button` (B/Y) | `SceneManager.advance_scene()` | immer (aktiviert Standalone vorher falls nötig) |

**Button handler:**
```gdscript
func _on_button(button_name: String) -> void:
    if not SceneManager.standalone_mode:
        SceneManager.activate_standalone()
    if button_name == "by_button":
        SceneManager.advance_scene()
```
Note: name-agnostic approach for standalone activation ensures compatibility across
OpenXR profiles — the specific button name depends on which interaction profile the
runtime activates. `by_button` is the action name for B (right) / Y (left) buttons.

**Locomotion:**
```gdscript
# Beide Controller: "max-Betrag gewinnt" — unabhängige Inputs, kein Konflikt
var fwd:  float = _stick_l.y if abs(_stick_l.y) >= abs(_stick_r.y) else _stick_r.y
var turn: float = _stick_l.x if abs(_stick_l.x) >= abs(_stick_r.x) else _stick_r.x

# Bewegung: Kamera-Forward-Vektor (Y=0, normiert) × fwd × move_speed × delta
# Rotation: rotate_y(deg_to_rad(-turn * rotation_speed * delta))
```

**Boundary (`_clamp_to_walk_area()`):**
Reads `XRWalkArea` node from `SYSTEM/main.tscn` (PlaneMesh, single point of truth).
Clamps `global_position.x` and `.z` to the plane's half-extents around its center.
Safe if node is missing or mesh is wrong type — silently skips.

**Position broadcast:**
```gdscript
# body_pos = camera XZ projected onto XROrigin Y (floor height)
# Avatar follows physical head movement, not frozen XROrigin spawn point
var body_floor := Vector3(cam.global_position.x, global_position.y, cam.global_position.z)
NetworkManager.send_player_state(body_floor, cam.global_position, cam.global_rotation)
```

**`_ready()`** calls `$XRCamera3D.make_current()` — makes XRCamera3D the active viewport camera.
Without this, `ServerCamera` (current=true in team_scene.tscn) remains active →
OpenXR compositor sees wrong frames → gray viewport on Focus 3/Vision.

---

### `SYSTEM/openxr_action_map.tres`

**Purpose:** Defines all OpenXR actions and hardware bindings. Loaded via `project.godot → [xr] openxr/action_map`.

**Actions defined:**
| Action | Type | Used for |
|--------|------|---------|
| `trigger` | Float | — |
| `trigger_click` | Bool | — |
| `grip` / `grip_click` / `grip_force` | Float/Bool | — |
| `primary` | Vector2 | **Thumbstick locomotion** (both controllers) |
| `primary_click` | Bool | Thumbstick click |
| `secondary` | Vector2 | Secondary thumbstick (unused) |
| `menu_button` / `select_button` | Bool | khr profile fallback |
| `ax_button` | Bool | **A (right) / X (left) face buttons** |
| `by_button` | Bool | **B (right) / Y (left) face buttons** |
| `default_pose` / `aim_pose` / `grip_pose` / `palm_pose` | Pose | Controller tracking |
| `haptic` | Haptic | Vibration |

**Interaction profiles active:**
```
/interaction_profiles/khr/simple_controller    ← universal fallback (poses, select, menu, haptic)
/interaction_profiles/oculus/touch_controller  ← Meta Quest 2/3/Pro
/interaction_profiles/htc/vive_focus3_controller ← HTC Focus 3 + Focus Vision
```

**Critical note — project.godot:**
```ini
[xr]
openxr/action_map="res://SYSTEM/openxr_action_map.tres"
```
Without this line, Godot never submits the action map to the OpenXR runtime.
All button and thumbstick inputs are silently ignored. **Do not remove.**

---

### `_scenes/team_template/net_info_board.gd`

**Purpose:** Connection status Label3D, spawned at runtime by `SceneManager._spawn_net_info_board()` into every team scene. Not part of any .tscn file.

**Visibility logic:**
```gdscript
func _update() -> void:
    if NetworkManager.client_connected_flag or SceneManager.standalone_mode:
        visible = false   # connected OR standalone → hide board
        return
    visible = true
    # shows: "Keine Verbindung", server IP, reconnect attempt count
```

**Position in scene:** `Vector3(1.6, 1.5, 2.5)` — right side, head height, back of room.
Billboard mode: always faces camera.
Color: orange `Color(1.0, 0.45, 0.1)` for visibility in dark rooms.

---

### `SYSTEM/player/fps_player.gd` + `fps_player.tscn`

**Purpose:** Desktop FPS controller. Sends position to server.

**Scene tree:**
```
FPSPlayer (CharacterBody3D, fps_player.gd)
├── CollisionShape3D (CapsuleShape3D r=0.3, h=1.8)
└── Head (Node3D @ y=1.6)
    └── Camera3D
```

**Controls:**
| Input | Action |
|-------|--------|
| WASD | Move (4.0 m/s) |
| Mouse | Look (sensitivity 0.003) |
| Space | Jump (velocity 4.5) |
| Escape | Release mouse capture |

---

### Avatar System

#### Interface contract for all avatars

Any scene used as a remote avatar **must** implement:
```gdscript
var peer_id: int
func update_transform(body_pos: Vector3, head_pos: Vector3, head_rot: Vector3) -> void
```

Optional (enables first-person self-body view):
```gdscript
func set_self_mode(enabled: bool) -> void
```

SceneManager checks `has_method("set_self_mode")` before calling it.

#### `SYSTEM/avatar/variants/avatar_dynamic_cone.gd` (Default)

Procedural stacked torus rings avatar.

**Exports:**
```gdscript
num_rings:      int   = 8       # number of torus rings
base_diameter:  float = 1.2     # widest ring (bottom) in meters
top_diameter:   float = 0.2     # narrowest ring (below head)
head_diameter:  float = 0.25    # head sphere diameter
tube_diameter:  float = 0.049   # torus tube thickness
damping_bottom: float = 0.8     # responsiveness at t=0 (1/sec)
damping_mid:    float = 1.8     # responsiveness at t=0.5 (1/sec)
damping_top:    float = 12.0    # responsiveness at t=1 (1/sec)
```

**Damping formula** (quadratic 3-point interpolation, passes exactly through all three values):
```gdscript
qa = 2*(damping_top + damping_bottom - 2*damping_mid)
qb = 4*damping_mid - 3*damping_bottom - damping_top
responsiveness(t) = qa*t² + qb*t + damping_bottom
smooth = 1.0 - exp(-responsiveness * delta)
```

#### Avatar Variants Summary
| File | Shape | set_self_mode |
|------|-------|---------------|
| `remote_avatar.tscn` | CapsuleMesh + SphereMesh | ✗ |
| `avatar_capsule.tscn` | CapsuleMesh + SphereMesh | ✗ |
| `avatar_box.tscn` | BoxMesh + SphereMesh | ✗ |
| `avatar_sphere.tscn` | Single SphereMesh | ✗ |
| `avatar_ghost.tscn` | Transparent spheres | ✗ |
| `avatar_dynamic_cone.tscn` | Procedural tori | ✓ **Default** |

---

### `_scenes/scene_registry.gd`

**Purpose:** Ordered list of scene folder paths. **Only Dev Team edits this file.**

**Format:**
```gdscript
func get_scenes() -> Array:
  return [
    "res://_scenes/team_a/",
    "res://_scenes/team_b/",
    # "res://_scenes/team_c/",  # commented out = disabled
  ]
```

---

### `_scenes/team_X/scene_info.cfg`

**Format (Godot ConfigFile):**
```ini
[scene]
name       = "Team A – Titel der Installation"
duration   = 120.0          ; seconds; -1.0 = no auto-advance
scene_file = "team_a.tscn"  ; required
team       = "Team A"       ; optional: shown in fade overlay
info       = "Kurzbeschreibung"
avatar     = "res://SYSTEM/avatar/variants/..."    ; optional: default = avatar_dynamic_cone.tscn
player_color = Color(1.0, 1.0, 1.0, 1)    ; optional: forces all players to one color
```

---

## COLLISION LAYERS

| Layer | Name | Used by |
|-------|------|---------|
| 1 | world | Floor, static geometry |
| 2 | players | FPS/XR player (local) |
| 4 | avatars | Remote avatars, InteractionZone detection |

---

## HARDWARE TARGETS

### HTC Vive Focus Vision (Primäres Headset)
- HTC Focus Vision = Nachfolger des Focus 3 (identisches controller layout)
- Plugin: `godotopenxrvendors` (Khronos/HTC vendor)
- Interaction profile: `/interaction_profiles/htc/vive_focus3_controller`
- Export preset: "Android – HTC Focus 3" (gleiche APK)
- Render scale: 0.6× (set at runtime in main.gd for "focus" or "vive" in model name)
- shader_baker: `true` — eliminates per-scene shader compilation hitching
- Controller layout: Left (X/Y/thumbstick/trigger/grip), Right (A/B/thumbstick/trigger/grip)

### HTC Focus 3
- Identisch zu Focus Vision für dieses Projekt
- Gleiche APK, gleiche Interaction Profile

### Meta Quest (2 / 3 / Pro)
- Plugin: `godot_meta_toolkit` + `godotopenxrvendors`
- Interaction profile: `/interaction_profiles/oculus/touch_controller`
- Export preset: "Android – Meta Quest"
- APK: `Hyper-Irrealismus-III-Quest.apk`

### Desktop (PC — Server or FPS client)
- Standard Godot Windows/Linux export
- No XR hardware required
- FPS mode: WASD + mouse
- VRS disabled programmatically at startup

---

## PROJECT SETTINGS (project.godot)

```ini
[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
textures/vram_compression/import_etc2_astc=true
anti_aliasing/quality/msaa_3d=1                        # 2× MSAA
vrs/mode=2                                             # VRS_XR — CRITICAL:
                                                       # overridden to VRS_DISABLED for PC in main.gd

[xr]
openxr/enabled=true
openxr/form_factor=0
openxr/view_configuration=1
openxr/reference_space=1
openxr/foveation_level=2
shaders/enabled=true
openxr/action_map="res://SYSTEM/openxr_action_map.tres" # CRITICAL: without this, no button/stick input
openxr/extensions/meta/color_space/starting_color_space=3
```

---

## KNOWN ISSUES / OPEN ITEMS

```yaml
pending:
  - id: left-controller-by-button
    description: >
      On HTC Focus Vision, B/Y button (by_button) sometimes only fires from right controller.
      Root cause unknown — may be interaction profile matching, tracker state, or device-specific.
      Workaround: button handler is name-agnostic for standalone activation; by_button for scene advance.
      Status: needs device testing with adb logcat to confirm action names on left controller.

  - id: vr-fade-overlay-headset-untested
    description: >
      VR scene transition overlay (3D QuadMesh + Label3D, 2m distance, lazy-follow).
      Confirmed working in editor. Not verified on physical headset.
    status: needs APK rebuild + headset test

  - id: shadow-quality-untested
    description: >
      shadow_blur=2.5 + SHADOW_PARALLEL_2_SPLITS (runtime, Focus only) +
      directional_shadow atlas size.mobile=4096 + soft_shadow_filter_quality.mobile=2.
      If perf degrades: reduce atlas to 2048. If pixelated: increase blur.
    status: needs headset test
```

---

## EXTENSION GUIDE

### Adding a new team scene
1. Duplicate `_scenes/team_template/` → `_scenes/team_yourname/`
2. Edit `_scenes/team_yourname/scene_info.cfg`
3. Add folder path to `_scenes/scene_registry.gd`

### Adding a new avatar variant
1. Create `SYSTEM/avatar/variants/avatar_yourname.gd` extending `CharacterBody3D`
2. Implement: `var peer_id: int` + `func update_transform(body_pos, head_pos, head_rot)`
3. Optionally: `func set_self_mode(enabled: bool)`
4. Create `avatar_yourname.tscn` with `CollisionShape3D` (layer=4, mask=0)
5. Reference in scene_registry entry via `"avatar":` key

---

## DEPENDENCY GRAPH

```
main.gd
 ├── GameState (Autoload)
 ├── NetworkManager (Autoload)
 │    └── GameState
 └── SceneManager (Autoload)
      ├── GameState
      ├── NetworkManager
      ├── scene_registry.gd (loaded at runtime)
      ├── SYSTEM/player/fps_player.tscn / xr_player.tscn
      └── SYSTEM/avatar/*.tscn (per scene, from registry)

xr_player.gd
 └── SceneManager (standalone_mode, activate_standalone, advance_scene)

net_info_board.gd (injected at runtime, not in tscn)
 ├── NetworkManager (client_connected_flag)
 └── SceneManager (standalone_mode)

team_scene.gd
 ├── SceneManager (for solo test detection)
 └── fps_player.tscn (spawned in solo mode only)
```

---

## CHANGELOG

| Date | Change | Files |
|------|--------|-------|
| 2026-07-30 | Standalone-Modus: XR-Client läuft ohne Server — Timer + Szenen laufen autonom durch; aktiviert via beliebigem Controller-Button | `scene_manager.gd` |
| 2026-07-30 | xr_player: Thumbstick-Locomotion (beide Controller, max-Betrag, 1.2 m/s, bounded zu XRWalkArea); Rotation via X-Achse (60°/s, aktiviert) | `player/xr_player.gd` |
| 2026-07-30 | xr_player: LeftHand + RightHand XRController3D hinzugefügt; button_pressed + input_vector2_changed auf beiden verbunden; SphereMesh Debug-Visuals | `player/xr_player.tscn`, `player/xr_player.gd` |
| 2026-07-30 | xr_player Button-Mapping: beliebiger Button → standalone; by_button (B/Y) → nächste Szene; beide Controller identisch | `player/xr_player.gd` |
| 2026-07-30 | openxr_action_map: Quest-Profil + Focus3/Vision-Profil hinzugefügt (ax_button, by_button, primary thumbstick, poses, haptic, trigger, grip/squeeze) | `openxr_action_map.tres` |
| 2026-07-30 | project.godot: openxr/action_map="res://openxr_action_map.tres" hinzugefügt — ohne diesen Eintrag ignoriert Godot die Action Map komplett | `project.godot` |
| 2026-07-30 | main.tscn: XRWalkArea (MeshInstance3D, PlaneMesh 3.5×6m, visible=false) als single point of truth für Locomotion-Grenzen | `main.tscn` |
| 2026-07-30 | net_info_board: Board verschwindet wenn standalone_mode=true (nicht erst bei echter Serververbindung) | `_scenes/team_template/net_info_board.gd` |
| 2026-07-30 | advance_scene(): _timer=0.0 direkt im Aufruf — verhindert wiederholtes Emittieren von scene_about_to_change in jedem Frame während des Fade-Outs | `scene_manager.gd` |
| 2026-05-07 | cam_dolly.gd: CamDolly-Node rotiert ServerCamera um Y-Achse (2°/s); ServerCamera-Transform angepasst | `cam_dolly.gd`, `main.tscn` |
| 2026-05-07 | scene registry: steflie + Pia Liv integriert (gesamt 4 Team-Szenen aktiv) | `_scenes/scene_registry.gd` |
| 2026-05-07 | scene registry: Milena_Elizabeth hinzugefügt | `_scenes/scene_registry.gd` |
| 2026-05-06 | server_ip Fallback auf 192.168.50.172 aktualisiert | `networking/network_manager.gd` |
| 2026-05-06 | fix: Gradle daemon + caching deaktiviert — verhindert Einbetten veralteter PCK in APK | `android/build/gradle.properties` |
| 2026-05-06 | fix: *.cfg in export include_filter — scene_info.cfg fehlte in APK-PCK | `export_presets.cfg.template` |
| 2026-05-06 | fix: xr_player _ready() mit XRCamera3D.make_current() | `player/xr_player.gd` |
| 2026-04-29 | fix: xr_player.gd _ready() entfernt redundanten viewport.use_xr=true | `player/xr_player.gd` |
| 2026-04-28 | triggers/ → _deprecated/triggers/; design_teams.md restructured | multiple |
| 2026-04-27 | Folder cleanup: scenes/ → _scenes/, docs split into _anleitungen/ | multiple |
| 2026-04-27 | scene_info.cfg per team folder; registry now path-list only | multiple |
| 2026-04-27 | Default avatar → avatar_dynamic_cone.tscn | `scene_manager.gd` |
| 2026-04-27 | Renderer: Forward Plus → GL Compatibility | `project.godot` |
| 2026-04-27 | VR fade overlay: CanvasLayer → 3D QuadMesh + Label3D | `main.gd` |
| 2026-04-27 | Focus 3 render_target_size_multiplier → 0.6 | `main.gd` |
| 2026-04-27 | _soften_shadows: shadow_blur=2.5 + SHADOW_PARALLEL_2_SPLITS for Focus 3 | `scene_manager.gd` |
| 2026-04-24 | 3D-Verbindungsstatusanzeige (Label3D, Billboard) | `net_info_board.gd`, `scene_manager.gd` |
| 2026-04-24 | Reconnect-Logik: ENet-Client alle 5s (dauerhaft) | `network_manager.gd` |
| 2026-04-03 | Network diagnostics overlay (Tab toggle) | `main.gd` |
| 2026-04-03 | Server-authoritative avatar colors + scene-level player_color override | multiple |
| 2026-04-03 | Fade-to-black transition with scene title overlay | multiple |
| 2026-04-02 | Fix HTC foveation artifacts + PC black screen | `project.godot` |
| 2026-04-02 | Add DynamicCone avatar (tori, quadratic damping, set_self_mode) | `avatar_dynamic_cone.gd/.tscn` |
| 2026-04-02 | Add self-body FP view (self_avatar in SceneManager) | `scene_manager.gd` |
| 2026-03-31 | Fix FPS camera, player-avatar collision, double scene load | `fps_player.gd`, `scene_manager.gd` |
