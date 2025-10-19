extends Sprite2D

func _process(_delta: float) -> void:
	$"Look Text".text = level.look_text
	if level.look_text == "":
		visible = false
	else:
		visible = true
