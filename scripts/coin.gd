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
	RANDOM_TELEPORTS,
	RANDOM_SPEEDS,
}

var type : Type

const TYPE_TO_MULT : Dictionary[Type, float] = {
	Type.REVERSED_CONTROLS : 1.3,
	Type.STATIC : 1.3,
	Type.SCAN_LINES : 1.3,
	Type.BUGS : 1.3,
	Type.BIG_DASH : 1.3,
	Type.FASTER_PLAYER : 1.3,
	Type.LAG : 1.3, ## Random freezes
	Type.UPSIDE_DOWN : 1.3,
	Type.CHROMATIC_ABERRATION : 1.3,
	Type.INVISIBLE_SPIKES : 1.3,
	Type.LOW_GRAVITY : 0.8,
	Type.RANDOM_TELEPORTS : 1.3,
	Type.RANDOM_SPEEDS : 1.3,
}

const TYPE_TO_NAME: Dictionary[Type, String] = {
	Type.REVERSED_CONTROLS : "PLACEHOLDER NAME",
	Type.STATIC : "PLACEHOLDER NAME",
	Type.SCAN_LINES : "PLACEHOLDER NAME",
	Type.BUGS : "PLACEHOLDER NAME",
	Type.BIG_DASH : "PLACEHOLDER NAME",
	Type.FASTER_PLAYER : "PLACEHOLDER NAME",
	Type.LAG : "PLACEHOLDER NAME", ## Random freezes
	Type.UPSIDE_DOWN : "PLACEHOLDER NAME",
	Type.CHROMATIC_ABERRATION : "PLACEHOLDER NAME",
	Type.INVISIBLE_SPIKES : "PLACEHOLDER NAME",
	Type.LOW_GRAVITY : "PLACEHOLDER NAME",
	Type.RANDOM_TELEPORTS : "PLACEHOLDER NAME",
	Type.RANDOM_SPEEDS : "PLACEHOLDER NAME",
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
	Type.RANDOM_TELEPORTS : Color.WHITE,
	Type.RANDOM_SPEEDS : Color.WHITE,
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
		while Game.inst.coin_type_in_hand(new_coin.type):
			new_coin.type = randi_range(0, Type.size())
		coins.append(new_coin)
	return coins

func _ready() -> void:
	pick_mult()
	pick_name()
	pick_color()
	

func _physics_process(delta: float) -> void:
	button.disabled = not interactable
	

func pick_mult():
	multiplier = TYPE_TO_MULT[type]
	mult_label.text = "x" + str(multiplier).pad_decimals(1)
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
			pass
		Type.STATIC:
			pass
		Type.SCAN_LINES:
			pass
		Type.BUGS:
			pass
		Type.BIG_DASH:
			pass
		Type.FASTER_PLAYER:
			pass
		Type.LAG: ## Random freezes
			pass
		Type.UPSIDE_DOWN:
			pass
		Type.CHROMATIC_ABERRATION:
			pass
		Type.INVISIBLE_SPIKES:
			pass
		Type.LOW_GRAVITY:
			pass
		Type.RANDOM_TELEPORTS:
			pass
		Type.RANDOM_SPEEDS:
			pass

func insert():
	Game.inst.insert_coin(self)

func put_on_table():
	Game.inst.put_coin_on_table(self)

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


func _on_button_mouse_exited() -> void:
	if on_table:
		play("unhover")
	name_label.hide()
