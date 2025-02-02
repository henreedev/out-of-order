extends Node2D

class_name Platformer

var running := false
@onready var player: Player = $Player

func _ready() -> void:
	player.died.connect(end_game)

func start():
	running = true

func end_game():
	running = false
	queue_free()
