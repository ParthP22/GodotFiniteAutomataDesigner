extends Node2D

var node_rad = 26.1725006103516
var _start_state: RigidBody2D = null
var _end_state: RigidBody2D = null
var transition: Array = []

var arrow_head = Polygon2D.new()
var arrow_shaft = Line2D.new()

var offset: float = 1
var special_name: String = "state"
var semi_circle_points = Curve2D.new()
var line_curve = Line2D.new()
var label = Label.new()
var label_bg = Sprite2D.new()
var arrow_hitbox: CollisionPolygon2D = CollisionPolygon2D.new()
@onready var light: Light2D = $PointLight2D


func _ready():
	# Arrow to another node
	add_child(arrow_shaft)
	arrow_shaft.default_color = Color(1, 1, 1) # white
	arrow_shaft.width = 3
	add_child(arrow_head)
	arrow_head.color = Color(1, 0, 0) # red
	
	# Arrow to self
	add_child(line_curve)
	line_curve.default_color = Color(1, 1, 1, 1) # white
	line_curve.width = 3
	
	# Label modifications
	line_curve.add_child(label)
	label.text = ""
	label.add_theme_color_override("font_color", Color("blue"))
	label.add_theme_font_size_override("font_size", 20)
	# Add arrow hitbox child
	add_child(arrow_hitbox)

func _process(_delta):
	pass

func _physics_process(_delta):
	if _start_state and _end_state and _start_state == _end_state:
		update_arrow_to_self()
	elif _start_state and _end_state and _start_state != _end_state:
		update_arrow_to_another()

func set_start_state(node: Object):
	if !_start_state:
		_start_state = node
	
func set_end_state(node: Object):
	if !_end_state:
		_end_state = node

func update_arrow_to_another():
# Calculate midpoint and set it as the arrow's position
	var start_pos = _start_state.global_position
	var end_pos = _end_state.global_position
	var midpoint = (start_pos + end_pos) / 2
	self.position = midpoint  # Move arrow to midpoint

	# Compute local positions relative to `self.position`
	var local_start = start_pos - self.position
	var local_end = end_pos - self.position
	var distance = local_start.distance_to(local_end)

	# Offset start and end positions to prevent overlap with circles
	var t1 = node_rad / distance
	var t2 = node_rad / distance
	var adjusted_start = (1 - t1) * local_start + t1 * local_end
	var adjusted_end = (1 - t2) * local_end + t2 * local_start

	# Compute direction and perpendicular direction
	var direction = (adjusted_end - adjusted_start).normalized()
	var perp_direction = Vector2(-direction.y, direction.x) * offset

	# Apply perpendicular offset to shift the entire arrow
	adjusted_start += perp_direction
	adjusted_end += perp_direction

	# Find a point slightly before the end for the arrowhead
	var t3 = 10 / adjusted_start.distance_to(adjusted_end)
	var arrow_tip = (1 - t3) * adjusted_end + t3 * adjusted_start

	# Find perpendicular points for arrowhead
	var perp_start = arrow_tip - perp_direction.normalized() * 7
	var perp_end = arrow_tip + perp_direction.normalized() * 7

	# Update shaft (main line) - Now relative to `self.position`
	arrow_shaft.points = [adjusted_start, arrow_tip]

	# Update arrowhead - Now relative to `self.position`
	arrow_head.polygon = PackedVector2Array([perp_start, adjusted_end, perp_end])

	# Position label at the midpoint of the arrow, slightly above
	label.position = perp_direction.normalized() * offset  # Offset slightly above

	# Reshape arrow shaft collision box
	var hitbox_width = 5
	var p1 = adjusted_start + perp_direction.normalized() * hitbox_width
	var p2 = adjusted_start - perp_direction.normalized() * hitbox_width
	var p3 = adjusted_end - perp_direction.normalized() * hitbox_width
	var p4 = adjusted_end + perp_direction.normalized() * hitbox_width
	arrow_hitbox.polygon = PackedVector2Array([p1, p2, p3, p4])
	
	
func update_arrow_to_self():
	var node_center = _start_state.global_position
	self.position = node_center
	light.position = Vector2(0, -node_rad*2)
	# Clear the previous points
	semi_circle_points.clear_points()
	
	semi_circle_points.add_point(Vector2(-node_rad+10,-node_rad+10))
	semi_circle_points.add_point(Vector2(0,  -node_rad * 2), 
				Vector2(-node_rad,0),
				Vector2(node_rad,0))
	semi_circle_points.add_point(Vector2(node_rad/2 + 5, -node_rad))
	line_curve.points = semi_circle_points.get_baked_points()
	
	arrow_head.polygon = PackedVector2Array([
		Vector2(node_rad/2 - 10 + 5, -node_rad),
		Vector2(node_rad/2 + 5, -node_rad + 10),
		Vector2(node_rad/2 + 10 + 5, -node_rad)
	])
	
	# Adjust label position
	label.position = Vector2(0, -node_rad * 2.2)

	# Hitbox for self-loop
	var hitbox_offset = 5
	var p1 = Vector2(-node_rad - hitbox_offset + 12, -node_rad*1.9)  # Left
	var p2 = Vector2(0, -node_rad * 2 - hitbox_offset)  # Top
	var p3 = Vector2(node_rad + hitbox_offset - 12, -node_rad*1.9)  # Right
	var p4 = Vector2(node_rad, -node_rad)  # Bottom right
	var p5 = Vector2(-node_rad/2, -node_rad-1) # Bottom middle
	var p6 = Vector2(-node_rad - hitbox_offset+8,-node_rad+12)  # Bottom left

	arrow_hitbox.polygon = PackedVector2Array([p1, p2, p3, p4, p5, p6])  # Ensure all points are included
	
func get_start_state():
	return _start_state

func get_end_state():
	return _end_state

func get_text() -> String:
	return label.text

func set_text(text: String):
	label.text = ""
	label.text = text

func get_transition() -> Array:
	return transition
	
func set_transition(new_transition: Array):
	transition = new_transition

func toggle_light():
	if light.energy <= 0:
		light.energy = 1
	else:
		light.energy = 0
