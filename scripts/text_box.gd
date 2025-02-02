extends Label

class_name TextBox
const TEXT_BOX = preload("res://scenes/text_box.tscn")
static func display_dialogue(dialogue : String):
	var text_box : TextBox = TEXT_BOX.instantiate()
	text_box.text = dialogue
	text_box.visible_ratio = 0.0
	text_box.modulate.a = 0
	
	Game.inst.dialogue.add_child(text_box)
	
	var tween := text_box.create_tween()
	tween.tween_property(text_box, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(text_box, "visible_ratio", 1.0, len(dialogue) * 0.07).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(1.0)
	tween.tween_property(text_box, "modulate", Color(.4, .4, .4, 0), 0.75).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(text_box.queue_free)
	
