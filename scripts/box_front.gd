extends Node2D
## Lacquered wooden box frame drawn in front of the fruit (static, drawn once).
const LACQUER := Color("3b2014")
const LACQUER_HI := Color("5a3420")
const GOLD := Color("c9a24a")
const RED := Color("c8282d")


func _draw() -> void:
	var ink := FruitArt.INK
	var top := Layout.BOX_TOP - 10.0
	var posts := [Rect2(Layout.BOX_OUT_L, top, Layout.INNER_L - Layout.BOX_OUT_L, Layout.BOX_BOTTOM - top),
		Rect2(Layout.INNER_R, top, Layout.BOX_OUT_R - Layout.INNER_R, Layout.BOX_BOTTOM - top)]
	var floor_r := Rect2(Layout.BOX_OUT_L, Layout.FLOOR_Y, Layout.BOX_OUT_R - Layout.BOX_OUT_L, Layout.BOX_BOTTOM - Layout.FLOOR_Y)
	# soft shadow under box
	draw_rect(Rect2(Layout.BOX_OUT_L + 8, Layout.BOX_BOTTOM - 4, Layout.BOX_OUT_R - Layout.BOX_OUT_L - 4, 14), Color(0.2, 0.12, 0.06, 0.18))
	for r in posts + [floor_r]:
		draw_rect(r, LACQUER)
	# wood grain
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for r in posts:
		for i in 4:
			var x: float = r.position.x + 4.0 + i * (r.size.x - 8.0) / 3.0
			var pts := PackedVector2Array()
			var y: float = r.position.y + 6.0
			while y < r.end.y - 6.0:
				pts.append(Vector2(x + sin(y * 0.02 + i * 2.0) * 1.6, y))
				y += 24.0
			draw_polyline(pts, LACQUER_HI, 1.0, true)
	# gold seigaiha band on the floor
	var bx := Layout.BOX_OUT_L + 10.0
	var by := Layout.FLOOR_Y + (Layout.BOX_BOTTOM - Layout.FLOOR_Y) * 0.75
	while bx < Layout.BOX_OUT_R - 10.0:
		draw_arc(Vector2(bx, by), 9.0, PI, TAU, 10, GOLD, 1.4, true)
		draw_arc(Vector2(bx, by), 5.0, PI, TAU, 8, GOLD, 1.2, true)
		bx += 18.0
	# chamfered inner corners (match physics)
	draw_colored_polygon(PackedVector2Array([Vector2(Layout.INNER_L, Layout.FLOOR_Y - 14), Vector2(Layout.INNER_L, Layout.FLOOR_Y), Vector2(Layout.INNER_L + 14, Layout.FLOOR_Y)]), LACQUER)
	draw_colored_polygon(PackedVector2Array([Vector2(Layout.INNER_R, Layout.FLOOR_Y - 14), Vector2(Layout.INNER_R, Layout.FLOOR_Y), Vector2(Layout.INNER_R - 14, Layout.FLOOR_Y)]), LACQUER)
	# gold inner trim
	var trim := PackedVector2Array([Vector2(Layout.INNER_L - 3, top + 4), Vector2(Layout.INNER_L - 3, Layout.FLOOR_Y - 14), Vector2(Layout.INNER_L + 11, Layout.FLOOR_Y + 3),
		Vector2(Layout.INNER_R - 11, Layout.FLOOR_Y + 3), Vector2(Layout.INNER_R + 3, Layout.FLOOR_Y - 14), Vector2(Layout.INNER_R + 3, top + 4)])
	draw_polyline(trim, GOLD, 3.0, true)
	# ink outlines
	var outline := PackedVector2Array([Vector2(Layout.BOX_OUT_L, top), Vector2(Layout.BOX_OUT_L, Layout.BOX_BOTTOM), Vector2(Layout.BOX_OUT_R, Layout.BOX_BOTTOM), Vector2(Layout.BOX_OUT_R, top)])
	draw_polyline(outline, ink, 3.0, true)
	for r in posts:
		draw_rect(Rect2(r.position.x - 4, top - 8, r.size.x + 8, 12), GOLD)
		draw_rect(Rect2(r.position.x - 4, top - 8, r.size.x + 8, 12), ink, false, 2.0)
	# red cord ties at the corners
	for c in [Vector2(Layout.BOX_OUT_L + 12, top + 18), Vector2(Layout.BOX_OUT_R - 12, top + 18), Vector2(Layout.BOX_OUT_L + 12, Layout.BOX_BOTTOM - 13), Vector2(Layout.BOX_OUT_R - 12, Layout.BOX_BOTTOM - 13)]:
		draw_line(c + Vector2(-9, -9), c + Vector2(9, 9), RED, 4.0, true)
		draw_line(c + Vector2(-9, 9), c + Vector2(9, -9), RED, 4.0, true)
		draw_circle(c, 3.0, Color("e9c46a"), true, -1.0, true)
