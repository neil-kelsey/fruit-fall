extends Control
## Score (brush numerals + vermilion stroke), best, and the NEXT hanko seal.
const VERMILION := Color("c8282d")
var main: Node
var shown := 0.0
var bump := 0.0
var next_pop := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(720, 1280)


func on_score() -> void:
	bump = 1.0


func on_next() -> void:
	next_pop = 1.0


func _process(delta: float) -> void:
	shown = move_toward(shown, main.score, maxf(1.0, absf(main.score - shown)) * delta * 8.0 + delta * 20.0)
	bump = maxf(0.0, bump - delta * 4.0)
	next_pop = maxf(0.0, next_pop - delta * 4.0)
	queue_redraw()


func _draw() -> void:
	var font: Font = main.font
	var txt := str(int(round(shown)))
	var fs := 88
	var sc := 1.0 + 0.22 * sin(bump * PI) * bump
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * sc
	# brush underline (tapered stroke)
	var pts := PackedVector2Array()
	var x0 := 30.0
	var x1 := 40.0 + w + 40.0
	for i in 17:
		var t := i / 16.0
		pts.append(Vector2(lerpf(x0, x1, t), 120.0 - 4.0 * t - sin(t * PI) * 2.0 - (1.0 - t) * 5.0 * sin(t * PI * 2.0)))
	for i in range(16, -1, -1):
		var t := i / 16.0
		pts.append(Vector2(lerpf(x0, x1, t), 120.0 - 4.0 * t + 4.0 + 5.0 * sin(t * PI) * (1.0 - t * 0.8)))
	draw_colored_polygon(pts, Color(VERMILION, 0.9))
	draw_set_transform(Vector2(40, 104), -0.02, Vector2(sc, sc))
	draw_string(font, Vector2(3, 3), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(VERMILION, 0.35))
	draw_string(font, Vector2.ZERO, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, FruitArt.INK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_string(font, Vector2(42, 160), "BEST  %d" % main.best, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, VERMILION)
	# NEXT hanko
	var ps := 1.0 + 0.15 * sin(next_pop * PI)
	draw_set_transform(Vector2(626, 80), -0.06, Vector2(ps, ps))
	var sb := StyleBoxFlat.new()
	sb.bg_color = VERMILION
	sb.set_corner_radius_all(10)
	sb.border_color = Color("8e1419")
	sb.set_border_width_all(3)
	draw_style_box(sb, Rect2(-62, -60, 124, 120))
	var inner := StyleBoxFlat.new()
	inner.draw_center = false
	inner.border_color = Color("f5e8cc", 0.85)
	inner.set_border_width_all(2)
	inner.set_corner_radius_all(6)
	draw_style_box(inner, Rect2(-54, -52, 108, 104))
	draw_string(font, Vector2(-54, -26), "NEXT", HORIZONTAL_ALIGNMENT_CENTER, 108, 24, Color("f5e8cc"))
	if main.next_tier >= 0:
		var r := FruitArt.RADII[main.next_tier]
		var s := minf(1.0, 30.0 / r)
		draw_set_transform(Vector2(626, 80) + Vector2(0, 16).rotated(-0.06) * ps, -0.06 + sin(main.dropper.time * 1.5) * 0.15, Vector2(s, s) * ps)
		draw_circle(Vector2.ZERO, r + 4.0 / s, Color("f5e8cc", 0.9), true, -1.0, true)
		FruitArt.draw_fruit(self, main.next_tier, r)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# hint
	if main.state == 1 and main.stats.drops < 3:
		draw_string(font, Vector2(0, 1240), "move · tap / click / space to drop", HORIZONTAL_ALIGNMENT_CENTER, 720, 26, Color(FruitArt.INK, 0.55))
