extends AnimatedSprite2D

func _process(_delta: float) -> void:
	if level.pointer_style == 0:
		animation = "pointer"
	elif level.pointer_style == 1:
		animation = "pointer_full"
