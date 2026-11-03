# CLAUDE.md

Guidance for Claude Code sessions working in this repository.

## Project
**Man vs AI** is a one-finger, top-down roguelite shooter for Android (portrait).
- Godot 4.7, GDScript, Compatibility renderer.
- 360×640 base viewport; 1 tile = 16 px.
- The design docs are in `docs/`: start with `docs/GDD.md`, and read `docs/technical.md` §0 before writing any game code.
- Example scene trees for every main object are in `docs/technical.md` §0.8.

## Hard rule: scene-first (node-based) development
The project owner develops node-based. Every change must follow these rules:
- **Everything visible, physical or positioned is a node in a `.tscn` scene.** That covers sprites, `Area2D`s, bodies,
  `CollisionShape2D`s and their shapes, markers, timers, cameras, particles and UI. Positions, sizes, collision
  layers/masks and groups are set in the scene, not in scripts.
- **Scripts only add behavior to nodes that already exist.** Reference nodes through scene-unique names
  (`@onready var hurtbox: Area2D = %Hurtbox`) or `@export` properties assigned in the Inspector.
- **Never construct nodes or shapes in code** (`Area2D.new()`, `CollisionShape2D.new()`, `Sprite2D.new()`,
  `Timer.new()`, `RectangleShape2D.new()`, …), and never build node trees in `_ready()`.
- **Runtime copies are the only exception:** the game may instantiate authored scenes (`PackedScene.instantiate()`).
  That covers bullets, drops, effects, enemies at `SpawnPoint`s, weapons and room templates, placed at positions read
  from marker nodes.
- **Tuning numbers are `@export` properties on the scene's root node,** each with a `##` doc comment. Non-world data
  (implants, level config, weapon catalog, control thresholds) is `.tres` under `data/`.
- **Connect same-scene signals in the scene file** (editor connections, `[connection]` entries). Code connects only to
  the `EventBus` autoload and to runtime copies it just created.
- **Use the node building blocks:**
  - `Timer` nodes for timing;
  - `AnimationPlayer` and `AnimatedSprite2D` for animation;
  - `StateMachine` nodes with one child node per state;
  - `class_name` component nodes in `src/components/`.
- **No `_draw()` for game visuals.** Only the debug overlay and `@tool` editor gizmos may draw.
- **Exceptions are rare:** a justified one needs a `# scene-first: allow <reason>` comment on the line and the owner's
  approval.

## Writing scenes as text
- Write `.tscn` files in Godot 4's text scene format (`[gd_scene format=3]`, then `[ext_resource]`, `[sub_resource]`,
  `[node]` and `[connection]` sections), the way the editor saves them, so the owner can open and edit them.
- Collision shapes are `[sub_resource]` entries (for example `RectangleShape2D` with `size`), assigned to the
  `shape` property of a `CollisionShape2D` node.

## Checks before committing
Run these from the repository root. Here `godot` means a Godot 4.7 binary.
```bash
tools/check_scene_first.sh
```
```bash
godot --headless --path . --script res://tools/check_scenes.gd
```
```bash
godot --headless --path . --script res://tools/smoke_test_controls.gd
```
```bash
godot --headless --path . --script res://tools/smoke_test_combat.gd
```
```bash
godot --headless --path . --script res://tools/test_level_generator.gd
```
```bash
godot --headless --path . --script res://tools/smoke_test_level.gd
```
```bash
godot --headless --path . --script res://tools/smoke_test_m4.gd
```
```bash
godot --headless --path . --script res://tools/smoke_test_flow.gd
```
```bash
godot --headless --path . --script res://tools/smoke_test_l2.gd
```
```bash
godot --headless --path . --script res://tools/smoke_test_l3.gd
```
Before writing physics or tool code, read the Godot 4.7 gotchas in `docs/technical.md` §1.0:
- `Area2D` sensors keep `monitorable` on;
- pooled areas are parked, never toggled;
- world-space Controls ignore the mouse;
- `--script` tools load project classes in `_initialize()`;
- door signals are ignored while a room transition fades (every room shares the same origin);
- inner enums must not reuse a global class name (`State` is taken);
- `resized` fires before `_ready`;
- nodes kept outside the tree must be freed by whoever keeps them;
- one leaked `AudioStreamPlayback` at exit in headless runs is harmless;
- only argument-less signals may be connected to `AudioStreamPlayer.play`.
If Godot isn't installed (for example in a cloud container), download the official Godot 4.7 Linux build from the
`godotengine/godot` GitHub releases into a scratch directory and run the checks with it.

## Conventions
- Static typing everywhere (`untyped_declaration` warnings are on).
- Follow the official GDScript style guide; files are snake_case, `class_name`s are PascalCase.
- When behavior or numbers change, keep the design docs in `docs/` in sync.
