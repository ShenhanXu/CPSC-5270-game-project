# Player.gd - Simplified Fix (No Complex Shader Management)
extends KinematicBody2D

# Physics constants - 状态机需要访问这些
const GRAVITY = 2000
const MAX_SPEED = 350
const JUMP_FORCE = 800
const ACCELERATION = MAX_SPEED / 0.2
const AIR_ACCELERATION = MAX_SPEED / 0.05
const DASH_SPEED = 1000
const DASH_DURATION = 0.2
const SLIDE_SPEED = 800
const SLIDE_DURATION = 0.5

# Player stats
export var health = 3
var velocity = Vector2.ZERO
var is_jumping = false
var jump_count = 0
export var jump_num = 2
var score = 0

# State machine会使用这些变量
var can_dash = true
var dash_direction = Vector2.ZERO
var ghost_spawn_timer = 0.0
var slide_direction = 0

# Invincibility system
var invincible_time = 0.0
var invincible_duration = 1

# Signals
signal update_score(new_score)

# Node references
onready var animation_player = $AnimationPlayer
onready var sprite = $Sprite
onready var coyote_timer = $CoyoteTimer
onready var jump_request_timer = $JumpRequestTimer
onready var state_machine = $StateMachine  # 状态机节点

# Preloaded scenes
var GhostScene = preload("res://scenes/GhostEffect.tscn")

# Game state variables
var dead = false
var input_enabled = true

func _ready():
	add_to_group("player")

func set_input_enabled(enabled):
	input_enabled = enabled

func _physics_process(delta):
	if dead or not input_enabled:
		return
	
	# 处理无敌时间和视觉效果
	update_invincibility(delta)

func update_invincibility(delta):
	if invincible_time > 0:
		invincible_time -= delta
		# Simple blinking effect - no shader needed
		sprite.modulate.a = 0.5 if int(invincible_time * 10) % 2 == 0 else 1.0
	else:
		# Always ensure normal visibility
		sprite.modulate = Color(1, 1, 1, 1)
		sprite.visible = true

# Ensure sprite is always visible (called by states)
func ensure_sprite_visible():
	sprite.visible = true
	if invincible_time <= 0:
		sprite.modulate = Color(1, 1, 1, 1)

# Set base color safely (used by states)
func set_base_modulate(color: Color):
	if invincible_time <= 0:
		sprite.modulate = color

# Create ghost effect for dash
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

# Add score and emit signal to UI
func add_score(amount):
	Global.score += amount
	emit_signal("update_score", Global.score)
	print("Current score: ", Global.score)

# Simple damage system - no complex shader effects
func take_damage(amount, show_animation = true, damage_type = "normal"):
	if invincible_time > 0:
		print("Player invincible, ignoring damage! Remaining: ", invincible_time, " seconds")
		return
		
	health -= amount
	$HealthBar.value = health
	
	invincible_time = invincible_duration
	print("Player hurt! Set invincible time: ", invincible_duration, " seconds")
	
	if health <= 0:
		die()
	else:
		if show_animation:
			# Simple flash animation using AnimationPlayer only
			$AnimationPlayer.play("flash")
			
			# Simple color flash effect
			start_simple_damage_flash()

# Simple damage flash using color modulation only
func start_simple_damage_flash():
	# Flash red briefly
	sprite.modulate = Color(1.5, 0.5, 0.5, 1)  # Red tint
	
	# Create a simple timer to restore color
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.2
	timer.one_shot = true
	timer.connect("timeout", self, "_on_damage_flash_finished", [timer])
	timer.start()

func _on_damage_flash_finished(timer):
	# Restore normal color
	if invincible_time <= 0:
		sprite.modulate = Color(1, 1, 1, 1)
	
	# Clean up timer
	timer.queue_free()

# Apply knockback force (optional)
func apply_knockback(force):
	if invincible_time <= 0:
		velocity += force

# Handle player death
func die():
	# Ensure normal appearance
	sprite.modulate = Color(1, 1, 1, 1)
	sprite.visible = true
	
	animation_player.play("die")
	dead = true
	yield(get_tree().create_timer(1.0), "timeout")
	get_tree().change_scene("res://scenes/EndScene.tscn")

# Handle falling off screen
func _on_VisibilityNotifier2D_screen_exited():
	animation_player.play("die")
	dead = true
	yield(get_tree().create_timer(1.0), "timeout")
	get_tree().change_scene("res://scenes/EndScene.tscn")

# Slide collision handling
func _on_SlideBox_body_entered(body):
	print("Slide collision with: ", body.name)
	if body == self:
		print("Ignore self")
		return
	
	if body.has_method("take_damage") and body != self:
		if body.is_in_group("enemies") or body.name.begins_with("Enemy") or body.name == "Boss":
			print("Deal damage to enemy: ", body.name)
			body.take_damage(1)
			invincible_time = 1.0
			print("Player gains invincibility after attack: 1 second")
		else:
			print("Not enemy, no damage: ", body.name)

func _on_SlideBox_area_entered(area):
	print("Slide area collision with: ", area.name)
	if area.get_parent() == self:
		print("Ignore own area")
		return
		
	if area.has_method("take_damage"):
		if area.is_in_group("enemies") or area.name.begins_with("Enemy") or area.name == "Boss":
			print("Deal damage to enemy area: ", area.name)
			area.take_damage(1)
			invincible_time = 1.0
			print("Player gains invincibility after attack: 1 second")
		else:
			print("Not enemy area, no damage: ", area.name)
