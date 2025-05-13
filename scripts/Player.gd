extends KinematicBody2D

const GRAVITY = 2000
const MAX_SPEED = 350
const JUMP_FORCE = 800
const ACCELERATION = MAX_SPEED / 0.2
const AIR_ACCELERATION = MAX_SPEED / 0.05

var velocity = Vector2.ZERO
var is_jumping = false

onready var animation_player = $AnimationPlayer
onready var sprite = $Sprite
onready var coyote_timer = $CoyoteTimer
onready var jump_request_timer = $JumpRequestTimer

func _physics_process(delta):
	var was_on_floor = is_on_floor()
	if is_on_floor():
		is_jumping = false
	elif was_on_floor and not is_jumping:
		coyote_timer.start()

	var direction = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var acc = ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, direction * MAX_SPEED, acc * delta)
	velocity.y += GRAVITY * delta

	var can_jump = is_on_floor() or coyote_timer.time_left > 0
	if can_jump and jump_request_timer.time_left > 0:
		velocity.y = -JUMP_FORCE
		is_jumping = true
		jump_request_timer.stop()
		coyote_timer.stop()

	if Input.is_action_just_pressed("jump"):
		jump_request_timer.start()

	if Input.is_action_just_released("jump") and velocity.y < -JUMP_FORCE / 2:
		velocity.y = -JUMP_FORCE / 2

	# 动画处理
	if is_jumping:
		animation_player.play("jump")
	elif velocity.x == 0:
		animation_player.play("idle")
	else:
		animation_player.play("walk")

	# 翻转精灵朝向
	if direction != 0:
		sprite.flip_h = direction < 0

	# 移动角色
	velocity = move_and_slide(velocity, Vector2.UP)
