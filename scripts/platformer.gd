extends Node2D

class_name Platformer

var running := false
@onready var player: Player = $Player
@onready var map: TileMapLayer = $Map

func _ready() -> void:
	visible = true
	player.died.connect(end_game)
	Game.inst.new_game_created.emit(self)

func get_spikes():
	return map.get_child(1) # FIXME scuffed
func get_coins():
	return map.get_child(0) # FIXME scuffed
func get_bugs():
	return map.get_child(3) # FIXME scuffed

func start():
	running = true

func end_game():
	running = false
	Game.inst.transition_to_state(Game.State.PICKING_COINS)
	queue_free()
