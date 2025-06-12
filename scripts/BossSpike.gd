extends Area2D

# Projectile properties
export var speed = 300  # Movement speed of the spike projectile
export var lifetime = 2.0  # How long the projectile exists before auto-destroying
export var tracking_strength = 6.0  # Initial tracking intensity (how aggressively it follows player)
export var tracking_duration = 1.5  # How long the projectile tracks the player

# Movement and targeting variables
var direction = Vector2.ZERO  # Current flight direction of the projectile
var player = null  # Reference to the player node
var tracking_timer = 0.0  # Timer counting down tracking duration
var is_tracking = true  # Whether the projectile is currently tracking the player

func _ready():
	# Set up automatic destruction timer
	$Timer.wait_time = lifetime
	$Timer.start()
	
	# Play appear animation if AnimationPlayer exists
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("appear")
	
	# Find player reference using multiple methods for reliability
	player = get_tree().get_nodes_in_group("player")[0] if get_tree().get_nodes_in_group("player").size() > 0 else null
	if player == null:
		# Backup method: search in parent node
		var world_node = get_parent()
		if world_node.has_node("Player"):
			player = world_node.get_node("Player")
	
	# Initialize tracking timer
	tracking_timer = tracking_duration
	
	# Set initial sprite rotation based on direction
	if direction != Vector2.ZERO and has_node("Sprite"):
		$Sprite.rotation = direction.angle() + PI/2  # Add 90 degrees to align sprite correctly

func _process(delta):
	# Update tracking timer
	if is_tracking:
		tracking_timer -= delta
		if tracking_timer <= 0:
			is_tracking = false  # Stop tracking after duration expires
	
	# Handle player tracking behavior
	if is_tracking and player != null:
		# Calculate direction vector pointing towards player
		var target_direction = (player.global_position - global_position).normalized()
		
		# Calculate decreasing tracking strength over time
		var time_progress = 1.0 - (tracking_timer / tracking_duration)  # Progress from 0 to 1
		var current_tracking_strength = tracking_strength * (1.0 - time_progress * 0.8)  # Reduce to 20% of original strength
		
		# Smoothly interpolate current direction towards target direction
		# This creates smooth turning rather than instant direction changes
		direction = direction.linear_interpolate(target_direction, current_tracking_strength * delta)
		direction = direction.normalized()
		
		# Update sprite rotation to match current direction
		if has_node("Sprite"):
			$Sprite.rotation = direction.angle() + PI/2
	
	# Move projectile along current direction
	position += direction * speed * delta

# Set initial direction when projectile is created
func set_direction(dir):
	direction = dir.normalized()
	# Immediately update sprite rotation when direction is set
	if has_node("Sprite") and direction != Vector2.ZERO:
		$Sprite.rotation = direction.angle() + PI/2

# Handle collision with objects
func _on_BossSpike_body_entered(body):
	# Check if collided with player
	if body.name == "Player" and body.has_method("take_damage"):
		# Deal spike damage to player (uses special damage type for visual effects)
		body.take_damage(1, true, "spike")
		queue_free()  # Destroy projectile after hitting player
	# Check if collided with walls or obstacles
	elif body.is_in_group("walls"):
		queue_free()  # Destroy projectile when hitting walls

# Handle automatic destruction when lifetime expires
func _on_Timer_timeout():
	queue_free()  # Remove projectile from scene
