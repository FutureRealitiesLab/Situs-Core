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
last_updated:  2026-05-06
last_commit:   (pending)  "fix: xr_player – XRCamera3D.make_current() in _ready()"
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
│  │  (Godot     │               │  • Meta Quest 2/3/Pro (XR)        │  │
│  │  SERVER     │               │  • HTC Focus 3 (XR)               │  │
│  │  mode)      │               │  • Desktop PC (FPS, optional)     │  │
│  │             │               └──────────────────────────────────┘  │
│  │  Shows all  │                                                      │
│  │  avatars    │  LAN Router (isolated network, no internet needed)  │
│  └─────────────┘                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Scene Lifecycle
```
Server Timer expires / N key / Button
		 │
		 ▼
SceneManager.advance_scene()
	├── _load_scene_local(next_index)      ← server
	└── _rpc_change_scene.rpc(next_index) ← all clients
			  │
			  ▼
		 _load_scene_local(index)
			  ├── free old scene
			  ├── free local_player + self_avatar
			  ├── instantiate new scene → SceneContainer
			  ├── spawn local player (FPS or XR)
			  ├── spawn self_avatar (if avatar supports set_self_mode)
			  ├── _soften_shadows(scene_root)  ← Focus 3 only
			  └── respawn all remote avatars (new avatar variant)
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
| `main.gd` | Root node: menu, mode selection, HUD, VR fade overlay | ~330 |
| `main.tscn` | Root scene: containers, HUD, cameras | — |
| `scene_manager.gd` | **Autoload**: scene loader, scene_info.cfg reader, avatar manager, timer, shadow softening | ~470 |
| `networking/game_state.gd` | **Autoload**: mode, peer IDs, colors | 44 |
| `networking/network_manager.gd` | **Autoload**: ENet relay, RPC chain | 183 |
| `player/fps_player.gd` | FPS camera+movement controller | 92 |
| `player/fps_player.tscn` | FPS player scene | — |
| `player/xr_player.gd` | OpenXR tracking controller (physical locomotion) | ~60 |
| `player/xr_player.tscn` | XR player scene | — |
| `avatar/remote_avatar.gd` | Base remote avatar: interpolation, color | 66 |
| `avatar/remote_avatar.tscn` | Legacy capsule+sphere avatar | — |
| `avatar/variants/avatar_dynamic_cone.gd` | DynamicCone avatar script | ~196 |
| `avatar/variants/avatar_dynamic_cone.tscn` | DynamicCone scene | — |
| `avatar/variants/avatar_box.tscn` | Box avatar variant | — |
| `avatar/variants/avatar_capsule.tscn` | Capsule avatar variant | — |
| `avatar/variants/avatar_sphere.tscn` | Sphere avatar variant | — |
| `avatar/variants/avatar_ghost.tscn` | Ghost avatar variant | — |
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

---

## MODULE SPECIFICATIONS

### `main.gd` + `main.tscn`

**Purpose:** Persistent root. Always loaded. Manages startup flow, contains all containers, VR fade overlay.

**Scene tree:**
```
Main (Node, main.gd)
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
const FADE_OUT_DURATION: float = 0.5
const TEXT_HOLD_DURATION: float = 2.0
const FADE_IN_DURATION:   float = 0.5
const VR_OVERLAY_DIST:    float = 2.0   # meters in front of camera
const VR_OVERLAY_SPEED:   float = 4.0   # lazy-follow 1/s
```

**Key functions:**
- `_ready()` — detects XR: sets VRS_XR + render_scale 0.6 (Focus 3) OR VRS_DISABLED (PC)
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

### `scene_manager.gd` (Autoload: SceneManager)

**Purpose:** Central coordinator. Manages scene lifecycle, player spawning, avatar management, timer, and shadow softening for Focus 3.

**Public API:**
```gdscript
SceneManager.initialize(scene_container, players_container)  # called by main.gd
SceneManager.start()                                          # called by main.gd after initialize
SceneManager.advance_scene()                                  # server: go to next scene (triggers fade)
SceneManager.go_to_scene(index: int)                          # server: jump to specific scene (triggers fade)
SceneManager.confirm_scene_load(index: int)                   # called by main.gd after fade-out
SceneManager.current_index        # int: index of loaded scene
SceneManager.scenes_list          # Array of scene dicts from registry
SceneManager.local_player         # Node: local FPS or XR player
SceneManager.remote_avatars       # Dictionary: peer_id → avatar Node
SceneManager.self_avatar          # Node: own body avatar (FP view)
```

**Signals:**
```gdscript
signal scene_about_to_change(index: int)            # fires before swap → triggers fade
signal scene_changed(index: int, scene_name: String) # fires after swap
signal timer_tick(remaining: float, total: float)
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

**Shadow softening (Focus 3 only):**
```gdscript
func _soften_shadows(scene_root: Node) -> void:
	# Called in _load_scene_local() only when _is_focus3() is true.
	# GL Compat + render_scale 0.6 → pixelated shadows without blur.
	for light in scene_root.find_children("*", "DirectionalLight3D", true, false):
		d.shadow_blur = 2.5
		d.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	# OmniLight3D and SpotLight3D: shadow_blur = 2.0
```

Note: `_disable_shadows()` is still present in code but no longer called.
If Focus 3 performance degrades, can re-enable by calling it in `_load_scene_local()`.

**Avatar selection priority:**
1. `scenes_list[current_index]["avatar"]` if set and valid
2. Default from `_load_scene_info()`: `res://avatar/variants/avatar_dynamic_cone.tscn`

---

### `networking/game_state.gd` (Autoload: GameState)

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

```gdscript
GameState.set_color_for_id(peer_id, color)  # explicit assignment (server → RPC → clients)
GameState.get_color_for_id(peer_id)         # lookup (fallback: local round-robin)
```

---

### `networking/network_manager.gd` (Autoload: NetworkManager)

**Purpose:** ENet transport layer. Relay-only server (no game logic on server side, only relay + avatar update).

**Constants:**
```gdscript
PORT = 7777
MAX_CLIENTS = 8
```

**Server IP resolution** (priority order):
1. `res://server_ip.txt` (if valid IPv4) — gitignored, each machine sets own
2. Hardcoded fallback: `"192.168.1.100"`

**Public API:**
```gdscript
NetworkManager.start_server()                               # called by main.gd in SERVER mode
NetworkManager.start_client()                               # called by main.gd in XR/FPS mode
NetworkManager.send_player_state(body, head_pos, head_rot)  # called by player scripts ~20Hz
```

**Signals:**
```gdscript
signal player_joined(peer_id: int)
signal player_left(peer_id: int)
signal client_connected()
```

**Reconnect behavior:** ENet client retries connection every 5s indefinitely.
`client_disconnected` signal triggers cleanup of remote avatars for that peer.

**RPC chain:**
```
Client                  Server                  Other Clients
  │                       │                          │
  ├─_server_receive_state─►│                          │
  │  (any_peer,            ├─update server avatar     │
  │   unreliable_ordered)  ├─_client_receive_state───►│
  │                        │  (authority,              │
  │                        │   unreliable_ordered)     │
```

---

### `player/fps_player.gd` + `fps_player.tscn`

**Purpose:** Desktop FPS controller. Sends position to server.

**Scene tree:**
```
FPSPlayer (CharacterBody3D, fps_player.gd)
├── CollisionShape3D (CapsuleShape3D r=0.3, h=1.8)
└── Head (Node3D @ y=1.6)
	└── Camera3D
```

**Physics layers:**
- `collision_layer = 2` (layer "players")
- `collision_mask = 1` (layer "world" only — ignores avatars)

**Controls:**
| Input | Action |
|-------|--------|
| WASD | Move (4.0 m/s) |
| Mouse | Look (sensitivity 0.003) |
| Space | Jump (velocity 4.5) |
| Escape | Release mouse capture |

**Network:** calls `NetworkManager.send_player_state()` every 0.05s

---

### `player/xr_player.gd` + `xr_player.tscn`

**Purpose:** OpenXR headset tracking. No artificial locomotion — movement is physical only.

**Scene tree:**
```
XRPlayer (XROrigin3D, xr_player.gd)
├── XRCamera3D          ← head tracking (auto by OpenXR)
├── LeftHand (XRController3D)
└── RightHand (XRController3D)
```

**`_ready()`** calls `$XRCamera3D.make_current()` — macht XRCamera3D zur aktiven Viewport-Kamera.
Analog zu `fps_player.gd`'s `camera.current = true`. Ohne diesen Aufruf bleibt
`ServerCamera` (current=true in team_scene.tscn) aktiv → OpenXR-Compositor sieht
falsche Frames → grauer Viewport auf Focus 3.

**Sends:** `NetworkManager.send_player_state()` every 0.05s
```gdscript
# XROrigin stays at spawn point for physical locomotion.
# body_pos = head XZ projected onto floor Y — avatar follows physical movement.
var body_floor := Vector3(cam.global_position.x, global_position.y, cam.global_position.z)
NetworkManager.send_player_state(body_floor, cam.global_position, cam.global_rotation)
```

**Important:** `body_pos` must use camera XZ (not XROrigin XZ). Otherwise the avatar base
stays frozen at the spawn point while the head moves, stretching the rings.

---

### Avatar System

#### Interface contract for all avatars

Any scene used as a remote avatar **must** implement:
```gdscript
var peer_id: int        # set before add_child() by SceneManager
func update_transform(body_pos: Vector3, head_pos: Vector3, head_rot: Vector3) -> void
```

Optional (enables first-person self-body view):
```gdscript
func set_self_mode(enabled: bool) -> void
# When true: hide head sphere, set collision_layer = 0
```

SceneManager checks `has_method("set_self_mode")` before calling it.

#### `avatar/remote_avatar.gd` (base/default)

- CapsuleMesh body + SphereMesh head
- Smooth interpolation: lerp factor 0.25
- Color from `GameState.get_color_for_id(peer_id)`
- Physics: `collision_layer = 4` (avatars), `collision_mask = 0`
- Does **not** implement `set_self_mode` → no FP self-body for this avatar

#### `avatar/variants/avatar_dynamic_cone.gd`

Procedural stacked torus rings avatar.

**Exports (inspector-adjustable):**
```gdscript
num_rings:      int   = 8       # number of torus rings
base_diameter:  float = 1.2     # widest ring (bottom) in meters
top_diameter:   float = 0.2     # narrowest ring (below head) in meters
head_diameter:  float = 0.25    # head sphere diameter
tube_diameter:  float = 0.049   # torus tube thickness (was 0.07, -30% 2026-04-27)
tube_segments:  int   = 12      # tube cross-section detail
base_y_offset:  float = 0.05    # bottom ring lift from ground
top_ring_gap:   float = 0.05    # gap between top ring and head sphere (added 2026-04-27)
damping_bottom: float = 0.8     # responsiveness at t=0 (1/sec) — was 1.5, more organic lag
damping_mid:    float = 1.8     # responsiveness at t=0.5 (1/sec) — was 2.5
damping_top:    float = 12.0    # responsiveness at t=1 (1/sec)
```

**Ring distribution:**
```gdscript
var ring_top = head_pos - Vector3(0.0, top_ring_gap, 0.0)
# t = float(i) / float(num_rings)  → top ring at (N-1)/N, one step below gap
_ring_pos_tgt[i] = base.lerp(ring_top, t)
```

**Damping formula** (quadratic 3-point interpolation):
```gdscript
qa = 2*(damping_top + damping_bottom - 2*damping_mid)
qb = 4*damping_mid - 3*damping_bottom - damping_top
responsiveness(t) = qa*t² + qb*t + damping_bottom
smooth = 1.0 - exp(-responsiveness * delta)
```
Passes exactly through all three control values at t=0, 0.5, 1.

**First-frame guard:** `_process` skips until first `update_transform()` call → prevents rings from appearing at world origin (0,0,0).

**`set_self_mode(true)`:** hides head sphere, sets `collision_layer = 0`.

#### Avatar Variants Summary
| File | Shape | set_self_mode | Notes |
|------|-------|---------------|-------|
| `remote_avatar.tscn` | CapsuleMesh + SphereMesh | ✗ | Legacy (not default) |
| `avatar_capsule.tscn` | CapsuleMesh + SphereMesh | ✗ | Humanoid |
| `avatar_box.tscn` | BoxMesh + SphereMesh | ✗ | Cubic |
| `avatar_sphere.tscn` | Single SphereMesh | ✗ | Minimal |
| `avatar_ghost.tscn` | Transparent spheres | ✗ | Ghostly |
| `avatar_dynamic_cone.tscn` | Procedural tori | ✓ | **Default**; full FP self-body |

---

### `_scenes/scene_registry.gd`

**Purpose:** Ordered list of scene folder paths. **Only Dev Team edits this file.**
Metadata (name, duration, avatar, …) lives in each team's `scene_info.cfg` — no merge conflicts.

**Format:**
```gdscript
func get_scenes() -> Array:
  return [
    "res://_scenes/team_a/",   # Dev Team controls order here
    "res://_scenes/team_b/",
    # "res://_scenes/team_c/",  # commented out = disabled
  ]
```

`SceneManager.initialize()` calls `_load_scene_info(folder_path)` for each entry and builds `scenes_list`.

**Current state (2026-04-27):** Three placeholder entries; Design Team scenes added by Dev Team before exhibition.

---

### `_scenes/team_X/scene_info.cfg`

**Purpose:** Per-team metadata file. Each Design Team only edits their own. No shared file → no merge conflicts.

**Format (Godot ConfigFile):**
```ini
[scene]
name       = "Team A – Titel der Installation"  ; shown in ServerHUD + fade overlay
duration   = 120.0                               ; seconds; -1.0 = no auto-advance
scene_file = "team_a.tscn"                      ; filename, relative to this folder (required)
team       = "Team A"                            ; optional: shown in fade overlay
info       = "Kurzbeschreibung"                  ; optional: shown in fade overlay
avatar     = "res://avatar/variants/..."         ; optional: default = avatar_dynamic_cone.tscn
player_color = Color(1.0, 1.0, 1.0, 1)          ; optional: forces all players to one color
                                                 ;  not set = individual colors from 8-slot palette
```

**Required field:** `scene_file` — loader returns empty dict and logs error if missing.
**Default avatar:** `res://avatar/variants/avatar_dynamic_cone.tscn` (if `avatar` not set).
**player_color not set** → each player keeps their server-assigned color from the 8-color palette.

**Files:** `_scenes/team_template/scene_info.cfg` (Design Team template), `_scenes/placeholder_b/scene_info.cfg`, `_scenes/placeholder_c/scene_info.cfg`

---

### `_scenes/team_template/team_scene.gd` + `team_scene.tscn`

**Purpose:** Base template for Design Teams. Duplicate the entire `team_template/` folder per team.

**Scene tree:**
```
TeamScene (Node3D, team_scene.gd)
├── WorldEnvironment
├── DirectionalLight3D
├── Floor (StaticBody3D)
│   ├── MeshInstance3D (PlaneMesh 20×20m)
│   └── CollisionShape3D (BoxShape 20×0.1×20m)
├── ServerCamera (Camera3D, current=true, fov=65)
│   position set by code: Vector3(0,5,5), look_at(Vector3(0,0.5,0))
├── ---------- (separator Node)
└── [team content here]
```

**Solo test mode** (F6 — no multiplayer):
- Detected by: `SceneManager.scenes_list.is_empty()`
- Action: spawns local FPSPlayer at origin for rapid testing
- No network required

**Multiplayer mode** (F5 — or via server):
- Player spawned by SceneManager (not team_scene.gd)
- `ServerCamera` used by server viewport (positioned by look_at in `_ready`)

---

### `triggers/interaction_zone.gd` + `interaction_zone.tscn`

**Purpose:** Reusable Area3D trigger that responds to remote avatars entering/leaving.

**Scene tree:**
```
InteractionZone (Area3D, interaction_zone.gd)
└── CollisionShape3D (BoxShape3D 2×2.5×2m)
```

**Collision mask:** layer 4 (avatars only). Ignores local player.
**Group filter:** only nodes in group `"remote_avatars"` trigger callbacks.

**Override in subclass:**
```gdscript
func _on_avatar_entered(avatar: Node3D) -> void: pass
func _on_avatar_exited(avatar: Node3D) -> void: pass
```

**Helpers:**
```gdscript
has_avatars() -> bool
get_avatar_count() -> int
get_avatars() -> Array[Node3D]
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

### Meta Quest (2 / 3 / Pro)
- Plugin: `godot_meta_toolkit` + `godotopenxrvendors`
- Export preset: "Android – Meta Quest"
- Gradle build: **not required** (Meta plugin works without)
- APK: `Hyper-Irrealismus-III-Quest.apk`
- Performance advantage: App Space Warp (ASW), Fixed Foveated Rendering (FFR), Meta driver optimizations
- shader_baker: `false` (Meta runtime has own aggressive shader caching)

### HTC Focus 3
- Plugin: `godotopenxrvendors` (Khronos/HTC vendor)
- Export preset: "Android – HTC Focus 3"
- Gradle build: **required** (for custom AndroidManifest.xml)
- Required manifest entry: `android.hardware.vr.headtracking` feature
- APK: `Hyper-Irrealismus-III-Focus3.apk`
- Render scale: 0.6× (set at runtime in main.gd for Focus/Vive devices)
- shader_baker: `true` in export_presets.cfg.template — bakes shaders into APK, eliminates per-scene compilation hitching
- Performance mode tip: use GL Compatibility renderer + render_scale 0.6 + shadow_blur (no Meta Toolkit equivalent)

### Desktop (PC — Server or FPS client)
- Standard Godot Windows/Linux export
- No XR hardware required
- FPS mode: WASD + mouse
- VRS disabled programmatically at startup (project.godot vrs/mode=2 would cause black screen)

---

## PROJECT SETTINGS (project.godot)

```ini
[rendering]
renderer/rendering_method="gl_compatibility"          # switched from Forward Plus 2026-04-27
renderer/rendering_method.mobile="gl_compatibility"   # explicit mobile path
textures/vram_compression/import_etc2_astc=true        # required for Android
anti_aliasing/quality/msaa_3d=1                        # 2× MSAA (re-enabled with GL Compat)
vrs/mode=2                                             # VRS_XR in project — CRITICAL:
													   # overridden to VRS_DISABLED for PC in main.gd
lights_and_shadows/directional_shadow/size.mobile=4096              # atlas (was 2048) — untested on headset
lights_and_shadows/directional_shadow/soft_shadow_filter_quality.mobile=2  # medium filter quality

[xr]
openxr/enabled=true
openxr/form_factor=0                         # head-mounted
openxr/view_configuration=1                  # stereo
openxr/reference_space=1                     # local (room-scale)
openxr/foveation_level=1                     # Low foveation (0=off, 1=low, 2=medium, 3=high)
shaders/enabled=true
openxr/extensions/meta/color_space/starting_color_space=3
```

### Foveation level guide (Focus 3)
| Level | Effect | Recommendation |
|-------|--------|----------------|
| 0 | Off | Full quality, highest GPU cost |
| 1 (Low) | Slight reduction at periphery, barely visible | **Current setting** |
| 2 (Medium) | Noticeable fovea rectangle if you look for it, ~10-15% GPU gain | Try next |
| 3 (High) | Obvious rectangle artifact, most gain | Avoid unless needed |

---

## KNOWN ISSUES / OPEN ITEMS

```yaml
pending:
  - id: student-scenes-missing
	description: >
	  scene_registry.gd still shows placeholder only.
	  Student teams must add their scenes before exhibition.
	status: waiting on student teams

  - id: foveation-medium-untested
	description: >
	  openxr/foveation_level=2 (Medium) not yet tested on Focus 3.
	  Expected: ~10-15% GPU gain, minor visible rectangle at periphery.
	status: ready to test — change value in project.godot and rebuild APK

  - id: vr-fade-overlay-2m-untested
	description: >
	  VR scene transition overlay moved to 3D (QuadMesh + Label3D) at 2.0m distance.
	  Fixed for PC. Not yet verified in actual headset.
	status: needs APK rebuild + headset test

  - id: shadow-quality-untested
	description: >
	  shadow_blur=2.5 + SHADOW_PARALLEL_2_SPLITS (runtime, Focus 3 only) +
	  directional_shadow atlas size.mobile=4096 + soft_shadow_filter_quality.mobile=2.
	  Combination untested on headset. If perf degrades: reduce atlas to 2048.
	  If still pixelated: increase blur; if too soft: reduce blur.
	status: needs APK rebuild + headset test

  - id: shader-baker-focus3
	description: >
	  shader_baker=true set in export_presets.cfg.template (Focus 3 preset only).
	  Eliminates per-scene compilation hitching on first frame.
	status: needs APK rebuild to take effect
```

---

## EXTENSION GUIDE

### Adding a new team scene
1. Duplicate `_scenes/team_template/` → `_scenes/team_yourname/`
2. Rename `.gd` and `.tscn` files appropriately
3. Edit `_scenes/team_yourname/scene_info.cfg`:
   ```ini
   [scene]
   name       = "Team X – Title"
   duration   = 120.0
   scene_file = "team_yourname.tscn"
   team       = "Team X"
   ```
4. Add folder path to `_scenes/scene_registry.gd`:
   ```gdscript
   "res://_scenes/team_yourname/",
   ```

### Adding a new avatar variant
1. Create `avatar/variants/avatar_yourname.gd` extending `CharacterBody3D`
2. Implement required interface:
   ```gdscript
   var peer_id: int
   func update_transform(body_pos, head_pos, head_rot): ...
   ```
3. Optionally implement: `func set_self_mode(enabled: bool): ...`
4. Create `avatar_yourname.tscn` with `CollisionShape3D` (layer=4, mask=0)
5. Reference in scene_registry entry via `"avatar":` key

### Adding a new trigger type
1. Duplicate `triggers/interaction_zone.tscn`
2. In attached script: `extends "res://triggers/interaction_zone.gd"`
3. Override `_on_avatar_entered()` and/or `_on_avatar_exited()`

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
	  ├── fps_player.tscn / xr_player.tscn
	  └── avatar/*.tscn (per scene, from registry)

team_scene.gd
 ├── SceneManager (for solo test detection)
 └── fps_player.tscn (spawned in solo mode only)

interaction_zone.gd
 └── (reads group "remote_avatars" — no direct import)
```

---

## CHANGELOG

| Date | Change | Files |
|------|--------|-------|
| 2026-05-06 | fix: xr_player – _ready() mit XRCamera3D.make_current() hinzugefügt; ohne diesen Aufruf bleibt ServerCamera (current=true) aktiv → OpenXR-Compositor sieht falsche Frames → grauer Viewport auf Focus 3 | `player/xr_player.gd` |
| 2026-04-29 | fix: xr_player.gd _ready() entfernt — redundanter zweiter viewport.use_xr=true-Aufruf (Nebeneffekt: hatte XRCamera3D aktiviert; führte auf GL Compat zu Render-Target-Realloc) | `player/xr_player.gd` |
| 2026-04-28 | triggers/ → _deprecated/triggers/ (deactivated; design teams use animations only); design_teams.md restructured: index, "Euer Toolkit" intro, ZIP + GitHub setup removed | `_deprecated/triggers/`, `_anleitungen/design_teams.md`, `_anleitungen/ARCHITECTURE.md` |
| 2026-04-27 | Folder cleanup: `scenes/` → `_scenes/`, deleted `world/` and `assets/`; docs split into `_anleitungen/` (design_teams, venue_team, dev_team); roles renamed Dev Team / Venue Team / Design Teams | multiple |
| 2026-04-27 | scene_info.cfg per team folder: registry now path-list only (Dev Team), metadata in cfg files (Design Teams) | `_scenes/scene_registry.gd`, `scene_manager.gd`, `_scenes/*/scene_info.cfg` |
| 2026-04-27 | Default avatar changed to avatar_dynamic_cone.tscn (was remote_avatar.tscn) | `scene_manager.gd` |
| 2026-04-27 | Fix Label3D outline_modulate not animated: outline no longer visible when text is transparent | `main.gd` |
| 2026-04-27 | Directional shadow atlas size.mobile 2048→4096; soft_shadow_filter_quality.mobile=2 | `project.godot` |
| 2026-04-27 | shader_baker=true for Focus 3 export preset (eliminates shader hitch on first scene frame) | `export_presets.cfg.template` |
| 2026-04-27 | VR fade overlay: replaced CanvasLayer with 3D QuadMesh (8×8m) + Label3D; lazy-follow at 2m distance | `main.gd` |
| 2026-04-27 | VRS: vrs/mode=2 set in project.godot; programmatically overridden to VRS_DISABLED on PC | `main.gd`, `project.godot` |
| 2026-04-27 | Renderer: switched Forward Plus → GL Compatibility (better mobile VR performance) | `project.godot` |
| 2026-04-27 | Focus 3 render_target_size_multiplier 0.7 → 0.6 (36% pixel count, shadow PCF cost -64%) | `main.gd` |
| 2026-04-27 | Re-enabled shadows on Focus 3 (render_scale 0.6 makes PCF cost viable again) | `scene_manager.gd` |
| 2026-04-27 | _soften_shadows(): shadow_blur=2.5 + SHADOW_PARALLEL_2_SPLITS for Focus 3 at runtime | `scene_manager.gd` |
| 2026-04-27 | xr_player: body_pos uses camera XZ on floor Y (physical locomotion fix — avatar no longer stays at spawn) | `player/xr_player.gd` |
| 2026-04-27 | DynamicCone: tube_diameter 0.07→0.049 (-30%), top_ring_gap=0.05, damping_bottom 1.5→0.8, damping_mid 2.5→1.8 | `avatar/variants/avatar_dynamic_cone.gd` |
| 2026-04-27 | MSAA 2× re-enabled (msaa_3d=1) — GL Compat handles it better than Forward Plus on mobile | `project.godot` |
| 2026-04-24 | Focus 3: Schatten zur Laufzeit deaktiviert (_disable_shadows via find_children); +8-12% Frame-Budget | `scene_manager.gd` |
| 2026-04-24 | Fix placeholder_c: Instance 9 mit Scale 7241 (1112× zu groß, außerhalb Raumgrenzen) entfernt | `placeholder_c.tscn` |
| 2026-04-24 | 3D-Verbindungsstatusanzeige (Label3D, Billboard): zeigt IP + Versuchszähler wenn nicht verbunden | `net_info_board.gd`, `scene_manager.gd` |
| 2026-04-24 | Reconnect-Logik: ENet-Client wiederholt Verbindungsversuche alle 5s (dauerhaft) | `network_manager.gd`, `scene_manager.gd` |
| 2026-04-24 | Focus 3 render_target_size_multiplier 0.75 → 0.7 | `main.gd` |
| 2026-04-24 | Fix connection failure on Android headsets: add INTERNET + NETWORK_STATE + WIFI_STATE permissions | `export_presets.cfg.template` |
| 2026-04-24 | Disable MSAA (msaa_3d=0) — expensive on mobile VR, minimal visual benefit through lenses | `project.godot` |
| 2026-04-03 | Network diagnostics overlay (Tab toggle): mode, peer ID, peers + colors | `main.gd`, `main.tscn`, `project.godot` |
| 2026-04-03 | Server-authoritative avatar colors + scene-level player_color override | `game_state.gd`, `network_manager.gd`, `scene_manager.gd`, `scene_registry.gd` |
| 2026-04-03 | Add fade-to-black transition with scene title overlay | `main.gd`, `main.tscn`, `scene_manager.gd`, `scene_registry.gd` |
| 2026-04-02 | Merge fix/multiplayer-fps-physics → master | — |
| 2026-04-02 | Fix HTC foveation artifacts + PC black screen (disable VRS + foveation) | `project.godot` |
| 2026-04-02 | Fix DynamicCone rings snapping to origin on first frame | `avatar_dynamic_cone.gd` |
| 2026-04-02 | ServerCamera position set via look_at() in code | `team_scene.gd` |
| 2026-04-02 | Enable Gradle build for HTC Focus 3 preset | `export_presets.cfg.template` |
| 2026-04-02 | Add VR headtracking manifest declaration for HTC Focus 3 | `AndroidManifest.xml` |
| 2026-04-02 | Add DynamicCone avatar (tori, quadratic damping, set_self_mode) | `avatar_dynamic_cone.gd/.tscn` |
| 2026-04-02 | Add self-body FP view (self_avatar in SceneManager) | `scene_manager.gd` |
| 2026-04-02 | Add server avatar display (server spawns + updates remote_avatars) | `scene_manager.gd`, `network_manager.gd` |
| 2026-03-31 | Fix FPS camera, player-avatar collision, double scene load | `fps_player.gd`, `scene_manager.gd` |
