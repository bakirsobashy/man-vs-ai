class_name OneShotFx
extends CPUParticles2D
## A one-shot particle effect copied at runtime (death sparks). Its "finished" signal is connected in the
## scene to free it.


func _on_finished() -> void:
	queue_free()
