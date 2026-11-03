#!/usr/bin/env bash
# Scene-first check (docs/technical.md §0).
# Fails if any game script in src/ constructs scene-tree nodes or collision shapes in code.
# Build those nodes in a .tscn scene instead. A justified exception needs
# "# scene-first: allow <reason>" on the same line and the owner's approval.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -d src ]; then
  echo "scene-first check: no src/ folder, nothing to check"
  exit 0
fi

classes='Node|Node2D|CanvasLayer|CanvasGroup|Control|Container|MarginContainer|VBoxContainer|HBoxContainer'
classes+='|GridContainer|CenterContainer|PanelContainer|ScrollContainer|Panel|Label|RichTextLabel|Button'
classes+='|TextureButton|LinkButton|CheckBox|CheckButton|OptionButton|HSlider|VSlider|ProgressBar'
classes+='|TextureProgressBar|TextureRect|ColorRect|NinePatchRect|ReferenceRect|LineEdit|Sprite2D'
classes+='|AnimatedSprite2D|Line2D|Polygon2D|Marker2D|Camera2D|Area2D|StaticBody2D|CharacterBody2D'
classes+='|RigidBody2D|AnimatableBody2D|CollisionShape2D|CollisionPolygon2D|RayCast2D|ShapeCast2D|Timer'
classes+='|AnimationPlayer|AnimationTree|AudioStreamPlayer|AudioStreamPlayer2D|GPUParticles2D|CPUParticles2D'
classes+='|PointLight2D|DirectionalLight2D|LightOccluder2D|TileMapLayer|NavigationAgent2D|NavigationRegion2D'
classes+='|NavigationObstacle2D|VisibleOnScreenNotifier2D|VisibleOnScreenEnabler2D|Path2D|PathFollow2D'
classes+='|RemoteTransform2D|Skeleton2D|Bone2D|SubViewport|SubViewportContainer'
classes+='|CircleShape2D|RectangleShape2D|CapsuleShape2D|SegmentShape2D|SeparationRayShape2D'
classes+='|ConvexPolygonShape2D|ConcavePolygonShape2D|WorldBoundaryShape2D'
pattern="(^|[^A-Za-z0-9_])(${classes})\.new\("

violations=$(grep -rnE --include='*.gd' "$pattern" src | grep -v 'scene-first: allow' || true)

if [ -n "$violations" ]; then
  echo "Scene-first violations: build these nodes in a .tscn scene instead (docs/technical.md §0):"
  echo "$violations"
  exit 1
fi
echo "scene-first check passed"
