extends MovementBase

# Platform-specific properties
export var move_to: Vector2 = Vector2.ZERO

# Platform-specific state
var start_position: Vector2
var target_position: Vector2
var moving_to_target: bool = true

# Only implement the abstract methods
func initialize_movement():
	start_position = global_position
	target_position = start_position + move_to

func get_current_target() -> Vector2:
	return target_position if moving_to_target else start_position

func on_target_reached():
	moving_to_target = !moving_to_target
	start_waiting()
