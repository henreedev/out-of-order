extends AnimatedSprite2D

class_name PlatformerCoin

var score := 50000

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		on_collect()

func on_collect():
	if Game.inst:
		Game.inst.add_score(score)
	queue_free()
