class_name Petals
extends Control
## Falling sakura petals.

var petals: Array = []
var rate := 0.0
var _acc := 0.0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(720, 1280)


func start(r: float) -> void:
	rate = r


func stop() -> void:
	rate = 0.0
	petals.clear()


func _process(delta: float) -> void:
	_acc += rate * delta
	while _acc >= 1.0:
		_acc -= 1.0
		petals.append({"p": Vector2(rng.randf_range(-40, 760), -20), "vy": rng.randf_range(70, 150), "ph": rng.randf() * TAU,
			"rot": rng.randf() * TAU, "rs": rng.randf_range(-3, 3), "s": rng.randf_range(10, 18), "flip": rng.randf() * TAU})
	var keep: Array = []
	for p in petals:
		p.ph += delta * 1.6
		p.p += Vector2(sin(p.ph) * 60.0 + 25.0, p.vy) * delta
		p.rot += p.rs * delta
		p.flip += delta * 3.0
		if p.p.y < 1320:
			keep.append(p)
	petals = keep
	queue_redraw()


func _draw() -> void:
	for p in petals:
		var s: float = p.s
		var sx := absf(cos(p.flip)) * 0.5 + 0.5
		draw_set_transform(p.p, p.rot, Vector2(sx, 1.0))
		var pts := PackedVector2Array()
		pts.append_array(FruitArt.bezier(Vector2(0, s * 0.7), Vector2(s * 0.75, s * 0.1), Vector2(s * 0.2, -s * 0.7), 8))
		pts.append(Vector2(0, -s * 0.45))
		pts.append_array(FruitArt.bezier(Vector2(-s * 0.2, -s * 0.7), Vector2(-s * 0.75, s * 0.1), Vector2(0, s * 0.7), 8).slice(0, 8))
		draw_colored_polygon(pts, Color("f6b7c6"))
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, Color("c75a7a"), 1.2, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
