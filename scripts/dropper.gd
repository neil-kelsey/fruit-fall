class_name Dropper
extends Node2D
## Crane that carries the next fruit. The dangling fruit is a cosmetic pendulum
## until release; then it becomes a real RigidBody2D.

var main: Node
var crane_x := 360.0
var target_x := 360.0
var crane_vx := 0.0
var face := 1.0
var _face_target := 1.0
var theta := 0.0
var theta_v := 0.0
var held_tier := -1
var appear := 1.0
var guide_y := -1.0
var time := 0.0
var danger := 0.0
var show_line := false


func set_held(t: int) -> void:
	held_tier = t
	appear = 0.0
	theta_v += randf_range(-1.0, 1.0)


func release() -> void:
	held_tier = -1


func beak_pos() -> Vector2:
	return Vector2(crane_x, Layout.CRANE_Y + 6.0 + sin(time * 2.2) * 4.0)


func string_len() -> float:
	return (Layout.HOLD_Y - Layout.CRANE_Y) * lerpf(0.55, 1.0, ease_out(appear))


func held_pos() -> Vector2:
	return beak_pos() + Vector2(sin(theta), cos(theta)) * string_len()


func held_rot() -> float:
	return theta * 0.9


func held_vx() -> float:
	return crane_vx + theta_v * cos(theta) * string_len()


static func ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)


func _process(delta: float) -> void:
	time += delta
	appear = minf(1.0, appear + delta * 4.0)
	var r := FruitArt.RADII[held_tier] if held_tier >= 0 else 20.0
	target_x = clampf(target_x, Layout.INNER_L + r + 2.0, Layout.INNER_R - r - 2.0)
	var last_vx := crane_vx
	var k := 220.0
	crane_vx += ((target_x - crane_x) * k - crane_vx * 2.0 * sqrt(k)) * delta
	crane_x += crane_vx * delta
	var ax := clampf((crane_vx - last_vx) / maxf(delta, 0.001), -5000.0, 5000.0)
	var L := maxf(string_len(), 20.0)
	theta_v += (-(1400.0 / L) * sin(theta) - (ax / L) * cos(theta) * 0.35 - theta_v * 3.0) * delta
	theta_v += sin(time * 1.3) * 0.15 * delta  # gentle idle sway
	theta = clampf(theta + theta_v * delta, -0.5, 0.5)
	if absf(crane_vx) > 80.0:
		_face_target = signf(crane_vx)
	face = move_toward(face, _face_target, delta * 7.0)
	queue_redraw()


func _draw() -> void:
	# danger line
	var flash := 0.5 + 0.5 * sin(time * 14.0)
	var a := 0.28 + clampf(danger, 0.0, 1.0) * 0.7 * flash
	var w := 2.0 + clampf(danger, 0.0, 1.0) * 2.0
	var x: float = Layout.INNER_L + 6.0
	while x < Layout.INNER_R - 6.0:
		draw_line(Vector2(x, Layout.DANGER_Y), Vector2(minf(x + 12.0, Layout.INNER_R - 6.0), Layout.DANGER_Y), Color(0.85, 0.2, 0.2, a), w, true)
		x += 22.0
	if held_tier >= 0:
		var r := FruitArt.RADII[held_tier]
		var hp := held_pos()
		var sc := lerpf(0.6, 1.0, ease_out(appear))
		# drop guide: dotted line to predicted landing + ghost outline
		if guide_y > hp.y:
			var y := hp.y + r + 10.0
			while y < guide_y - r - 4.0:
				draw_circle(Vector2(hp.x, y), 2.2, Color(0.98, 0.93, 0.82, 0.55), true, -1.0, true)
				y += 16.0
			var segs := 18
			for i in segs:
				if i % 2 == 0:
					var a0 := TAU * i / segs
					draw_arc(Vector2(hp.x, guide_y), r, a0, a0 + TAU / segs, 4, Color(0.98, 0.93, 0.82, 0.45), 2.0, true)
		var bp := beak_pos()
		var top := hp - Vector2(sin(theta), cos(theta)) * r * sc
		draw_line(bp, top, Color("c8282d"), 2.0, true)
		draw_set_transform(hp, held_rot(), Vector2(sc, sc))
		FruitArt.draw_fruit(self, held_tier, r)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var bp2 := beak_pos()
	draw_crane(self, bp2 - Vector2(84.0 * face, 4.0), face, sin(time * 7.0))


static func _wing(ci: CanvasItem, f: float, col: Color, tip_col: Color) -> void:
	var tip := Vector2(-36.0, -80.0 * f)
	var tipb := tip + Vector2(-16.0, 6.0)
	var mf := Vector2(4.0, -42.0 * f - 6.0)
	var mb := Vector2(-42.0, -38.0 * f + 6.0)
	var pts := PackedVector2Array([Vector2(16, -6), mf, tip, tipb, mb, Vector2(-22, -2)])
	FruitArt.safe_poly(ci, pts, col)
	var tp := PackedVector2Array([mf.lerp(tip, 0.55), tip, tipb, mb.lerp(tipb, 0.5)])
	FruitArt.safe_poly(ci, tp, tip_col)
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, FruitArt.INK, 2.0, true)


## Red-crowned crane in flight, beak tip at local (84, 4).
static func draw_crane(ci: CanvasItem, pos: Vector2, face: float, flap: float) -> void:
	var f := 0.25 + 0.75 * flap
	ci.draw_set_transform(pos, 0.0, Vector2(face if absf(face) > 0.05 else 0.05, 1.0))
	var ink := FruitArt.INK
	_wing(ci, f * 0.8 + 0.15, Color("d9d2c3"), Color("2a2522"))
	ci.draw_line(Vector2(-28, 6), Vector2(-86, 14), ink, 2.5, true)
	ci.draw_line(Vector2(-26, 8), Vector2(-84, 18), ink, 2.5, true)
	var tail := PackedVector2Array([Vector2(-30, -8), Vector2(-60, -4), Vector2(-52, 4), Vector2(-62, 10), Vector2(-30, 8)])
	ci.draw_colored_polygon(tail, Color("1e1a19"))
	var bod := FruitArt.ellipse_points(Vector2.ZERO, 38, 15, -0.05, 24)
	ci.draw_colored_polygon(bod, Color("fbf7ee"))
	var bc := bod.duplicate()
	bc.append(bod[0])
	ci.draw_polyline(bc, ink, 2.5, true)
	var neck := FruitArt.bezier(Vector2(30, -4), Vector2(50, -10), Vector2(70, -2))
	ci.draw_polyline(neck, ink, 8.0, true)
	ci.draw_circle(Vector2(72, -1), 7.0, Color("fbf7ee"), true, -1.0, true)
	ci.draw_circle(Vector2(72, -1), 7.0, ink, false, 2.0, true)
	ci.draw_circle(Vector2(71, -6), 3.6, Color("d22c2c"), true, -1.0, true)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(77, -3), Vector2(88, 4), Vector2(76, 3)]), Color("b9a35a"))
	ci.draw_circle(Vector2(74, -2), 1.3, ink, true)
	_wing(ci, f, Color("fbf7ee"), Color("1e1a19"))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
