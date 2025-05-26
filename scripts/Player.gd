extends KinematicBody2D

const GRAVITY = 2000
const MAX_SPEED = 350
const JUMP_FORCE = 800
const ACCELERATION = MAX_SPEED / 0.2
const AIR_ACCELERATION = MAX_SPEED / 0.05
const DASH_SPEED = 1000  
const DASH_DURATION = 0.2  

var velocity = Vector2.ZERO
var is_jumping = false
var jump_count = 0
export var jump_num = 2
var score = 0
var is_dashing = false 
var dash_timer = 0.0  
var can_dash = true  
var dash_direction = Vector2.ZERO  
var ghost_spawn_timer = 0.0 


signal update_score(new_score)

onready var animation_player = $AnimationPlayer
onready var sprite = $Sprite
onready var coyote_timer = $CoyoteTimer
onready var jump_request_timer = $JumpRequestTimer


var GhostScene = preload("res://scenes/GhostEffect.tscn")  

var dead = false


var input_enabled = true


func set_input_enabled(enabled):
	input_enabled = enabled


func _physics_process(delta):
	if dead or not input_enabled:
		return
	

	if is_dashing:
		ghost_spawn_timer -= delta
		if ghost_spawn_timer <= 0:
			create_ghost()
			ghost_spawn_timer = 0.05  
	

	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity = dash_direction * MAX_SPEED / 2  
		else:
			velocity = dash_direction * DASH_SPEED
			velocity = move_and_slide(velocity, Vector2.UP)
			return  
			
	var was_on_floor = is_on_floor()
	if is_on_floor():
		is_jumping = false
		jump_count = 0  
		can_dash = true  
	elif was_on_floor and not is_jumping:
		coyote_timer.start()

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
		jump_count = 1  
		jump_request_timer.stop()
		coyote_timer.stop()

	if Input.is_action_just_pressed("jump"):
		if not can_jump and jump_count < jump_num:  
			velocity.y = -JUMP_FORCE
			jump_count += 1  
		else:
			jump_request_timer.start()

	if Input.is_action_just_released("jump") and velocity.y < -JUMP_FORCE / 2:
		velocity.y = -JUMP_FORCE / 2


	if is_jumping:
		animation_player.play("jump")
	elif velocity.x == 0:
		animation_player.play("idle")
	else:
		animation_player.play("walk")


	if direction != 0:
		sprite.flip_h = direction < 0


	velocity = move_and_slide(velocity, Vector2.UP)


func add_score(amount):
	score += amount

	emit_signal("update_score", score)
	print("Current Socre: ", score)  


func start_dash():
	var input_direction = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()
	

	if input_direction == Vector2.ZERO:
		input_direction = Vector2(1 if not sprite.flip_h else -1, 0)
	
	dash_direction = input_direction
	is_dashing = true
	can_dash = false  
	dash_timer = DASH_DURATION
	ghost_spawn_timer = 0  
	



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

func die():
	animation_player.play("die")
	dead = true
	yield(get_tree().create_timer(1.0), "timeout")
	get_tree().change_scene("res://scenes/World.tscn")


func _on_VisibilityNotifier2D_screen_exited():
	animation_player.play("die")
	dead = true
	yield(get_tree().create_timer(1.0), "timeout")
	get_tree().change_scene("res://scenes/World.tscn")
