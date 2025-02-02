extends AnimatedSprite2D

class_name Coin

enum Type {
	REVERSED_CONTROLS,
	STATIC,
	SCAN_LINES,
	BUGS,
	BIG_DASH,
	FASTER_PLAYER,
	LAG, ## Random freezes
	UPSIDE_DOWN,
	CHROMATIC_ABERRATION,
	INVISIBLE_SPIKES,
	LOW_GRAVITY,
	RANDOM_SPEEDS,
	NO_COINS,
	SLOWER_PLAYER,
	HOZ_FLIP,
}

var type : Type

const TYPE_TO_MULT : Dictionary[Type, float] = {
	Type.REVERSED_CONTROLS : 2.0,
	Type.STATIC : 2.0,
	Type.SCAN_LINES : 1.5,
	Type.BUGS : 2.8,
	Type.BIG_DASH : 0.2,
	Type.FASTER_PLAYER : 0.4,
	Type.LAG : 2.2, ## Random freezes
	Type.UPSIDE_DOWN : 2.1,
	Type.CHROMATIC_ABERRATION : 1.5,
	Type.INVISIBLE_SPIKES : 2.9,
	Type.LOW_GRAVITY : 0.1,
	Type.RANDOM_SPEEDS : 1.8,
	Type.NO_COINS: 10.2,
	Type.SLOWER_PLAYER: 2.4,
	Type.HOZ_FLIP: 2.5,
}

const TYPE_TO_NAME: Dictionary[Type, String] = {
	Type.REVERSED_CONTROLS : "INVERSION",
	Type.STATIC : "INTERFERENCE",
	Type.SCAN_LINES : "SCANLINES",
	Type.BUGS : "BUGS",
	Type.BIG_DASH : "BIG DASH",
	Type.FASTER_PLAYER : "SPEEDY",
	Type.LAG : "LAG", ## Random freezes
	Type.UPSIDE_DOWN : "UPSIDE DOWN",
	Type.CHROMATIC_ABERRATION : "LSD",
	Type.INVISIBLE_SPIKES : "INVISIBLE SPIKES",
	Type.LOW_GRAVITY : "LOW GRAVITY",
	Type.RANDOM_SPEEDS : "PING PONG SPEED",
	Type.NO_COINS: "NO COINS",
	Type.SLOWER_PLAYER: "SLOWMO",
	Type.HOZ_FLIP: "FLIPPED",
}

@export var TYPE_TO_COLOR: Dictionary[Type, Color] = {
	Type.REVERSED_CONTROLS : Color.WHITE,
	Type.STATIC : Color.WHITE,
	Type.SCAN_LINES : Color.WHITE,
	Type.BUGS : Color.WHITE,
	Type.BIG_DASH : Color.WHITE,
	Type.FASTER_PLAYER : Color.WHITE,
	Type.LAG : Color.WHITE, ## Random freezes
	Type.UPSIDE_DOWN : Color.WHITE,
	Type.CHROMATIC_ABERRATION : Color.WHITE,
	Type.INVISIBLE_SPIKES : Color.WHITE,
	Type.LOW_GRAVITY : Color.WHITE,
	Type.RANDOM_SPEEDS : Color.WHITE,
	Type.NO_COINS : Color.WHITE,
	Type.SLOWER_PLAYER : Color.WHITE,
	Type.HOZ_FLIP : Color.WHITE,
}

const COIN = preload("res://scenes/coin.tscn")
var on_table := false
var interactable := false

# Attributes
var multiplier := 1.0
var coin_name := ""
var table_pos : Vector2

@onready var button: Button = $Button
@onready var name_label: Label = $NameLabel
@onready var mult_label: Label = $MultLabel

static func draw_new_coins(num := 3):
	var coins = []
	for i in range(num):
		var new_coin : Coin = COIN.instantiate()
		new_coin.type = randi_range(0, Type.size() - 1)
		while Game.inst.coin_type_in_list(new_coin.type, coins) or \
				Game.inst.coin_type_in_list(new_coin.type):
			new_coin.type = randi_range(0, Type.size() - 1)
		coins.append(new_coin)
	return coins

func _ready() -> void:
	pick_mult()
	pick_name()
	pick_color()
	

func _physics_process(delta: float) -> void:
	button.disabled = not interactable
	button.visible = interactable

func pick_mult():
	multiplier = TYPE_TO_MULT[type]
	mult_label.text = ("+" if multiplier - 1 > 0 else "") + str(multiplier - 1).pad_decimals(1)
	mult_label.label_settings = mult_label.label_settings.duplicate()
	mult_label.label_settings.font_color = Color.INDIAN_RED if multiplier < 1.0 else Color.SPRING_GREEN

func pick_name():
	coin_name = TYPE_TO_NAME[type]
	name_label.text = coin_name

func pick_color():
	self_modulate = TYPE_TO_COLOR[type]
	name_label.label_settings = name_label.label_settings.duplicate()
	name_label.label_settings.font_color = self_modulate


func do_coin_effect():
	match type:
		Type.REVERSED_CONTROLS:
			Player.reversed_controls = true
		Type.STATIC:
			var tween := Game.inst.create_tween().set_loops()
			tween.tween_method(Game.inst.set_static, 0.0, 0.5, 1.5).set_trans(Tween.TRANS_BOUNCE)
			tween.tween_method(Game.inst.set_static, .8, 0.0, 1.2).set_trans(Tween.TRANS_BOUNCE)
			Game.inst.effect_tweens.append(tween)
		Type.SCAN_LINES:
			#Game.inst.shader_mat.set_shader_parameter("scanlines_opacity", 1.0)
			#Game.inst.shader_mat.set_shader_parameter("scanlines_width", 0.4)
			Game.inst.shader_mat.set_shader_parameter("roll", true)
			Game.inst.shader_mat.set_shader_parameter("roll_speed", 5.0)
			Game.inst.shader_mat.set_shader_parameter("roll_size", 30.0)
			Game.inst.shader_mat.set_shader_parameter("distort_intensity", 0.2)
		Type.BUGS:
			if not Game.inst.new_game_created.is_connected(Game.inst.apply_bugs):
				Game.inst.new_game_created.connect(Game.inst.apply_bugs)
		Type.BIG_DASH:
			Player.dash_mod *= 1.75
		Type.FASTER_PLAYER:
			Player.speed *= 1.3
		Type.LAG: ## Random freezes
			var tween := Game.inst.create_tween().set_loops()
			tween.tween_callback(Game.inst.do_lag).set_delay(5)
			Game.inst.effect_tweens.append(tween)
		Type.UPSIDE_DOWN:
			Game.inst.new_game_created.connect(Game.inst.apply_upside_down)
		Type.CHROMATIC_ABERRATION:
			var tween := Game.inst.create_tween().set_loops()
			tween.tween_method(Game.inst.set_aberration, -.15, .17, 1.5).set_trans(Tween.TRANS_CUBIC)
			tween.tween_method(Game.inst.set_aberration, .17, -.15, 1.2).set_trans(Tween.TRANS_BACK)
			Game.inst.effect_tweens.append(tween)
		Type.INVISIBLE_SPIKES:
			if not Game.inst.new_game_created.is_connected(Game.inst.apply_invisible_spikes):
				Game.inst.new_game_created.connect(Game.inst.apply_invisible_spikes)
		Type.LOW_GRAVITY:
			Player.gravity *= 0.5
		Type.RANDOM_SPEEDS:
			var tween := create_tween().set_loops()
			tween.tween_property(Player, "random_speed_mod", 0.2, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(Player, "random_speed_mod", 1.0, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(Player, "random_speed_mod", 1.5, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(Player, "random_speed_mod", 5.5, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN)
			Game.inst.effect_tweens.append(tween)
		Type.NO_COINS:
			if not Game.inst.new_game_created.is_connected(Game.inst.apply_no_coins):
				Game.inst.new_game_created.connect(Game.inst.apply_no_coins)
		Type.SLOWER_PLAYER:
			Player.time_scale *= 0.6
		Type.HOZ_FLIP:
			Game.inst.new_game_created.connect(Game.inst.apply_flipped)

func insert():
	Game.inst.insert_coin(self)

func put_on_table():
	Game.inst.put_coin_on_table(self)

func trash():
	interactable = false
	var tween := create_tween().set_parallel()
	const DUR = 1.0
	tween.tween_property(self, "rotation", TAU * 5 * randf_range(-1.0, 1.0), DUR).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position:x", (-100 if randf() < 0.5 else 100) * randf_range(0.9, 1.2), DUR).set_trans(Tween.TRANS_BACK).set_delay(0.1)
	tween.tween_property(self, "position:y", 30 * randf_range(-1.2, 1.2), DUR).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(queue_free).set_delay(DUR)

func _on_button_pressed() -> void:
	if on_table:
		insert()
	else:
		put_on_table()


func _on_button_mouse_entered() -> void:
	if on_table:
		play("hover")
	if interactable:
		name_label.show()
		mult_label.show()


func _on_button_mouse_exited() -> void:
	if on_table:
		play("unhover")
	name_label.hide()
	mult_label.hide()


func _on_animation_finished() -> void:
	if animation == "unhover":
		animation = "on_table"
