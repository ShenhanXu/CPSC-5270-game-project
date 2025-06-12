extends MovementBase

# Enemy-specific properties
export var health: int = 1
export var patrol_points: Array = [Vector2.ZERO, Vector2(200, 0)]

# Enemy-specific state
var start_position: Vector2
var current_patrol_index: int = 0

func _ready():
	add_to_group("enemies")
	._ready()  # Call parent _ready

# Only implement the abstract methods
func initialize_movement():
	start_position = global_position
	current_patrol_index = 0

func get_current_target() -> Vector2:
	if patrol_points.empty():
		return Vector2.ZERO
	
	return start_position + patrol_points[current_patrol_index]

func on_target_reached():
	current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	start_waiting()

# Enemy-specific methods
func _on_Area2D_body_entered(body):
	if body.name == "Player":
		body.take_damage(1)

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()
