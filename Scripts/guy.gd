extends Node2D

@export var force_strength: float = 500.0

@onready var torso := $torso
@onready var left_foot := $"left foot"
@onready var right_foot := $"right foot"
@onready var left_hand := $"left hand"
@onready var right_hand := $"right hand"
@onready var head := $head
@onready var left_uarm := $"left Uarm"
@onready var right_uarm := $"right Uarm"
@onready var left_thigh := $"left thigh"
@onready var right_thigh := $"right thigh"

func _ready() -> void:
	right_hand.get_node("Sprite2D").flip_h = true

func _physics_process(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_global_mouse_position()
		if Input.is_action_pressed("a"):
			_apply_paired_force(left_foot, mouse_pos)
		if Input.is_action_pressed("d"):
			_apply_paired_force(right_foot, mouse_pos)
		if Input.is_action_pressed("q"):
			_apply_paired_force(left_hand, mouse_pos)
		if Input.is_action_pressed("e"):
			_apply_paired_force(right_hand, mouse_pos)

	if Input.is_action_pressed("w"):
		_spread_and_ball(true)
	if Input.is_action_pressed("s"):
		_spread_and_ball(false)

	_update_grab_states()

	_apply_joint_angular_damping(torso, left_thigh, 15.0)
	_apply_joint_angular_damping(torso, right_thigh, 15.0)
	_apply_joint_angular_damping(left_thigh, left_foot, 15.0)
	_apply_joint_angular_damping(right_thigh, right_foot, 15.0)

	_enforce_angular_limit(torso, left_thigh, deg_to_rad(-10), deg_to_rad(120), 18000.0)
	_enforce_angular_limit(torso, right_thigh, deg_to_rad(-120), deg_to_rad(10), 18000.0)
	_enforce_angular_limit(left_thigh, left_foot, deg_to_rad(-145), deg_to_rad(0), 18000.0)
	_enforce_angular_limit(right_thigh, right_foot, deg_to_rad(0), deg_to_rad(145), 18000.0)
	_enforce_angular_limit(left_uarm, left_hand, deg_to_rad(-145), deg_to_rad(0), 18000.0)
	_enforce_angular_limit(right_uarm, right_hand, deg_to_rad(0), deg_to_rad(145), 18000.0)


	queue_redraw()

func _update_grab_states() -> void:
	if Input.is_action_just_pressed("space"):
		var grab_all = Input.is_action_pressed("w")
		if grab_all or Input.is_action_pressed("q"):
			left_hand.grabbing = true
		if grab_all or Input.is_action_pressed("e"):
			right_hand.grabbing = true
		if grab_all or Input.is_action_pressed("a"):
			left_foot.grabbing = true
		if grab_all or Input.is_action_pressed("d"):
			right_foot.grabbing = true

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var release_all = Input.is_action_pressed("w")
		if release_all or Input.is_action_pressed("q"):
			left_hand.grabbing = false
		if release_all or Input.is_action_pressed("e"):
			right_hand.grabbing = false
		if release_all or Input.is_action_pressed("a"):
			left_foot.grabbing = false
		if release_all or Input.is_action_pressed("d"):
			right_foot.grabbing = false


func _apply_paired_force(part: RigidBody2D, target_pos: Vector2) -> void:
	var local_offset = Vector2(0, 18)
	var global_offset_pos = part.to_global(local_offset)

	var direction = (target_pos - global_offset_pos).normalized()
	var force = direction * force_strength

	var speed = part.linear_velocity.length()
	var damping_factor = clamp(1.0 - (speed / 200.0), 0.1, 1.0)
	var damped_force = force * damping_factor

	var offset = global_offset_pos - part.global_position

	# Apply force to the limb
	part.apply_force(damped_force, offset)

	# Apply equal and opposite force to the torso at the same relative point
	var torso_offset = global_offset_pos - torso.global_position
	torso.apply_force(-damped_force, torso_offset)

	# Apply torques to account for rotational effect
	var limb_torque = offset.cross(damped_force)
	part.apply_torque(offset.cross(damped_force))  # Optional — if you want the limb to rotate
	torso.apply_torque(torso_offset.cross(-damped_force))




func _spread_and_ball(push_away: bool) -> void:
	var limbs = [left_hand, right_hand, left_foot, right_foot]
	var sign = 1 if push_away else -1

	for part in limbs:
		var local_offset = Vector2(0, 18)
		var global_offset_pos = part.to_global(local_offset)

		var direction = (global_offset_pos - torso.global_position).normalized() * sign
		var force = direction * force_strength

		var speed = part.linear_velocity.length()
		var damping_factor = clamp(1.0 - (speed / 75.0), 0.1, 1.0)
		var damped_force = force * damping_factor

		var limb_offset = global_offset_pos - part.global_position
		var torso_offset = global_offset_pos - torso.global_position

		part.apply_force(damped_force, limb_offset)
		torso.apply_force(-damped_force, torso_offset)

func _get_relative_angle(parent: RigidBody2D, child: RigidBody2D) -> float:
	return wrapf(child.rotation - parent.rotation, -PI, PI)

func _enforce_angular_limit(parent: RigidBody2D, child: RigidBody2D, min_angle: float, max_angle: float, stiffness: float) -> void:
	var rel_angle = wrapf(child.rotation - parent.rotation, -PI, PI)
	if rel_angle < min_angle:
		child.apply_torque(stiffness)
		parent.apply_torque(-stiffness)
	elif rel_angle > max_angle:
		child.apply_torque(-stiffness)
		parent.apply_torque(stiffness)

func _apply_joint_angular_damping(parent: RigidBody2D, child: RigidBody2D, damping_strength: float) -> void:
	var rel_ang_vel = child.angular_velocity - parent.angular_velocity
	var damping_torque = -rel_ang_vel * damping_strength
	child.apply_torque(damping_torque)
	parent.apply_torque(-damping_torque)
