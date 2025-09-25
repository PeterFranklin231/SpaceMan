extends Camera2D

@export var target_body: RigidBody2D
@export var follow_speed: float = 5.0  # Higher = snappier follow

var zoom_level := 1.0
const MIN_ZOOM := 1.0
const MAX_ZOOM := 5.0
const ZOOM_STEP := 0.2

func _ready():
	update_zoom()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level += ZOOM_STEP
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level -= ZOOM_STEP

		zoom_level = clamp(zoom_level, MIN_ZOOM, MAX_ZOOM)
		update_zoom()

func update_zoom():
	zoom = Vector2(zoom_level, zoom_level)
	
func _process(delta: float) -> void:
	if target_body:
		global_position = global_position.lerp(target_body.global_position, delta * follow_speed)
