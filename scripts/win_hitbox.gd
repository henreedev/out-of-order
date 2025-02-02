extends Area2D

class_name WinHitbox

func _ready() -> void:
	body_entered.connect(_on_win_hitbox_body_entered)

func _on_win_hitbox_body_entered(body: Node2D) -> void:
	if body is Player:
		Game.inst.win_platformer()
