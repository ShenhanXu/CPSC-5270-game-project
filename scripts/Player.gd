extends KinematicBody2D

const GRAVITY = 2000
const MAX_SPEED = 350
const JUMP_FORCE = 800
const ACCELERATION = MAX_SPEED / 0.2
const AIR_ACCELERATION = MAX_SPEED / 0.05
const DASH_SPEED = 1000  # Dash speed
const DASH_DURATION = 0.2  # Dash duration

const SLIDE_SPEED = 800  # Slide initial speed
const SLIDE_DURATION = 0.5  # Slide duration

var is_sliding = false  # Whether sliding
var slide_timer = 0.0  # Slide timer
var slide_direction = 0  # Slide direction

export var health = 3

var velocity = Vector2.ZERO
var is_jumping = false
var jump_count = 0
export var jump_num = 2
var score = 0
var is_dashing = false  # Whether dashing
var dash_timer = 0.0  # Dash timer
var can_dash = true  # Whether can dash
var dash_direction = Vector2.ZERO  # Dash direction
var ghost_spawn_timer = 0.0  # Ghost spawn timer

# Invincibility system
var invincible_time = 0.0  # Invincible time
var invincible_duration = 1  # Invincible for 1 second after taking damage

# Define signals
signal update_score(new_score)

onready var animation_player = $AnimationPlayer
onready var sprite = $Sprite
onready var coyote_timer = $CoyoteTimer
onready var jump_request_timer = $JumpRequestTimer

# Add preloaded scene
var GhostScene = preload("res://scenes/GhostEffect.tscn")  # Need to create this scene

var dead = false

# Add variable to control input state
var input_enabled = true

# Add method to set input state
func set_input_enabled(enabled):
	input_enabled = enabled

# Check input state in input processing function
func _physics_process(delta):
	if dead or not input_enabled:
		return
	
	# Update invincible time
	if invincible_time > 0:
		invincible_time -= delta
		# Blinking effect during invincibility
		sprite.modulate.a = 0.5 if int(invincible_time * 10) % 2 == 0 else 1.0
	else:
		# Restore normal transparency (but consider slide settings)
		if not is_sliding:
			sprite.modulate.a = 1.0
	
	# Handle dash ghost generation
	if is_dashing:
		ghost_spawn_timer -= delta
		if ghost_spawn_timer <= 0:
			create_ghost()
			ghost_spawn_timer = 0.05  # Generate ghost every 0.05 seconds
	
	# Handle slide logic - fixed version
	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			# Slide ends, restore normal state
			$SlideBox/CollisionShape2D.disabled = true
			is_sliding = false
			sprite.rotation = 0  # Restore character upright
			sprite.visible = true  # Ensure visible
			# Restore transparency, but consider invincible time
			if invincible_time <= 0:
				sprite.modulate = Color(1, 1, 1, 1)  # Ensure opaque
			print("Slide ends")
		else:
			velocity.x = slide_direction * SLIDE_SPEED * (slide_timer / SLIDE_DURATION)  # Slide speed decays over time
			velocity.y += GRAVITY * delta * 0.5  # Gravity effect halved during slide
			velocity = move_and_slide(velocity, Vector2.UP)
			$SlideBox/CollisionShape2D.disabled = false
			# Ensure character visible during slide
			sprite.visible = true
			return  # Slide not affected by other movement logic
	
	# Handle dash logic
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity = dash_direction * MAX_SPEED / 2  # Maintain some speed after dash ends
		else:
			velocity = dash_direction * DASH_SPEED
			velocity = move_and_slide(velocity, Vector2.UP)
			return  # Dash not affected by other movement logic
	
	# Handle slide input - allow sliding in air
	if Input.is_action_just_pressed("slide") and not is_sliding and not is_dashing:
		start_slide()
	
	var was_on_floor = is_on_floor()
	if is_on_floor():
		is_jumping = false
		jump_count = 0  # Reset jump count on ground
		can_dash = true  # Can dash again after landing
	elif was_on_floor and not is_jumping:
		coyote_timer.start()

	# Handle dash input
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		start_dash()

	var direction = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var acc = ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, direction * MAX_SPEED, acc * delta)
	velocity.y += GRAVITY * delta

	var can_jump = is_on_floor() or coyote_timer.time_left > 0
	if can_jump and jump_request_timer.time_left > 0:
		velocity.y = -JUMP_FORCE
		is_jumping = true
		jump_count = 1  # First jump
		jump_request_timer.stop()
		coyote_timer.stop()

	if Input.is_action_just_pressed("jump"):
		if not can_jump and jump_count < jump_num:  # Check if can double jump
			velocity.y = -JUMP_FORCE
			jump_count += 1  # Second jump
		else:
			jump_request_timer.start()

	if Input.is_action_just_released("jump") and velocity.y < -JUMP_FORCE / 2:
		velocity.y = -JUMP_FORCE / 2

	# Animation handling
	if is_jumping:
		animation_player.play("jump")
	elif velocity.x == 0:
		animation_player.play("idle")
	else:
		animation_player.play("walk")

	# Flip sprite direction
	if direction != 0:
		sprite.flip_h = direction < 0

	# Move character
	velocity = move_and_slide(velocity, Vector2.UP)

# Method to add score
func add_score(amount):
	Global.score += amount
	# Emit signal to notify UI update
	emit_signal("update_score", Global.score)
	print("Current score: ", Global.score)  # Temporary print score, can replace with UI display later

# Start dash
func start_dash():
	var input_direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	
	# If no input direction, use character facing direction
	if input_direction == Vector2.ZERO:
		input_direction = Vector2(1 if not sprite.flip_h else -1, 0)
	
	dash_direction = input_direction
	is_dashing = true
	can_dash = false  # Need to land to dash again after dashing
	dash_timer = DASH_DURATION
	ghost_spawn_timer = 0  # Start generating ghosts immediately
	
	# Can add dash sound effect here
	# $DashSound.play()

# Create ghost effect
func create_ghost():
	var ghost = GhostScene.instance()
	get_parent().add_child(ghost)
	ghost.global_position = global_position
	ghost.texture = sprite.texture
	ghost.flip_h = sprite.flip_h
	ghost.hframes = sprite.hframes
	ghost.vframes = sprite.vframes
	ghost.frame = sprite.frame
	ghost.scale = sprite.scale

# Take damage - add invincible time check and optional animation control
func take_damage(amount, show_animation = true):
	# Check invincible time
	if invincible_time > 0:
		print("Player invincible, ignoring damage! Remaining: ", invincible_time, " seconds")
		return
		
	health -= amount
	$HealthBar.value = health
	
	# Set invincible time
	invincible_time = invincible_duration
	print("Player hurt! Set invincible time: ", invincible_duration, " seconds")
	
	if health <= 0:
		die()
	else:
		# Only play hurt animation when show_animation is true (passive damage)
		if show_animation:
			$AnimationPlayer.play("flash")
		# Can add hurt sound effect
		pass

# Add knockback effect (optional)
func apply_knockback(force):
	# Only knockback when not in invincible time
	if invincible_time <= 0:
		velocity += force

func die():
	animation_player.play("die")
	dead = true
	yield(get_tree().create_timer(1.0), "timeout")
	get_tree().change_scene("res://scenes/EndScene.tscn")

func _on_VisibilityNotifier2D_screen_exited():
	animation_player.play("die")
	dead = true
	yield(get_tree().create_timer(1.0), "timeout")
	get_tree().change_scene("res://scenes/EndScene.tscn")

# Start slide - fixed version (works in air and on ground)
func start_slide():
	print("Start slide")
	slide_direction = 1 if not sprite.flip_h else -1
	is_sliding = true
	slide_timer = SLIDE_DURATION
	
	# Character tilt
	sprite.rotation = slide_direction * PI/6  # 30 degree tilt
	# Ensure sprite visible
	sprite.visible = true
	sprite.modulate = Color(1, 1, 1, 1)  # Ensure opaque
	
	$SlideBox/CollisionShape2D.disabled = false
	# Play slide animation (if available)
	# animation_player.play("slide")
	
	# Can add slide sound effect here
	# $SlideSound.play()

# Fixed slide collision detection - add stricter enemy judgment
func _on_SlideBox_body_entered(body):
	print("Slide collision with: ", body.name)
	# Ensure not attacking self
	if body == self:
		print("Ignore self")
		return
	
	# Check if collision object is enemy - add more judgment conditions
	if body.has_method("take_damage") and body != self:
		# Can add enemy tag or group judgment
		if body.is_in_group("enemies") or body.name.begins_with("Enemy") or body.name == "Boss":
			print("Deal damage to enemy: ", body.name)
			body.take_damage(1)
			# Give player 1 second invincibility after dealing damage (no animation)
			invincible_time = 1.0
			print("Player gains invincibility after attack: 1 second")
		else:
			print("Not enemy, no damage: ", body.name)

func _on_SlideBox_area_entered(area):
	print("Slide area collision with: ", area.name)
	# Ensure not attacking own area
	if area.get_parent() == self:
		print("Ignore own area")
		return
		
	if area.has_method("take_damage"):
		# Add enemy judgment
		if area.is_in_group("enemies") or area.name.begins_with("Enemy") or area.name == "Boss":
			print("Deal damage to enemy area: ", area.name)
			area.take_damage(1)
			# Give player 1 second invincibility after dealing damage (no animation)
			invincible_time = 1.0
			print("Player gains invincibility after attack: 1 second")
		else:
			print("Not enemy area, no damage: ", area.name)
