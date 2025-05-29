extends KinematicBody2D

export var move_to = Vector2.ZERO 
export var speed = 100.0          
export var wait_time = 1.0        

var start_position = Vector2.ZERO
var target_position = Vector2.ZERO
var moving_to_target = true
var wait_timer = 0.0

func _ready():
	start_position = position
	target_position = position + move_to

func _physics_process(delta):
	if wait_timer > 0:
		wait_timer -= delta
		return
	
	var target = target_position if moving_to_target else start_position
	var direction = (target - position).normalized()
	var velocity = direction * speed
	
	if position.distance_to(target) < speed * delta:
		position = target
		moving_to_target = !moving_to_target
		wait_timer = wait_time
	else:
		position += velocity * delta
