class_name MovementBase
extends KinematicBody2D

# Common properties
export var speed: float = 100.0
export var wait_time: float = 1.0

# Common state
var wait_timer: float = 0.0

func _ready():
	initialize_movement()

# TEMPLATE METHOD - This is the algorithm skeleton
func _physics_process(delta):
	# Step 1: Handle waiting
	if wait_timer > 0:
		wait_timer -= delta
		handle_waiting(delta)
		return
	
	# Step 2: Get target (implemented by subclasses)
	var target = get_current_target()
	if target == Vector2.ZERO:
		return
	
	# Step 3: Move toward target
	var direction = (target - global_position).normalized()
	var velocity = direction * speed
	
	# Step 4: Check if reached
	if global_position.distance_to(target) < 10.0:
		global_position = target
		on_target_reached()
	else:
		move_and_slide(velocity)

# ABSTRACT METHODS - Subclasses must implement these
func initialize_movement():
	# Override in subclasses
	pass

func get_current_target() -> Vector2:
	# Override in subclasses
	return Vector2.ZERO

func on_target_reached():
	# Override in subclasses
	pass

# HOOK METHOD - Optional override
func handle_waiting(delta):
	# Optional override in subclasses
	pass

# UTILITY METHODS
func start_waiting():
	wait_timer = wait_time

# ==========================================
# MovingPlatform.gd - ONLY the differences!
# ==========================================
