class_name FruitArt
extends RefCounted
## Procedural woodblock-style fruit art. Every fruit has asymmetric details
## (stems, leaves, calyx, highlights, stripes, netting) so rolling reads clearly.

const INK := Color("24170f")
const RADII: Array[float] = [20.0, 27.0, 35.0, 43.0, 53.0, 63.0, 75.0, 88.0, 104.0, 124.0]
const NAMES: Array[String] = ["Cherry", "Strawberry", "Plum", "Persimmon", "Peach", "Yuzu", "Pear", "Apple", "Melon", "Watermelon"]
const COLORS: Array[Color] = [Color("cf1f2e"), Color("e2343b"), Color("8e3270"), Color("ea7420"), Color("f6b0a6"), Color("f3c432"), Color("e3c785"), Color("c92d2b"), Color("b3d06a"), Color("3f8a3a")]
const SHADES: Array[Color] = [Color("8f0f1c"), Color("a81d26"), Color("5a1942"), Color("b34f10"), Color("e07a80"), Color("cf9614"), Color("b8954c"), Color("8c1717"), Color("7a9e3c"), Color("1d5a22")]
const LEAF := Color("4a8a35")
const LEAF_DARK := Color("27521f")
const STEM := Color("5b3a1e")
const STEM_GREEN := Color("51702a")
const HILITE := Color(1, 1, 1, 0.55)

static var _rng := RandomNumberGenerator.new()


static func ellipse_points(c: Vector2, rx: float, ry: float, ang := 0.0, n := 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(ang))
	return pts


## Draws a polygon only if it triangulates (avoids engine errors on degenerate shapes).
static func safe_poly(ci: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	if not Geometry2D.triangulate_polygon(pts).is_empty():
		ci.draw_colored_polygon(pts, col)


static func draw_ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, ang := 0.0) -> void:
	ci.draw_colored_polygon(ellipse_points(c, rx, ry, ang), col)


static func bezier(a: Vector2, ctrl: Vector2, b: Vector2, n := 12) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n + 1):
		var t := float(i) / n
		pts.append(a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))
	return pts


static func leaf_points(base: Vector2, dir: float, length: float, width: float, n := 10) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var d := Vector2.from_angle(dir)
	var nrm := d.orthogonal()
	for i in range(n + 1):
		var t := float(i) / n
		pts.append(base + d * length * t + nrm * sin(t * PI) * width * (1.0 - 0.35 * t))
	for i in range(n - 1, 0, -1):
		var t := float(i) / n
		pts.append(base + d * length * t - nrm * sin(t * PI) * width * (1.0 - 0.35 * t))
	return pts


static func draw_leaf(ci: CanvasItem, base: Vector2, dir: float, length: float, width: float, lw: float, col := LEAF) -> void:
	var pts := leaf_points(base, dir, length, width)
	ci.draw_colored_polygon(pts, col)
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, INK, lw, true)
	ci.draw_line(base, base + Vector2.from_angle(dir) * length * 0.8, LEAF_DARK, maxf(1.0, lw * 0.6), true)


static func stroke(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	ci.draw_polyline(pts, INK, w + 2.0, true)
	ci.draw_polyline(pts, col, w, true)


static func body(ci: CanvasItem, r: float, col: Color, shade: Color, lw: float) -> float:
	ci.draw_circle(Vector2.ZERO, r, INK, true, -1.0, true)
	var ri := r - lw
	ci.draw_circle(Vector2.ZERO, ri, shade, true, -1.0, true)
	ci.draw_circle(Vector2(-0.08, -0.08) * r, ri * 0.87, col, true, -1.0, true)
	return ri


static func hilite(ci: CanvasItem, r: float) -> void:
	draw_ellipse(ci, Vector2(-0.4, -0.36) * r, 0.24 * r, 0.12 * r, HILITE, -0.8)
	draw_ellipse(ci, Vector2(-0.16, -0.62) * r, 0.06 * r, 0.04 * r, HILITE, -0.3)


static func rand_in_circle(rad: float, ymin := -1.0) -> Vector2:
	for _i in 30:
		var p := Vector2(_rng.randf_range(-rad, rad), _rng.randf_range(-rad, rad))
		if p.length() < rad and p.y > ymin * rad:
			return p
	return Vector2.ZERO


## Meridian-style curve that stays inside a circle of radius ri.
static func meridian(ri: float, s: float, wobble: float, zig := 0.0, n := 18) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n + 1):
		var y := lerpf(-0.93, 0.93, float(i) / n)
		var half := sqrt(maxf(0.0, 1.0 - y * y))
		var x := s * half + sin(y * 5.0 + s * 7.0) * wobble * half
		if zig != 0.0:
			x += (zig if i % 2 == 0 else -zig) * half
		pts.append(Vector2(clampf(x, -half * 0.97, half * 0.97), y) * ri)
	return pts


static func draw_fruit(ci: CanvasItem, tier: int, r: float) -> void:
	var lw := clampf(r * 0.075, 2.0, 7.0)
	_rng.seed = 7919 * (tier + 3)
	var col := COLORS[tier]
	var sh := SHADES[tier]
	match tier:
		0: # cherry: long curved stem + leaf
			body(ci, r, col, sh, lw)
			hilite(ci, r)
			ci.draw_arc(Vector2(0.04, -0.72) * r, 0.18 * r, PI * 1.15, PI * 1.85, 8, sh, lw * 0.7, true)
			var st := bezier(Vector2(0.04, -0.82) * r, Vector2(0.12, -1.3) * r, Vector2(0.62, -1.45) * r)
			stroke(ci, st, STEM_GREEN, lw * 0.9)
			draw_leaf(ci, Vector2(0.58, -1.43) * r, -0.15, 0.85 * r, 0.26 * r, lw * 0.6)
		1: # strawberry: seeds + star calyx
			var ri := body(ci, r, col, sh, lw)
			for i in 15:
				var p := rand_in_circle(ri * 0.8, -0.45)
				var ang := p.angle() + PI * 0.5
				draw_ellipse(ci, p, 0.045 * r, 0.075 * r, Color("f7e27a"), ang)
				ci.draw_line(p - Vector2(0, 0.05 * r).rotated(ang), p + Vector2(0, 0.05 * r).rotated(ang), Color(0.45, 0.05, 0.05, 0.6), 1.0, true)
			hilite(ci, r)
			for a in [-2.85, -2.2, -1.57, -0.94, -0.29]:
				draw_leaf(ci, Vector2(0, -0.78) * r, a, 0.5 * r, 0.14 * r, lw * 0.6)
			stroke(ci, bezier(Vector2(0, -0.8) * r, Vector2(0.05, -1.05) * r, Vector2(0.18, -1.15) * r), STEM_GREEN, lw * 0.8)
		2: # plum: side cleft + small stem/leaf + bloom
			body(ci, r, col, sh, lw)
			ci.draw_polyline(bezier(Vector2(0.12, -0.9) * r, Vector2(0.55, 0.0) * r, Vector2(0.08, 0.9) * r), sh, lw * 0.9, true)
			for i in 6:
				ci.draw_circle(rand_in_circle(r * 0.7), r * 0.03, Color(1, 1, 1, 0.25), true, -1.0, true)
			hilite(ci, r)
			stroke(ci, bezier(Vector2(0.1, -0.86) * r, Vector2(0.12, -1.0) * r, Vector2(0.02, -1.14) * r), STEM, lw * 0.8)
			draw_leaf(ci, Vector2(0.06, -1.05) * r, -0.45, 0.62 * r, 0.2 * r, lw * 0.6)
		3: # persimmon: four broad sepals + square stem
			var ri := body(ci, r, col, sh, lw)
			for s in [-0.45, 0.45]:
				ci.draw_polyline(meridian(ri, s, 0.02), Color(sh, 0.35), lw * 0.6, true)
			hilite(ci, r)
			for a in [-2.75, -2.0, -1.15, -0.4]:
				draw_leaf(ci, Vector2(0, -0.74) * r, a, 0.45 * r, 0.2 * r, lw * 0.6, Color("5b8a2e"))
			ci.draw_rect(Rect2(Vector2(-0.08, -0.92) * r, Vector2(0.16, 0.16) * r), STEM)
			ci.draw_rect(Rect2(Vector2(-0.08, -0.92) * r, Vector2(0.16, 0.16) * r), INK, false, maxf(1.0, lw * 0.5))
		4: # peach: blush, cleft, stem with two leaves
			body(ci, r, col, sh, lw)
			ci.draw_circle(Vector2(0.24, 0.16) * r, 0.52 * r, Color("ee7d86", 0.55), true, -1.0, true)
			ci.draw_circle(Vector2(0.3, 0.2) * r, 0.3 * r, Color("e0566a", 0.35), true, -1.0, true)
			ci.draw_polyline(bezier(Vector2(0.0, -0.92) * r, Vector2(-0.38, -0.1) * r, Vector2(0.06, 0.55) * r), sh, lw * 1.0, true)
			hilite(ci, r)
			stroke(ci, bezier(Vector2(0.04, -0.88) * r, Vector2(0.06, -1.0) * r, Vector2(0.12, -1.1) * r), STEM, lw * 0.9)
			draw_leaf(ci, Vector2(0.1, -1.04) * r, -0.35, 0.62 * r, 0.2 * r, lw * 0.6)
			draw_leaf(ci, Vector2(0.06, -1.0) * r, -2.6, 0.45 * r, 0.16 * r, lw * 0.6, Color("5f9a40"))
		5: # yuzu: dimpled rind, navel, leaf
			body(ci, r, col, sh, lw)
			for i in 36:
				ci.draw_circle(rand_in_circle(r * 0.85), r * 0.022, Color(sh, 0.55), true, -1.0, true)
			var nv := Vector2(0.06, 0.8) * r
			for k in 5:
				ci.draw_line(nv, nv + Vector2.from_angle(TAU * k / 5.0) * r * 0.07, sh, maxf(1.0, lw * 0.4), true)
			hilite(ci, r)
			ci.draw_circle(Vector2(0, -0.86) * r, r * 0.07, STEM_GREEN, true, -1.0, true)
			draw_leaf(ci, Vector2(0.02, -0.88) * r, -0.3, 0.6 * r, 0.22 * r, lw * 0.6, Color("3f7a2a"))
		6: # nashi pear: russet crown, lenticels, crooked stem
			body(ci, r, col, sh, lw)
			ci.draw_circle(Vector2(0.02, -0.58) * r, 0.3 * r, Color("a8793e", 0.45), true, -1.0, true)
			for i in 46:
				ci.draw_circle(rand_in_circle(r * 0.85), r * 0.018, Color("fbf0c4", 0.85), true, -1.0, true)
			hilite(ci, r)
			stroke(ci, bezier(Vector2(0, -0.84) * r, Vector2(0.06, -1.08) * r, Vector2(-0.14, -1.28) * r), STEM, lw * 1.0)
		7: # apple: two-tone streaks, dimple, stem and leaf
			var ri := body(ci, r, col, sh, lw)
			ci.draw_circle(Vector2(-0.32, 0.26) * r, 0.4 * r, Color("e8b53e", 0.45), true, -1.0, true)
			for s in [-0.7, -0.45, -0.2, 0.15, 0.4, 0.65]:
				ci.draw_polyline(meridian(ri, s, 0.05), Color(sh, 0.35), maxf(1.0, lw * 0.45), true)
			hilite(ci, r)
			ci.draw_arc(Vector2(0, -0.66) * r, 0.2 * r, PI * 1.15, PI * 1.85, 10, sh, lw * 0.8, true)
			stroke(ci, bezier(Vector2(0, -0.74) * r, Vector2(-0.02, -0.95) * r, Vector2(-0.1, -1.1) * r), STEM, lw * 0.9)
			draw_leaf(ci, Vector2(-0.04, -0.98) * r, -0.55, 0.55 * r, 0.2 * r, lw * 0.6)
		8: # melon: cream netting + T stem
			var ri := body(ci, r, col, sh, lw)
			var net := Color("f1f4d6", 0.85)
			for s in [-0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75]:
				ci.draw_polyline(meridian(ri, s, 0.06), net, maxf(1.0, lw * 0.4), true)
			for y in [-0.6, -0.3, 0.0, 0.3, 0.6]:
				var half := sqrt(1.0 - y * y) * 0.95
				var pts := PackedVector2Array()
				for i in 13:
					var x := lerpf(-half, half, i / 12.0)
					pts.append(Vector2(x, y + sin(x * 9.0 + y * 4.0) * 0.035) * ri)
				ci.draw_polyline(pts, net, maxf(1.0, lw * 0.35), true)
			hilite(ci, r)
			stroke(ci, PackedVector2Array([Vector2(0, -0.86) * r, Vector2(0.02, -1.1) * r]), STEM_GREEN, lw * 1.1)
			stroke(ci, PackedVector2Array([Vector2(-0.16, -1.1) * r, Vector2(0.2, -1.1) * r]), STEM_GREEN, lw * 0.9)
		9: # watermelon: jagged dark stripes + curly stem
			var ri := body(ci, r, col, sh, lw)
			for s in [-0.82, -0.52, -0.2, 0.12, 0.45, 0.78]:
				ci.draw_polyline(meridian(ri, s, 0.04, 0.035, 22), Color("163f19"), lw * 1.5, true)
			hilite(ci, r)
			var spiral := PackedVector2Array()
			for i in 22:
				var t := i / 21.0
				var a := -PI * 0.5 + t * TAU * 1.3
				spiral.append(Vector2(0.08, -1.0) * r + Vector2(0, -0.12 * r * t) + Vector2.from_angle(a) * r * 0.08 * t)
			stroke(ci, PackedVector2Array([Vector2(0, -0.86) * r, Vector2(0.06, -1.0) * r]), STEM_GREEN, lw * 0.9)
			stroke(ci, spiral, STEM_GREEN, lw * 0.6)
