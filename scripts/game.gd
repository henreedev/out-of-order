extends Node2D

## Root level node for gameplay, displaying the arcade machine and the gameplay 
## within it, as well as any animations involving the machine or coins.
class_name Game

signal new_game_created(new_platformer : Platformer)

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
@onready var platformer: Platformer # = $SubViewportContainer/SubViewport/Platformer
@onready var sign: AnimatedSprite2D = $Sign
@onready var camera: Camera2D = $Camera2D
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var jump_button: MachineButton = $Machine/JumpButton
@onready var dash_button: MachineButton = $Machine/DashButton
@onready var joystick: Sprite2D = $Machine/Joystick
@onready var insert_label: Label = $InsertLabel
@onready var ready_label: Label = $ReadyLabel
@onready var pocket_arrow: Sprite2D = $PocketArrow
@onready var pocket_label: Label = $PocketLabel
@onready var pocket_button: Button = $PocketButton
@onready var pick_num_label: Label = $PickNumLabel
@onready var shaders: ColorRect = $Shaders
@onready var shader_mat: ShaderMaterial = $Shaders.material
@onready var timer_label: Label = $TimerLabel

var orig_shader_mat : ShaderMaterial

## A singleton instance.
static var inst : Game

var inserted_coins : Array[Coin]
var table_coins : Array[Coin]
var hand_coins : Array[Coin]

const MAX_SCORE := 9999
var score := 0
var score_multiplier := 1.0

var intro_done := false

const START_TIME := 1.0
var game_timer := START_TIME

var joystick_tween : Tween

var effect_tweens : Array[Tween]

const MAX_COINS_HELD = 6 
var coins_to_pick := 2
var available_coin_positions : Array[Vector2]
var coin_insert_satisfied := false

const INSERT_TEXT = "INSERT COIN"
const INSERT_TEXT_CONTINUE = "INSERT COIN\nTO CONTINUE"

func _ready() -> void:
	inst = self
	orig_shader_mat = shader_mat.duplicate()
	grab_coin_positions_and_delete()
	play_intro()
	blink_insert_label()
	move_pocket_arrow()
	reset_static_vars()

func reset_static_vars():
	Player.time_scale = 1.0
	Player.speed = Player.BASE_SPEED
	Player.random_speed_mod = 1.0
	Player.gravity = Player.GRAVITY
	Player.dash_mod = 1.0
	Player.reversed_controls = false
	Player.lag_time_scale = 1.0

func grab_coin_positions_and_delete():
	for coin in get_children():
		if coin is Coin:
			available_coin_positions.append(coin.position)
			coin.queue_free()

func play_intro():
	var intro_tween := create_tween()
	
	const FADE_IN = 2.0
	intro_tween.tween_property(self, "modulate", Color.WHITE, FADE_IN).from(Color.BLACK).set_trans(Tween.TRANS_CUBIC)
	intro_tween.parallel().tween_property(camera, "zoom", Vector2.ONE, FADE_IN).from(Vector2.ONE * 2).set_trans(Tween.TRANS_CUBIC)
	intro_tween.tween_property(self, "intro_done", true, 0.0)

func blink_insert_label():
	insert_label.text = INSERT_TEXT
	var tween := create_tween().set_loops()
	tween.tween_property(insert_label, "visible", true, 0.5)
	tween.tween_property(insert_label, "visible", false, 0.5)

func move_pocket_arrow():
	var tween := create_tween().set_loops()
	tween.tween_property(pocket_arrow, "position", pocket_arrow.position, 1.0)
	tween.tween_property(pocket_arrow, "position", pocket_arrow.position + Vector2.DOWN, 1.0)

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
			tick_timer(delta)
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
			tick_timer(delta)
		State.INSERTING_COINS:
			tick_timer(delta)
			
			if coin_insert_satisfied:
				ready_label.show()
				insert_label.modulate.a = 0
				if Input.get_axis("move_left", "move_right") != 0 or\
						Input.is_action_just_pressed("jump"):
					transition_to_state(State.IN_GAME)
					act_on_state(delta)
			else:
				insert_label.modulate.a = 1
				ready_label.hide()
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
			game_score_label.show()
			multiplier_label.show()
			for coin: Coin in get_tree().get_nodes_in_group("coin"):
				coin.interactable = false
			ready_label.hide()
		State.PICKING_COINS:
			rotate_joystick_to(0)
			dash_button.release()
			jump_button.release()
			
			if score == MAX_SCORE:
				win()
				return
			
			timer_label.show()
			
			# Check if we have space
			set_num_coins_to_pick()
			assert(coins_to_pick >= 0)
			if coins_to_pick == 0:
				# TODO show some text explaining why didnt check pocket
				transition_to_state(State.INSERTING_COINS)
				return
			# Check pocket
			prompt_pocket_after_delay()
			
		State.INSERTING_COINS:
			make_table_coins_interactable()
			coin_insert_satisfied = false
			pick_num_label.create_tween().tween_property(pick_num_label, "modulate", Color.TRANSPARENT, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		State.END:
			hide_pocket()
			for coin : Coin in get_tree().get_nodes_in_group("coin"):
				coin.interactable = false
			for tween in effect_tweens:
				if tween:
					tween.kill()

func tick_timer(delta):
	game_timer = maxf(game_timer - delta, 0)
	timer_label.text = str(int(game_timer + 1) / 60) + ":" + str(int(game_timer + 1) % 60).pad_zeros(2)
	if game_timer <= 0:
		timer_label.text = "0:00"
		lose()

func win():
	transition_to_state(State.END)
	# TODO trigger dialogue
	var tween := create_tween()
	tween.tween_interval(5.0)
	tween.tween_property(high_score_label, "position", Vector2(-31, -7), 3.0)
	tween.tween_interval(0.0)
	tween.tween_property(high_score_label, "text", "9999", 0.0)
	tween.tween_property(self, "modulate", Color.BLACK, 2.0).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(get_tree().reload_current_scene)

func lose():
	transition_to_state(State.END)
	# TODO trigger dialogue
	sign.play("lower")
	var tween := create_tween()
	tween.tween_interval(4.0)
	tween.tween_property(self, "modulate", Color.BLACK, 2.0).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(get_tree().reload_current_scene)

func prompt_pocket_after_delay():
	insert_label.modulate.a = 1
	
	var tween : Tween = create_tween()
	tween.tween_interval(1.15)
	tween.tween_callback(prompt_pocket)

func prompt_pocket():
	pocket_button.disabled = false
	pocket_button.visible = true
	pocket_arrow.visible = true
	pocket_arrow.modulate.a = 0.0
	pocket_label.visible = true
	pocket_label.modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(pocket_arrow, "modulate", Color.WHITE, 0.5).from(Color(2,2,2,0)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(pocket_label, "modulate", Color.WHITE, 0.5).from(Color(2,2,2,0)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func hide_pocket():
	pocket_button.disabled = true
	pocket_button.visible = false
	var tween := create_tween().set_parallel()
	tween.tween_property(pocket_arrow, "modulate", Color.TRANSPARENT, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(pocket_arrow, "visible", false, 0.5)
	tween.tween_property(pocket_label, "modulate", Color.TRANSPARENT, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(pocket_label, "visible", false, 0.5)

func make_table_coins_interactable():
	get_tree().set_group("coin", "interactable", true)
	for coin : Coin in get_tree().get_nodes_in_group("coin"):
		if coin.on_table:
			coin.interactable = true
		else:
			coin.trash()

func add_score(amount : int):
	amount *= score_multiplier
	score = mini(score + amount, MAX_SCORE)
	game_score_label.text = str(score).pad_zeros(4)

func draw_coins():
	# Draw the coins
	var tween := create_tween().set_parallel()
	var new_coins = Coin.draw_new_coins(3)
	pick_num_label.text = "PICK " + str(coins_to_pick)
	pick_num_label.visible = true
	pick_num_label.modulate.a = 0
	const HOZ_OFFSET = Vector2(20.0, 0.0)
	var screen_pos = -HOZ_OFFSET
	var i = 0
	for new_coin : Coin in new_coins:
		new_coin.position = Vector2(randi_range(70, 80), 100)
		add_child(new_coin)
		tween.tween_property(new_coin, "position", screen_pos, .8 * randf_range(0.7, 1.3)).set_delay(i * 0.2 * randf_range(0.7, 1.3)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(new_coin, "interactable", true, 0.0).set_delay(1.6)
		screen_pos += HOZ_OFFSET
		i += 1
	tween.tween_property(pick_num_label, "modulate", Color.WHITE, 0.5).from(Color(2,2,2,0)).set_delay(1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	
func coin_type_in_list(type : Coin.Type, coin_list : Array = table_coins):
	for coin : Coin in coin_list:
		if coin.type == type:
			return true
	return false

func insert_coin(coin : Coin):
	game_score_label.show()
	multiplier_label.show()
	coin.interactable = false
	coin.on_table = false
	coin_insert_satisfied = true
	score_multiplier += coin.multiplier - 1
	coin.do_coin_effect()
	multiplier_label.text = "x" + str(score_multiplier).pad_decimals(1)
	table_coins.erase(coin)
	inserted_coins.append(coin)
	assert(coin.table_pos != Vector2.ZERO)
	available_coin_positions.append(coin.table_pos)
	coin.play("hover")
	var tween := create_tween() 
	tween.tween_property(coin, "position:x", randf_range(-5.0, 10.0), 1.0).set_trans(Tween.TRANS_ELASTIC)
	tween.parallel().tween_property(coin, "position:y", 55.0, 1.0).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_callback(coin.queue_free) # TODO add an insert sound here

func put_coin_on_table(coin : Coin):
	var tween := create_tween()
	table_coins.append(coin)
	coin.interactable = false
	coin.on_table = true
	coin.play("unhover")
	coin.z_index = 0
	var end_pos = find_open_coin_position()
	coin.table_pos = end_pos
	var drop_offset = Vector2(0, randi_range(-35, -45))
	tween.tween_property(coin, "position", end_pos + drop_offset, 0.8).set_trans(Tween.TRANS_BACK)
	tween.tween_property(coin, "position", end_pos, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(coin.play.bind("on_table"))
	
	coins_to_pick -= 1
	pick_num_label.text = "PICK " + str(coins_to_pick)
	assert(coins_to_pick >= 0)
	if coins_to_pick == 0:
		transition_to_state(State.INSERTING_COINS)


func find_open_coin_position():
	return available_coin_positions.pop_at(randi_range(0, available_coin_positions.size() - 1))

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
	platformer.visible = false
	sub_viewport.add_child(platformer)
	
	insert_label.text = INSERT_TEXT_CONTINUE

func win_platformer():
	add_score(500)
	platformer.player.die()

func apply_coin_effect(coin : Coin):
	coin.apply_effect()

func rotate_joystick_to(angle):
	if joystick_tween:
		joystick_tween.kill()
	joystick_tween = create_tween()
	var is_elastic = randf() < 0.4
	joystick_tween.tween_property(joystick, "rotation", angle, 0.55 if is_elastic else 0.35).set_trans(Tween.TRANS_ELASTIC if is_elastic else Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func do_lag():
	var lag_tween := create_tween()
	lag_tween.tween_interval(0.2 * randf_range(0.6, 1.8))
	lag_tween.tween_property(Player, "lag_time_scale", 0.0, 0.1)
	lag_tween.tween_interval(0.5 * randf_range(0.3, 1.8))
	lag_tween.tween_property(Player, "lag_time_scale", 1.0, 0.1)
	

func _on_sign_animation_finished() -> void:
	if sign.animation == "raise":
		transition_to_state(State.PICKING_COINS) 


func _on_pocket_button_pressed() -> void:
	draw_coins()
	hide_pocket()


func apply_invisible_spikes(new_platformer : Platformer) -> void:
	new_platformer.get_spikes().hide()

func apply_no_coins(new_platformer : Platformer) -> void:
	new_platformer.get_coins().free()

func apply_upside_down(new_platformer : Platformer):
	new_platformer.player.camera.zoom.y = -1

func apply_flipped(new_platformer : Platformer):
	new_platformer.player.camera.zoom.x = -1

func apply_bugs(new_platformer : Platformer):
	new_platformer.get_bugs().enabled = true

func set_aberration(val : float):
	shader_mat.set_shader_parameter("aberration", val)

func set_static(val : float):
	shader_mat.set_shader_parameter("static_noise_intensity", val)
