extends Sprite

var alpha = 0.7  
export var fade_speed = 10.0  

func _process(delta):
	alpha -= fade_speed * delta
	modulate.a = alpha
	
	if alpha <= 0:
		queue_free() 
