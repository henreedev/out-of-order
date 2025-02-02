extends Area2D

class_name Bug

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		Game.inst.platformer.player.die()
