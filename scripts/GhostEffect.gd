
extends Sprite

var alpha = 0.7  # Initial transparency
export var fade_speed = 10.0  # Fade out speed

func _process(delta):
	alpha -= fade_speed * delta
	modulate.a = alpha
	
	if alpha <= 0:
		queue_free()  # Delete node after completely transparent
