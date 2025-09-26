extends Node2D

@export var force_strength: float = 80.0

# Body Part References
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
@onready var peenie := $Peenie

func _ready() -> void:
	right_hand.get_node("Sprite2D").flip_h = true
	peenie.get_node("Sprite2D").scale = Vector2(0.32,0.32)
	peenie.get_node("Sprite2D").position = Vector2(0,2)
	peenie.get_node("CollisionPolygon2D").scale = Vector2(0.15,0.15)
	peenie.get_node("CollisionPolygon2D").position = Vector2(0,3)

func _physics_process(delta: float) -> void:
	# Input for 'reaching' with the mouse
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

	# Input for 'spreading' or 'balling up'
	if Input.is_action_pressed("w"):
		_spread_and_ball(true)
	if Input.is_action_pressed("s"):
		_spread_and_ball(false)

	_update_grab_states()

	# Joint Damping
	#_apply_joint_angular_damping(torso, left_thigh, 15.0)
	#_apply_joint_angular_damping(torso, right_thigh, 15.0)
	#_apply_joint_angular_damping(left_thigh, left_foot, 15.0)
	#_apply_joint_angular_damping(right_thigh, right_foot, 15.0)

	# Angular Limits Enforcement
	_enforce_angular_limit(torso, left_thigh, deg_to_rad(-10), deg_to_rad(110), 2000.0)
	_enforce_angular_limit(torso, right_thigh, deg_to_rad(-110), deg_to_rad(10), 2000.0)
	_enforce_angular_limit(left_thigh, left_foot, deg_to_rad(-135), deg_to_rad(0), 2000.0)
	_enforce_angular_limit(right_thigh, right_foot, deg_to_rad(0), deg_to_rad(135), 2000.0)
	_enforce_angular_limit(left_uarm, left_hand, deg_to_rad(-145), deg_to_rad(10), 1000.0)
	_enforce_angular_limit(right_uarm, right_hand, deg_to_rad(0), deg_to_rad(145), 1000.0)

	queue_redraw()

func _update_grab_states() -> void:
	if Input.is_action_just_pressed("right click"):
		var release_all = Input.is_action_pressed("w")
		if release_all or Input.is_action_pressed("q"):
			left_hand.grabbing = !left_hand.grabbing
		if release_all or Input.is_action_pressed("e"):
			right_hand.grabbing = !right_hand.grabbing
		if release_all or Input.is_action_pressed("a"):
			left_foot.grabbing = !left_foot.grabbing
		if release_all or Input.is_action_pressed("d"):
			right_foot.grabbing = !right_foot.grabbing

func _apply_paired_force(part: RigidBody2D, target_pos: Vector2) -> void:
	var local_offset = Vector2(0, 18)
	var global_offset_pos = part.to_global(local_offset) # The primary global point of application

	# Calculate the base force and damping
	var direction = (target_pos - global_offset_pos).normalized()
	var base_force = direction * force_strength

	var speed = part.linear_velocity.length()
	var damping_factor = clamp(1.0 - (speed / 200.0), 0.1, 1.0)
	var damped_force = base_force * damping_factor

	# 1. PRIMARY LIMB: Apply 100% force to the selected limb
	var offset_on_part = global_offset_pos - part.global_position
	part.apply_force(damped_force, offset_on_part)
	part.apply_torque(offset_on_part.cross(damped_force))

	# 1B. TORSO REACTION: Apply 100% opposite force to the torso
	var torso_reaction_1_force = -damped_force
	var offset_on_torso_1 = global_offset_pos - torso.global_position
	
	torso.apply_force(torso_reaction_1_force, offset_on_torso_1)
	torso.apply_torque(offset_on_torso_1.cross(torso_reaction_1_force))

	# 2. OTHER LIMBS: Apply 10% opposite force for counter-reach
	var all_limbs = [left_hand, right_hand, left_foot, right_foot]
	var other_limbs = all_limbs.filter(func(limb): return limb != part)
	
	# TORSO REACTION: Apply 10% of primary, in opposite direction
	var other_limb_force = -damped_force * 0.1

	for other in other_limbs:
		var other_limb_offset_pos = other.to_global(local_offset)
		var offset_on_other = other_limb_offset_pos - other.global_position
		
		# Apply force to the other limb
		other.apply_force(other_limb_force, offset_on_other)
		other.apply_torque(offset_on_other.cross(other_limb_force))
		#apply each reactive force
		var torso_reaction_N_force = -other_limb_force 
		var offset_on_torso_N = other_limb_offset_pos - torso.global_position
		
		torso.apply_force(torso_reaction_N_force, offset_on_torso_N)
		torso.apply_torque(offset_on_torso_N.cross(torso_reaction_N_force))

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
	var ramp_range = deg_to_rad(5.0)
	
	# Determine the center of the 'unallowed' range
	var unallowed_midpoint = 0.0
	var unallowed_range_size = 0.0
	
	# Calculate the two unallowed sections
	var range1_min = max_angle
	var range1_max = wrapf(min_angle + 2 * PI, -PI, PI)
	var range2_min = min_angle
	var range2_max = wrapf(max_angle - 2 * PI, -PI, PI)

	var in_unallowed_range = false
	var error_angle = 0.0
	var torque_direction = 0.0

	# Check first unallowed range (clockwise from max_angle)
	if rel_angle > range1_min or rel_angle < range1_max:
		unallowed_range_size = wrapf(range1_max - range1_min, 0, 2 * PI)
		unallowed_midpoint = wrapf(range1_min + unallowed_range_size / 2.0, -PI, PI)
		in_unallowed_range = true
		
	# Check second unallowed range (counter-clockwise from min_angle)
	elif rel_angle < range2_min or rel_angle > range2_max:
		unallowed_range_size = wrapf(range2_min - range2_max, 0, 2 * PI)
		unallowed_midpoint = wrapf(range2_min + unallowed_range_size / 2.0, -PI, PI)
		in_unallowed_range = true
		
	if in_unallowed_range:
		# Determine which way to push for the shortest path
		var dist_to_min = abs(wrapf(rel_angle - min_angle, -PI, PI))
		var dist_to_max = abs(wrapf(rel_angle - max_angle, -PI, PI))
		
		# Set error based on distance to nearest allowed limit
		if dist_to_min < dist_to_max:
			error_angle = dist_to_min
			torque_direction = 1.0 # Push towards max
		else:
			error_angle = dist_to_max
			torque_direction = -1.0 # Push towards min
		
		var ramp_factor = clamp(error_angle / ramp_range, 0.0, 1.0)
		var ramped_stiffness = stiffness * ramp_factor
		
		child.apply_torque(ramped_stiffness * torque_direction)
		parent.apply_torque(-ramped_stiffness * torque_direction)

func _apply_joint_angular_damping(parent: RigidBody2D, child: RigidBody2D, damping_strength: float) -> void:
	return
	# The original damping logic is commented out here by the 'return' for testing
	var rel_ang_vel = child.angular_velocity - parent.angular_velocity
	var damping_torque = -rel_ang_vel * damping_strength
	child.apply_torque(damping_torque)
	parent.apply_torque(-damping_torque)
