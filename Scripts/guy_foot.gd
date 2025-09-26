extends RigidBody2D

var grabbing: bool = false
var _was_grabbing: bool = false
var grab_joint: PinJoint2D = null

@onready var grabarea: Area2D = $grab

func _physics_process(delta: float) -> void:
	if grabbing:
		# Try to grab if we don't already have a joint
		if not grab_joint:
			_try_grab()
	else:
		if grab_joint:
			_release_grab()

	_was_grabbing = grabbing

func _try_grab() -> void:
	if grab_joint or not grabarea:
		return

	var overlapping = grabarea.get_overlapping_bodies()
	for body in overlapping:
		if body == self or not body is RigidBody2D:
			continue

		var local_offset = Vector2(0, 18)  # 18 pixels down
		var contact_point = to_global(local_offset)

		# Create PinJoint2D at that offset position
		grab_joint = PinJoint2D.new()
		get_tree().current_scene.add_child(grab_joint)

		grab_joint.global_position = contact_point
		grab_joint.node_a = get_path()
		grab_joint.node_b = body.get_path()

		break  # Only grab one object


func _release_grab() -> void:
	if grab_joint:
		grab_joint.queue_free()
		grab_joint = null
