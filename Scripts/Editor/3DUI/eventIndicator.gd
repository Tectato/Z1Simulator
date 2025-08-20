extends Node3D
class_name EventIndicator

enum Type {Attention, Error, Blocked, Turn}
var riseSpeed = 0.1

func setType(type : Type):
	var anim = ""
	match(type):
		Type.Attention:
			anim = "attention"
		Type.Error:
			anim = "error"
		Type.Blocked:
			anim = "blocked"
		Type.Turn:
			anim = "turn"
	$Sprite.animation = anim

func _process(delta: float) -> void:
	position = position + Vector3.UP * riseSpeed * delta

func _on_timer_timeout() -> void:
	queue_free()
