extends Area2D

export var speed = 300
export var lifetime = 2.0
var direction = Vector2.ZERO  # Bullet flight direction

func _ready():
	# Set bullet lifetime
	$Timer.wait_time = lifetime
	$Timer.start()
	
	# Play appear animation
	$AnimationPlayer.play("appear")
	
	# Rotate bullet sprite according to direction
	if direction != Vector2.ZERO:
		$Sprite.rotation = direction.angle() + PI/2  # Adjust sprite facing to match flight direction

func _process(delta):
	# Bullet moves along set direction
	position += direction * speed * delta

func set_direction(dir):
	direction = dir.normalized()

func _on_BossSpike_body_entered(body):
	if body.name == "Player" and body.has_method("die"):
		body.take_damage(1)
	elif body.is_in_group("walls"):  # If hit wall
		queue_free()  # Destroy bullet

func _on_Timer_timeout():
	# Lifetime ended, destroy bullet
	queue_free()
