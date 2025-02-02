extends Node2D

class_name BugSpawner
const BUG = preload("res://scenes/bug.tscn")
const Y_EXTENT = 45.0

var enabled := false

var spawn_interval := 3.0

var spawn_timer := spawn_interval

func _physics_process(delta: float) -> void:
	if enabled:
		spawn_timer -= delta
		if spawn_timer <= 0:
			spawn_timer = spawn_interval - spawn_timer
			spawn_bug()

func spawn_bug():
	var spawn_pos = Vector2(0, randf_range(-Y_EXTENT, Y_EXTENT))
	var bug = BUG.instantiate()
	bug.position = spawn_pos
	add_child(bug)
	var tween := create_tween()
	tween.tween_property(bug, "global_position:x", -4.0, 24.0)
	tween.tween_callback(bug.queue_free)
	var tween_2 := create_tween().set_loops
	tween.tween_property(bug, "position:y", -1.0, 0.5)
	tween.tween_property(bug, "position:y", 1.0, 0.75)
