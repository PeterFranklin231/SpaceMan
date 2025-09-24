extends Node2D

@export var left_hand: RigidBody2D
@export var right_hand: RigidBody2D
@export var left_foot: RigidBody2D
@export var right_foot: RigidBody2D

var highlight_offset := Vector2(0, 22)
var thickness := 2.0
var active_color := Color.YELLOW
var grabbing_color := Color.SKY_BLUE
var grabbed_object_color := Color.ORANGE_RED

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Highlights if active (keys held) - radius 18
	if Input.is_action_pressed("q"):
		_draw_highlight(left_hand, active_color, 8)
	if Input.is_action_pressed("e"):
		_draw_highlight(right_hand, active_color, 8)
	if Input.is_action_pressed("a"):
		_draw_highlight(left_foot, active_color, 8)
	if Input.is_action_pressed("d"):
		_draw_highlight(right_foot, active_color, 8)

	# Highlights if grabbing (grabbing == true) - radius 20
	if left_hand and left_hand.has_method("get") and left_hand.get("grabbing"):
		_draw_highlight(left_hand, grabbing_color, 10)
	if right_hand and right_hand.has_method("get") and right_hand.get("grabbing"):
		_draw_highlight(right_hand, grabbing_color, 10)
	if left_foot and left_foot.has_method("get") and left_foot.get("grabbing"):
		_draw_highlight(left_foot, grabbing_color, 10)
	if right_foot and right_foot.has_method("get") and right_foot.get("grabbing"):
		_draw_highlight(right_foot, grabbing_color, 10)

	# Highlights if grabbed joint exists and not null (grab_joint != null) - radius 22
	if left_hand and left_hand.has_method("get"):
		var joint = left_hand.get("grab_joint")
		if joint != null:
			_draw_highlight(left_hand, grabbed_object_color, 12)
	if right_hand and right_hand.has_method("get"):
		var joint = right_hand.get("grab_joint")
		if joint != null:
			_draw_highlight(right_hand, grabbed_object_color, 12)
	if left_foot and left_foot.has_method("get"):
		var joint = left_foot.get("grab_joint")
		if joint != null:
			_draw_highlight(left_foot, grabbed_object_color, 12)
	if right_foot and right_foot.has_method("get"):
		var joint = right_foot.get("grab_joint")
		if joint != null:
			_draw_highlight(right_foot, grabbed_object_color, 12)

func _draw_highlight(body: RigidBody2D, color: Color, radius: float) -> void:
	if not body:
		return
	
	var global_pos = body.to_global(highlight_offset)
	var local_pos = to_local(global_pos)
	draw_arc(local_pos, radius, 0, TAU, 32, color, thickness)
