extends Camera2D

@export var target_body: RigidBody2D
@export var follow_speed: float = 5.0  # Higher = snappier follow

func _process(delta: float) -> void:
	if target_body:
		global_position = global_position.lerp(target_body.global_position, delta * follow_speed)
