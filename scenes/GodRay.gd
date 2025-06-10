extends ColorRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

var time := 0.0

func _process(delta):
	time += delta
	material.set_shader_param("u_time", time)
