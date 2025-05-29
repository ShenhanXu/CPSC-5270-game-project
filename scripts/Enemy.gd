extends KinematicBody2D

export var speed = 100  
export var patrol_points = [Vector2.ZERO, Vector2(200, 0)]  
var current_point = 0  
var velocity = Vector2.ZERO
var start_position = Vector2.ZERO  

func _ready():
	start_position = position  

func _physics_process(delta):
	
	var target = start_position + patrol_points[current_point]
	
	var move_direction = (target - position).normalized()
	
	velocity = move_direction * speed
	
	velocity = move_and_slide(velocity)
	
	if position.distance_to(target) < 10:
		current_point = (current_point + 1) % patrol_points.size()
	
	if velocity.x != 0:
		$Sprite.flip_h = velocity.x < 0


func _on_Area2D_body_entered(body):
	if body.name == "Player":
		body.die()
