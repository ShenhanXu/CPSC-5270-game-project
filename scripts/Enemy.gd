extends KinematicBody2D

export var health = 1
export var speed = 100  # Movement speed
export var patrol_points = [Vector2.ZERO, Vector2(200, 0)]  # Patrol points in local coordinates
var current_point = 0  # Current target point index
var velocity = Vector2.ZERO
var start_position = Vector2.ZERO  # Starting position

func _ready():
	add_to_group("enemies")
	start_position = position  # Record initial position

func _physics_process(delta):
	# Calculate target position (convert local coordinates to global coordinates)
	var target = start_position + patrol_points[current_point]
	# Calculate movement direction
	var move_direction = (target - position).normalized()
	# Set velocity
	velocity = move_direction * speed
	# Move enemy
	velocity = move_and_slide(velocity)
	# Check if reached target point
	if position.distance_to(target) < 10:
		current_point = (current_point + 1) % patrol_points.size()
	# Update sprite direction
	if velocity.x != 0:
		$Sprite.flip_h = velocity.x < 0

func _on_Area2D_body_entered(body):
	if body.name == "Player":
		body.take_damage(1)

# Take damage
func take_damage(amount):
	health -= amount
	if health <= 0:
		die()
	else:
		# Can add hurt animation or sound effect
		pass

# Death
func die():
	# Can add death animation, drop items, etc.
	queue_free()
