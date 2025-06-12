extends KinematicBody2D

export var health = 3
export var speed = 100
export var dash_speed = 500
export var detection_range = 4000
var velocity = Vector2.ZERO
var player = null
var state = "idle"
var attack_cooldown = 0
var dash_direction = Vector2.ZERO
var is_dashing = false
var dash_timer = 0
var spike_scene = preload("res://scenes/BossSpike.tscn")

# Add damage cooldown to prevent continuous damage
var damage_cooldown = 0.0
var damage_cooldown_time = 1.0  # No repeated damage within 1 second
var slide_damage_cooldown = 0.0  # Slide damage specific cooldown
var slide_damage_cooldown_time = 1.5  # Slide damage cooldown time is longer
var is_hurt = false  # Whether Boss is in hurt state
var hurt_timer = 0.0  # Hurt state timer

# Death shader material
var death_material = null

func _ready():
	add_to_group("enemies")
	# Find player node
	player = get_parent().get_node("Player")

	death_material = preload("res://materials/boss_die_materials.tres")

func _physics_process(delta):
	if player == null or not is_physics_processing():
		return
	
	# Update damage cooldown
	if damage_cooldown > 0:
		damage_cooldown -= delta
	if slide_damage_cooldown > 0:
		slide_damage_cooldown -= delta
	
	# Update hurt state
	if is_hurt:
		hurt_timer -= delta
		if hurt_timer <= 0:
			is_hurt = false
			state = "idle"  # Return to idle after hurt
		else:
			# During hurt state, only apply knockback movement
			velocity = move_and_slide(velocity)
			return  # Skip normal AI logic during hurt
		
	# Calculate distance to player
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Only use distance detection to avoid multiple collisions
	check_player_collision()
	
	# Attack cooldown timer
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	match state:
		"idle":
			$Sprite.play("idle")
			# In idle state, always move towards player (增强跟随)
			if distance_to_player < detection_range:
				var direction = (player.global_position - global_position).normalized()
				velocity = direction * speed
				print("Boss following player - Distance: ", distance_to_player)  # 调试信息
				
				# Choose attack method
				if attack_cooldown <= 0:
					if distance_to_player < 200:
						# Use dash attack at close range
						start_dash_attack()
					else:
						# Use spike attack at long range
						start_spike_attack()
					attack_cooldown = 3.0  # 3 second cooldown
			else:
				# 即使超出检测范围也跟随（可选）
				var direction = (player.global_position - global_position).normalized()
				velocity = direction * speed * 0.5  # 慢速跟随
				print("Boss slow following - Distance: ", distance_to_player)
				
		"dash_attack":
			if is_dashing:
				dash_timer -= delta
				if dash_timer <= 0:
					is_dashing = false
					state = "idle"
					$Sprite.rotation = 0  # Return to upright
				else:
					$Sprite.play("attack")
					velocity = dash_direction * dash_speed
					
		"spike_attack":
			# Spike attack state is just a brief state, return to idle immediately after generating spikes
			$Sprite.play("attack")
			state = "idle"
	
	# Update sprite direction
	if velocity.x != 0 and state != "dash_attack":
		$Sprite.flip_h = velocity.x < 0
	
	# Apply movement
	velocity = move_and_slide(velocity)

# Check direct collision with player - but avoid duplication with Player slide attack
func check_player_collision():
	# If Boss is in enemies group, Player's slide will directly call take_damage
	# So here we only handle non-slide collisions
	if player == null or not is_physics_processing():
		return
		
	# Check distance between Boss and player
	var distance = global_position.distance_to(player.global_position)
	
	# If distance is close (indicates collision)
	if distance < 80:
		# Only handle collisions when player is not sliding AND not invincible
		if not ("is_sliding" in player and player.is_sliding) and not ("invincible_time" in player and player.invincible_time > 0):
			# Normal collision, player takes damage
			if damage_cooldown <= 0:
				if player.has_method("take_damage"):
					player.take_damage(1)  # Default shows animation for passive damage
					damage_cooldown = damage_cooldown_time
					print("Boss deals damage!")
					apply_knockback_to_player()
			else:
				print("Boss damage on cooldown")

# Apply knockback effect to player
func apply_knockback_to_player():
	if player == null:
		return
		
	# Calculate knockback direction (from Boss to player)
	var knockback_direction = (player.global_position - global_position).normalized()
	
	# If player has velocity property, modify directly
	if player.has_method("apply_knockback"):
		player.apply_knockback(knockback_direction * 300)
	elif "velocity" in player:
		# Directly set player velocity to achieve knockback
		player.velocity += knockback_direction * 300

# Start dash attack
func start_dash_attack():
	state = "dash_attack"
	dash_direction = (player.global_position - global_position).normalized()
	is_dashing = true
	dash_timer = 1.0  # Dash lasts 1 second
	
	# Rotate sprite
	var rotation_angle = PI/4  # 45 degrees
	$Sprite.rotation = -rotation_angle if dash_direction.x > 0 else rotation_angle

# Start spike attack (now bullet attack)
func start_spike_attack():
	state = "spike_attack"
	
	# Create bullet instance
	var bullet = spike_scene.instance()
	get_parent().add_child(bullet)
	
	# Set bullet position to Boss position
	bullet.global_position = global_position
	
	# Calculate direction towards player
	var direction = (player.global_position - global_position).normalized()
	
	# Set bullet flight direction
	bullet.set_direction(direction)

# Take damage - add slide damage cooldown check
func take_damage(amount):
	# Check slide damage cooldown
	if slide_damage_cooldown > 0:
		print("Boss slide damage on cooldown, ignoring damage")
		return
		
	print("=== Boss takes damage ===")
	print("Damage amount: ", amount)
	print("Current health: ", health)
	
	health -= amount
	print("Health after damage: ", health)
	print("==================")
	
	# Set slide damage cooldown
	slide_damage_cooldown = slide_damage_cooldown_time
	print("Set slide damage cooldown: ", slide_damage_cooldown_time, " seconds")
	
	if health <= 0:
		die()
	else:
		# Add hurt knockback effect - Boss moves away from player
		if has_node("AnimationPlayer"):
			$AnimationPlayer.play("flash")
		if player != null:
			# Calculate direction from player to Boss (direction Boss should be knocked back)
			var knockback_direction = (global_position - player.global_position).normalized()
			# Apply stronger knockback force to move Boss away from player
			velocity = knockback_direction * 600  # Strong knockback force
			# Set hurt state to pause normal AI
			is_hurt = true
			hurt_timer = 0.5  # Hurt state lasts 0.5 seconds
			print("Boss knocked back away from player")

# Death - 新的死亡效果
func die():
	print("Boss dies! Starting death animation...")
	# 确保Boss不能再受到伤害
	set_physics_process(false)
	
	# 应用死亡shader效果
	apply_death_effect()

# 新的死亡效果函数
func apply_death_effect():
	# 应用shader材质
	var shader_instance = death_material.duplicate()
	$Sprite.material = shader_instance
	
	# 创建Tween控制死亡动画
	var tween = Tween.new()
	add_child(tween)
	
	# 死亡进度动画 (0到1，持续2秒)
	tween.interpolate_method(self, "_update_death_progress", 0.0, 1.0, 2.0, Tween.TRANS_CUBIC, Tween.EASE_IN)
	
	# 缩放效果 - 先放大再缩小
	tween.interpolate_property($Sprite, "scale", Vector2(0.5, 0.5), Vector2(0.8, 0.8), 0.5, Tween.TRANS_BACK, Tween.EASE_OUT)
	tween.interpolate_property($Sprite, "scale", Vector2(0.8, 0.8), Vector2(0.2, 0.2), 1.5, Tween.TRANS_CUBIC, Tween.EASE_IN, 0.5)
	
	# 旋转效果 - 两圈旋转
	tween.interpolate_property($Sprite, "rotation_degrees", 0, 720, 2.0, Tween.TRANS_CUBIC, Tween.EASE_IN)
	
	# 轻微上升效果
	var current_pos = global_position
	var target_pos = current_pos + Vector2(0, -50)
	tween.interpolate_property(self, "global_position", current_pos, target_pos, 1.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	
	# 添加屏幕震动
	add_screen_shake()
	
	# 动画完成后切换场景
	tween.connect("tween_all_completed", self, "_on_death_animation_finished")
	tween.start()
	
	# 可以添加死亡音效
	# $DeathSound.play()

func _update_death_progress(progress):
	# 更新shader的死亡进度参数
	if $Sprite.material:
		$Sprite.material.set_shader_param("death_progress", progress)

func add_screen_shake():
	# 获取摄像机
	var camera = get_node("../Player/Camera2D")
	if camera == null:
		return
	
	# 创建震动Tween
	var shake_tween = Tween.new()
	add_child(shake_tween)
	
	# 震动效果 - 15次震动，每次0.05秒
	for i in range(15):
		var shake_offset = Vector2(
			rand_range(-8, 8),
			rand_range(-8, 8)
		)
		var delay = i * 0.1  # 每0.1秒一次震动
		
		shake_tween.interpolate_property(
			camera, "offset",
			camera.offset, shake_offset,
			0.05, Tween.TRANS_CUBIC, Tween.EASE_OUT, delay
		)
		
		shake_tween.interpolate_property(
			camera, "offset",
			shake_offset, Vector2.ZERO,
			0.05, Tween.TRANS_CUBIC, Tween.EASE_IN, delay + 0.05
		)
	
	shake_tween.start()

func _on_death_animation_finished():
	print("Boss death animation completed! Switching to victory scene...")
	queue_free()
	# 切换到胜利场景
	if ResourceLoader.exists("res://scenes/WinScene.tscn"):
		get_tree().change_scene("res://scenes/WinScene.tscn")
	elif ResourceLoader.exists("res://scenes/Victory.tscn"):
		get_tree().change_scene("res://scenes/Victory.tscn")
	elif ResourceLoader.exists("res://scenes/win.tscn"):
		get_tree().change_scene("res://scenes/win.tscn")
	else:
		print("Victory scene not found, returning to main menu")
		get_tree().change_scene("res://scenes/StartScene.tscn")

# Hurt timer timeout handler
func _on_HurtTimer_timeout():
	state = "idle"  # Return to idle state
