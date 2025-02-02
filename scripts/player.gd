extends CharacterBody2D

class_name Player

signal died

const SPEED = 65.0

const JUMP_BUFFER = 1.0
var jump_buffer_timer := 0.0
const COYOTE_TIME = 0.1
var coyote_timer := 0.0
const DASH_COOLDOWN = 2.0
var dash_cooldown_timer := 0.0
const JUMP_STR = 70.0
const JUMP_FLOAT_STR = 0.5
const JUMP_FLOAT_SPD = 5.0
const GRAVITY = 150.0

var on_floor := false
var dead := false
@onready var asprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if dead: return
	
	_tick_timers(delta)
	_check_floor_status()
	
	# Vertical movement
	var grav = GRAVITY
	
	if Input.is_action_just_pressed("jump"):
		_try_jump()
	
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5
	
	if Input.is_action_pressed("jump"):
		# Lower gravity if holding space at top of jump arc
		if abs(velocity.y) < JUMP_FLOAT_SPD:
			grav *= JUMP_FLOAT_STR
		if jump_buffer_timer > 0 and is_on_floor():
			_jump()
	
	if not is_on_floor():
		velocity.y += grav * delta
	
	if Input.is_action_just_pressed("dash"):
		try_dash()
	
	# Hoz movement
	var movement = Input.get_axis("move_left", "move_right") * SPEED
	var accel_mod = 1.0 if is_on_floor() else 0.6
	var dist_to_max_speed = abs(SPEED - abs(velocity.x))
	
	if dist_to_max_speed < 20 and movement * velocity.x > 0:
		accel_mod *= 0.5
	
	const LERP_RATIO = 0.9
	
	const LERP_STR = 4.0
	const LINEAR_STR = 2.5
	
	
	velocity.x = (1.0 - LERP_RATIO) * move_toward(velocity.x, movement, LINEAR_STR * accel_mod) + \
		LERP_RATIO * lerp(velocity.x, movement, delta * LERP_STR * accel_mod)
	move_and_slide()
	
	# Check for spike collision
	for i in range(get_slide_collision_count()):
		if get_slide_collision(i).get_collider() is Spikes:
			die()
			return
	
	# Animate
	if is_on_floor():
		if movement < 0:
			asprite.flip_h = true
			asprite.animation = "walk"
			asprite.speed_scale = abs(velocity.x) / SPEED
		elif movement > 0:
			asprite.flip_h = false
			asprite.animation = "walk"
			asprite.speed_scale = abs(velocity.x) / SPEED
		if abs(velocity.x) < 0.1:
			asprite.play("idle")
	else:
		asprite.play("jump")
	

func _try_jump():
	if is_on_floor() or coyote_timer > 0.0:
		_jump()
	else:
		jump_buffer_timer = JUMP_BUFFER

func _jump():
	velocity.y = -JUMP_STR

func _check_floor_status():
	if not is_on_floor() and on_floor and not Input.is_action_pressed("jump"):
		# Just left floor
		coyote_timer = COYOTE_TIME
	on_floor = is_on_floor()

func _tick_timers(delta : float):
	coyote_timer = maxf(0.0, coyote_timer - delta)
	jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
	dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)

func try_dash():
	if not dash_cooldown_timer > 0:
		var mouse_dir = get_local_mouse_position().normalized()
		mouse_dir.x *= 1.5
		const STR = 75.0
		velocity = mouse_dir * STR
		dash_cooldown_timer = DASH_COOLDOWN

func die():
	dead = true
	collision_mask = 0
	asprite.play("death")
	asprite.speed_scale = 1.0

func _on_animated_sprite_2d_animation_finished() -> void:
	if asprite.animation == "death":
		died.emit() # End this game
