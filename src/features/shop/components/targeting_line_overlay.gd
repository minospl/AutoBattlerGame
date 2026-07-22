class_name TargetingLineOverlay
extends Control

var active_card: Control = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		if DragManager.dragged_card is ShopCardItem:
			active_card = DragManager.dragged_card
			set_process(true)
			queue_redraw()
	elif what == NOTIFICATION_DRAG_END:
		if active_card != null:
			active_card = null
			set_process(false)
			queue_redraw()

func _process(_delta: float) -> void:
	if active_card:
		queue_redraw()

func _draw() -> void:
	if active_card:
		var dragged_card: Control = active_card
		
		# Draw the Hearthstone-style food targeting line
		var start_pos: Vector2 = dragged_card.global_position + dragged_card.size / 2.0
		start_pos = get_global_transform().affine_inverse() * start_pos
		var end_pos: Vector2 = get_local_mouse_position()
		
		var dist: float = start_pos.distance_to(end_pos)
		if dist < 20.0:
			return
			
		# Quadratic bezier points
		var p0: Vector2 = start_pos
		var p2: Vector2 = end_pos
		var mid: Vector2 = (p0 + p2) / 2.0
		var diff: Vector2 = p2 - p0
		var perp: Vector2 = Vector2(-diff.y, diff.x).normalized()
		# Add a subtle organic curve perpendicular to the line, proportional to distance
		var p1: Vector2 = mid + perp * (dist * 0.15)
		
		# 1. Sample the curve to get arc length parameterization
		var num_samples: int = 50
		var sample_points: Array[Vector2] = []
		var sample_distances: Array[float] = []
		
		sample_points.append(p0)
		sample_distances.append(0.0)
		
		var accumulated_dist: float = 0.0
		for k: int in range(1, num_samples + 1):
			var t: float = float(k) / float(num_samples)
			var pt: Vector2 = _get_bezier_point(p0, p1, p2, t)
			accumulated_dist += sample_points[k - 1].distance_to(pt)
			sample_points.append(pt)
			sample_distances.append(accumulated_dist)
			
		var total_length: float = accumulated_dist
		
		# Define dash properties
		var dash_length: float = 28.0
		var gap_length: float = 24.0
		var step: float = dash_length + gap_length
		
		var color: Color = GameColors.GOLDEN_BORDER
		var thickness: float = 16.0
		
		# Draw dashes along the curve from the arrow (end) to the card (start)
		# This anchors the dashes to the arrow, making them slide out of the card
		var arrow_offset: float = 90.0
		var min_d: float = 20.0
		var d: float = total_length - arrow_offset
		
		while d > min_d:
			# Find the sample interval for distance d
			var idx: int = 0
			while idx < num_samples and sample_distances[idx + 1] < d:
				idx += 1
				
			# Interpolate between idx and idx+1
			var dist_a: float = sample_distances[idx]
			var dist_b: float = sample_distances[idx + 1]
			var factor: float = 0.0
			if dist_b - dist_a > 0.0001:
				factor = (d - dist_a) / (dist_b - dist_a)
				
			var pos: Vector2 = sample_points[idx].lerp(sample_points[idx + 1], factor)
			var tangent: Vector2 = (sample_points[idx + 1] - sample_points[idx]).normalized()
			
			var dash_start: Vector2 = pos - tangent * (dash_length / 2.0)
			var dash_end: Vector2 = pos + tangent * (dash_length / 2.0)
			
			# Fade factor: lines im blizej jedzenia tym mniej widoczne (fade).
			# To ensure the first segment closest to the arrow tip is fully solid, we normalize by the max drawn distance.
			var max_d: float = total_length - arrow_offset
			var t_fade: float = d / max_d if max_d > 0.0 else 1.0
			var alpha: float = lerp(0.15, 1.0, t_fade)
			var dash_color: Color = Color(color.r, color.g, color.b, alpha)
			draw_line(dash_start, dash_end, dash_color, thickness)
			
			d -= step
			
		# Draw arrowhead at the end (p2)
		var arrow_len: float = 32.0
		var arrow_width: float = 24.0
		
		# We sample the curve at the base of the arrowhead (d_front) and the back of the tail (d_back)
		# to make both the arrowhead and its connecting tail follow the curve's curvature perfectly.
		var d_front: float = max(0.0, total_length - arrow_len)
		var d_back: float = max(0.0, d_front - 20.0) # tail length is 20px
		
		# Sample d_front (arrowhead base center)
		var idx_f: int = 0
		while idx_f < num_samples - 1 and sample_distances[idx_f + 1] < d_front:
			idx_f += 1
		var dist_fa: float = sample_distances[idx_f]
		var dist_fb: float = sample_distances[idx_f + 1]
		var factor_f: float = 0.0
		if dist_fb - dist_fa > 0.0001:
			factor_f = (d_front - dist_fa) / (dist_fb - dist_fa)
		var pos_f: Vector2 = sample_points[idx_f].lerp(sample_points[idx_f + 1], factor_f)
		var tangent_f: Vector2 = (sample_points[idx_f + 1] - sample_points[idx_f]).normalized()
		var perp_f: Vector2 = Vector2(-tangent_f.y, tangent_f.x).normalized()
		
		# Arrowhead vertices (anchored to pos_f and aligned perpendicular to curve tangent)
		var tip: Vector2 = p2
		var left: Vector2 = pos_f + perp_f * arrow_width
		var right: Vector2 = pos_f - perp_f * arrow_width
		
		# Draw the main triangle arrowhead
		draw_colored_polygon(PackedVector2Array([tip, left, right]), color)
		
		# Draw the curved "cypelek" (connecting tail/neck protrusion)
		# We sample multiple points between d_back and d_front to make it curve organically.
		var tail_width: float = thickness # 16.0
		var num_tail_steps: int = 6
		var tail_left_pts: Array[Vector2] = []
		var tail_right_pts: Array[Vector2] = []
		
		for i: int in range(num_tail_steps):
			var t_ratio: float = float(i) / float(num_tail_steps - 1)
			var d_curr: float = lerp(d_back, d_front, t_ratio)
			
			var idx_curr: int = 0
			while idx_curr < num_samples - 1 and sample_distances[idx_curr + 1] < d_curr:
				idx_curr += 1
			var dist_curr_a: float = sample_distances[idx_curr]
			var dist_curr_b: float = sample_distances[idx_curr + 1]
			var factor_curr: float = 0.0
			if dist_curr_b - dist_curr_a > 0.0001:
				factor_curr = (d_curr - dist_curr_a) / (dist_curr_b - dist_curr_a)
			var pos_curr: Vector2 = sample_points[idx_curr].lerp(sample_points[idx_curr + 1], factor_curr)
			var tangent_curr: Vector2 = (sample_points[idx_curr + 1] - sample_points[idx_curr]).normalized()
			var perp_curr: Vector2 = Vector2(-tangent_curr.y, tangent_curr.x).normalized()
			
			var pt_left: Vector2 = pos_curr + perp_curr * (tail_width / 2.0)
			var pt_right: Vector2 = pos_curr - perp_curr * (tail_width / 2.0)
			
			tail_left_pts.append(pt_left)
			tail_right_pts.append(pt_right)
			
		var tail_polygon_pts: PackedVector2Array = PackedVector2Array()
		# Left edge: back (d_back) to front (d_front)
		for pt: Vector2 in tail_left_pts:
			tail_polygon_pts.append(pt)
		# Right edge: front (d_front) back to base (d_back)
		for j: int in range(tail_right_pts.size() - 1, -1, -1):
			tail_polygon_pts.append(tail_right_pts[j])
			
		draw_colored_polygon(tail_polygon_pts, color)

func _get_bezier_point(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var q0: Vector2 = p0.lerp(p1, t)
	var q1: Vector2 = p1.lerp(p2, t)
	return q0.lerp(q1, t)
