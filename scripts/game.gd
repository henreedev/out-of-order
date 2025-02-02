extends Node2D

## Root level node for gameplay, displaying the arcade machine and the gameplay 
## within it, as well as any animations involving the machine or coins.
class_name Game

enum State {
	INTRO,
	IN_GAME,
	PICKING_COINS,
	INSERTING_COINS,
	END,
}

var state : State = State.INTRO

const PLATFORMER_SCENE = preload("res://scenes/platformer.tscn")

@onready var game_score_label: Label = $GameScoreLabel
@onready var high_score_label: Label = $HighScoreLabel
@onready var multiplier_label: Label = $MultiplierLabel
@onready var platformer: Platformer = $SubViewportContainer/SubViewport/Platformer
@onready var sign: AnimatedSprite2D = $Sign
@onready var camera: Camera2D = $Camera2D
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var jump_button: MachineButton = $Machine/JumpButton
@onready var dash_button: MachineButton = $Machine/DashButton
@onready var joystick: Sprite2D = $Machine/Joystick
@onready var insert_label: Label = $InsertLabel
@onready var ready_label: Label = $ReadyLabel

## A singleton instance.
static var inst : Game

var inserted_coins : Array[Coin]
var table_coins : Array[Coin]
var hand_coins : Array[Coin]

const MAX_SCORE := 9999
var score := 0
var score_multiplier := 1.0

var intro_done := false

var joystick_tween : Tween

const MAX_COINS_HELD = 6 
var coins_to_pick := 2
var coin_positions : Array[Vector2]
var available_coin_positions : Array[Vector2]
var coin_insert_satisfied := false

const INSERT_TEXT = "INSERT COIN"
const INSERT_TEXT_CONTINUE = "INSERT COIN\nTO CONTINUE"

func _ready() -> void:
	inst = self
	grab_coin_positions_and_delete()
	play_intro()
	blink_insert_label()
	move_pocket_arrow()
	

func grab_coin_positions_and_delete():
	for coin in get_children():
		if coin is Coin:
			coin_positions.append(coin.position)
			coin.queue_free()

func play_intro():
	var intro_tween := create_tween()
	
	const FADE_IN = 2.0
	intro_tween.tween_property(self, "modulate", Color.WHITE, FADE_IN).from(Color.BLACK).set_trans(Tween.TRANS_CUBIC)
	intro_tween.parallel().tween_property(camera, "zoom", Vector2.ONE, FADE_IN).from(Vector2.ONE * 2)
	intro_tween.tween_property(self, "intro_done", true, 0.0)

func blink_insert_label():
	var tween := create_tween().set_loops()
	tween.tween_property(insert_label, "visible", true, 0.5)
	tween.tween_property(insert_label, "visible", false, 0.5)

func move_pocket_arrow():
	var tween := create_tween().set_loops()
	tween.tween_property(insert_label, "visible", true, 0.5)
	tween.tween_property(insert_label, "visible", false, 0.5)

func _input(event) -> void:
	if event.is_action_pressed("fullscreen"):
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			#Input.mouse_mode = Input.MOUSE_MODE_CONFINED
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			#Input.mouse_mode = Input.MOUSE_MODE_CONFINED

func _physics_process(delta: float) -> void:
	act_on_state(delta)

func act_on_state(delta: float):
	match state:
		State.INTRO:
			if intro_done:
				if Input.is_action_just_pressed("dash"):
					sign.play("raise")
		State.IN_GAME:
			if Input.is_action_just_pressed("dash"):
				dash_button.press()
			if Input.is_action_just_released("dash"):
				dash_button.release()
			
			if Input.is_action_just_pressed("jump"):
				jump_button.press()
			if Input.is_action_just_released("jump"):
				jump_button.release()
			
			if Input.is_action_just_pressed("move_left") or \
					Input.is_action_just_released("move_left") or \
					Input.is_action_just_pressed("move_right") or \
					Input.is_action_just_released("move_right"):
				var movement = Input.get_axis("move_left", "move_right")
				var angle = movement * PI / 4
				rotate_joystick_to(angle)
		State.PICKING_COINS:
			pass
		State.INSERTING_COINS:
			pass
		State.END:
			pass

func transition_to_state(new_state : State):
	if state != new_state:
		state = new_state
	match new_state:
		State.INTRO:
			pass
		State.IN_GAME:
			start_new_game()
		State.PICKING_COINS:
			rotate_joystick_to(0)
			draw_coins()
		State.INSERTING_COINS:
			create_tween().tween_callback(make_table_coins_interactable).set_delay(1.6)
			coin_insert_satisfied = false
			insert_label.show()
		State.END:
			pass

func make_table_coins_interactable():
	get_tree().set_group("coin", "interactable", true)

func add_score(amount : int):
	amount *= score_multiplier
	score = mini(score + amount, MAX_SCORE)
	game_score_label.text = str(score).pad_zeros(4)

func draw_coins():
	# Check if we have space
	set_num_coins_to_pick()
	assert(coins_to_pick >= 0)
	if coins_to_pick == 0:
		# TODO show some text explaining why didnt check pocket
		transition_to_state(State.INSERTING_COINS)
		return
	
	# Draw the coins
	var tween := create_tween()
	var new_coins = Coin.draw_new_coins(3)
	const HOZ_OFFSET = Vector2(20.0, 0.0)
	var screen_pos = -HOZ_OFFSET
	var i = 0
	for new_coin : Coin in new_coins:
		new_coin.position = Vector2(randi_range(70, 80), 55)
		add_child(new_coin)
		tween.tween_property(new_coin, "position", screen_pos, 1.0).set_delay(i * 0.2)
		tween.tween_property(new_coin, "interactable", true, 0.0).set_delay(2.0)
	
	
	
func coin_type_in_hand(type : Coin.Type):
	for coin : Coin in hand_coins:
		if coin.type == type:
			return true
	return false

func insert_coin(coin : Coin):
	coin.interactable = false
	assert(coin.table_pos != Vector2.ZERO)
	available_coin_positions.append(coin.table_pos)
	var tween := create_tween() # TODO
	#tween.tween_property(coin.position, "")

func put_coin_on_table(coin : Coin):
	var tween := create_tween()
	coin.interactable = false
	coin.on_table = true
	coin.play("unhover")
	coin.z_index = 0
	var end_pos = find_open_coin_position()
	coin.table_pos = end_pos
	var drop_offset = Vector2(0, randi_range(-35, -45))
	tween.tween_property(coin, "position", end_pos + drop_offset, 1.0).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(coin, "position", end_pos, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(coin, "animation", "on_table", 0.0)
	
	coins_to_pick -= 1
	assert(coins_to_pick >= 0)
	if coins_to_pick == 0:
		transition_to_state(State.INSERTING_COINS)


func find_open_coin_position():
	return available_coin_positions.pop_at(randi_range(0, available_coin_positions.size()))

func get_coins_held():
	return MAX_COINS_HELD - available_coin_positions.size()

func get_available_coin_slots():
	return available_coin_positions.size()

func set_num_coins_to_pick():
	coins_to_pick = mini(get_available_coin_slots(), 2)

func on_game_won():
	add_score(1000)

func start_new_game():
	if platformer:
		print("TODO FIX CASE WITH PLATFORMER STILL NONNULL WHEN STARTING NEW GAME")
		platformer.queue_free()
	platformer = PLATFORMER_SCENE.instantiate()
	sub_viewport.add_child(platformer)
	
	insert_label.text = INSERT_TEXT_CONTINUE

func apply_coin_effects():
	score_multiplier = 1.0
	for coin in inserted_coins:
		score != coin.multiplier

func rotate_joystick_to(angle):
	if joystick_tween:
		joystick_tween.kill()
	joystick_tween = create_tween()
	joystick_tween.tween_property(joystick, "rotation", angle, 0.35).set_trans(Tween.TRANS_ELASTIC if randf() < 0.5 else Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _on_sign_animation_finished() -> void:
	if sign.animation == "raise":
		transition_to_state(State.IN_GAME) # TODO change to State.PICKING_COINS
