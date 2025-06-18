# PlayerStateMachine.gd - Fixed to avoid visual conflicts
extends Node

# 状态机控制器
var current_state = null
var states = {}
var player = null

func _ready():
	player = get_parent()
	
	# 创建所有状态实例
	states["idle"] = IdleState.new()
	states["walking"] = WalkingState.new()
	states["jumping"] = JumpingState.new()
	states["dashing"] = DashingState.new()
	states["sliding"] = SlidingState.new()
	
	# 为每个状态设置引用
	for state in states.values():
		state.player = player
		state.state_machine = self
	
	# 设置初始状态
	change_state("idle")

func _physics_process(delta):
	if current_state:
		current_state.update(delta)

func change_state(new_state_name):
	if current_state:
		current_state.exit()
	
	current_state = states[new_state_name]
	current_state.enter()
	print("State changed to: ", new_state_name)

func can_change_to_state(state_name):
	if current_state:
		return current_state.can_transition_to(state_name)
	return true

# ========================================
# 状态基类 - 修复版本
# ========================================
class StateBase:
	var player = null
	var state_machine = null
	
	func enter():
		pass
	
	func exit():
		pass
	
	func update(delta):
		pass
	
	func can_transition_to(state_name):
		return true
	
	# 通用方法
	func apply_gravity(delta):
		player.velocity.y += player.GRAVITY * delta
	
	func handle_ground_state():
		if player.is_on_floor():
			player.is_jumping = false
			player.jump_count = 0
			player.can_dash = true
			return true
		return false
	
	func handle_horizontal_movement(delta):
		var direction = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		var acc = player.ACCELERATION if player.is_on_floor() else player.AIR_ACCELERATION
		player.velocity.x = move_toward(player.velocity.x, direction * player.MAX_SPEED, acc * delta)
		
		if direction != 0:
			player.sprite.flip_h = direction < 0
		
		return direction
	
	func set_animation(anim_name):
		if player.animation_player:
			player.animation_player.play(anim_name)

# ========================================
# 具体状态类 - 移除所有视觉干预
# ========================================

# 待机状态
class IdleState extends StateBase:
	func enter():
		set_animation("idle")
	
	func update(delta):
		handle_ground_state()
		apply_gravity(delta)
		
		var direction = handle_horizontal_movement(delta)
		
		# 状态转换
		if Input.is_action_just_pressed("jump"):
			player.jump_request_timer.start()
			if player.is_on_floor() or player.coyote_timer.time_left > 0:
				state_machine.change_state("jumping")
		elif Input.is_action_just_pressed("dash") and player.can_dash:
			state_machine.change_state("dashing")
		elif Input.is_action_just_pressed("slide"):
			state_machine.change_state("sliding")
		elif abs(direction) > 0:
			state_machine.change_state("walking")
		
		player.velocity = player.move_and_slide(player.velocity, Vector2.UP)

# 行走状态
class WalkingState extends StateBase:
	func enter():
		set_animation("walk")
	
	func update(delta):
		handle_ground_state()
		apply_gravity(delta)
		
		var direction = handle_horizontal_movement(delta)
		
		# 状态转换
		if Input.is_action_just_pressed("jump"):
			player.jump_request_timer.start()
			if player.is_on_floor() or player.coyote_timer.time_left > 0:
				state_machine.change_state("jumping")
		elif Input.is_action_just_pressed("dash") and player.can_dash:
			state_machine.change_state("dashing")
		elif Input.is_action_just_pressed("slide"):
			state_machine.change_state("sliding")
		elif abs(direction) == 0:
			state_machine.change_state("idle")
		
		player.velocity = player.move_and_slide(player.velocity, Vector2.UP)

# 跳跃状态
class JumpingState extends StateBase:
	func enter():
		set_animation("jump")
		player.velocity.y = -player.JUMP_FORCE
		player.is_jumping = true
		player.jump_count = 1
		player.jump_request_timer.stop()
		player.coyote_timer.stop()
	
	func update(delta):
		apply_gravity(delta)
		handle_horizontal_movement(delta)
		
		# 可变跳跃高度
		if Input.is_action_just_released("jump") and player.velocity.y < -player.JUMP_FORCE / 2:
			player.velocity.y = -player.JUMP_FORCE / 2
		
		# 状态转换
		if Input.is_action_just_pressed("jump") and player.jump_count < player.jump_num:
			# 二段跳
			player.velocity.y = -player.JUMP_FORCE
			player.jump_count += 1
		elif Input.is_action_just_pressed("dash") and player.can_dash:
			state_machine.change_state("dashing")
		elif Input.is_action_just_pressed("slide"):
			state_machine.change_state("sliding")
		elif player.is_on_floor():
			# 落地转换
			var direction = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
			if abs(direction) > 0:
				state_machine.change_state("walking")
			else:
				state_machine.change_state("idle")
		
		player.velocity = player.move_and_slide(player.velocity, Vector2.UP)

# 冲刺状态
class DashingState extends StateBase:
	var dash_timer = 0.0
	
	func enter():
		# 获取冲刺方向
		var input_direction = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		).normalized()
		
		if input_direction == Vector2.ZERO:
			input_direction = Vector2(1 if not player.sprite.flip_h else -1, 0)
		
		player.dash_direction = input_direction
		player.can_dash = false
		dash_timer = player.DASH_DURATION
		player.ghost_spawn_timer = 0
	
	func update(delta):
		dash_timer -= delta
		
		# 生成鬼影效果
		player.ghost_spawn_timer -= delta
		if player.ghost_spawn_timer <= 0:
			player.create_ghost()
			player.ghost_spawn_timer = 0.05
		
		# 冲刺移动
		player.velocity = player.dash_direction * player.DASH_SPEED
		player.velocity = player.move_and_slide(player.velocity, Vector2.UP)
		
		# 状态转换
		if dash_timer <= 0:
			# 冲刺结束
			player.velocity = player.dash_direction * player.MAX_SPEED / 2
			
			if player.is_on_floor():
				var direction = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
				if abs(direction) > 0:
					state_machine.change_state("walking")
				else:
					state_machine.change_state("idle")
			else:
				state_machine.change_state("jumping")
		elif Input.is_action_just_pressed("slide"):
			state_machine.change_state("sliding")
	
	func can_transition_to(state_name):
		return state_name == "sliding"

# 滑铲状态 - 关键修复：移除所有视觉干预
class SlidingState extends StateBase:
	var slide_timer = 0.0
	
	func enter():
		print("Start slide")
		player.slide_direction = 1 if not player.sprite.flip_h else -1
		slide_timer = player.SLIDE_DURATION
		
		# 只设置旋转和碰撞盒，不干预颜色和可见性
		player.sprite.rotation = player.slide_direction * PI/6
		player.get_node("SlideBox/CollisionShape2D").disabled = false
		
		print("Slide started - rotation set, collision enabled")
	
	func update(delta):
		slide_timer -= delta
		
		if slide_timer <= 0:
			exit()
			
			if player.is_on_floor():
				var direction = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
				if abs(direction) > 0:
					state_machine.change_state("walking")
				else:
					state_machine.change_state("idle")
			else:
				state_machine.change_state("jumping")
		else:
			# 滑铲移动
			player.velocity.x = player.slide_direction * player.SLIDE_SPEED * (slide_timer / player.SLIDE_DURATION)
			player.velocity.y += player.GRAVITY * delta * 0.5
			player.velocity = player.move_and_slide(player.velocity, Vector2.UP)
	
	func exit():
		# 只恢复旋转和碰撞盒，完全不干预颜色和可见性
		player.get_node("SlideBox/CollisionShape2D").disabled = true
		player.sprite.rotation = 0
		
		print("Slide ended - rotation reset, collision disabled")
	
	func can_transition_to(state_name):
		return false
