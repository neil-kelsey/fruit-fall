class_name Fx
extends Node2D
## Ink droplets, splats, brush rings and dust puffs, drawn procedurally.

const INK := Color("1b1530")
var parts: Array = []
var rng := RandomNumberGenerator.new()


func burst(pos: Vector2, col: Color, tier: int, radius: float) -> void:
	var n := 12 + tier * 3
	for i in n:
		var dir := Vector2.from_angle(rng.randf() * TAU)
		var spd := rng.randf_range(180.0, 420.0 + tier * 50.0)
		var c := col.lerp(INK, rng.randf_range(0.0, 0.5)) if rng.randf() < 0.7 else Color("f5e8cc")
		parts.append({"k": 0, "p": pos + dir * radius * 0.5, "v": dir * spd, "r": rng.randf_range(2.5, 5.0 + tier * 0.8),
			"c": c, "life": 0.0, "max": rng.randf_range(0.35, 0.7), "drag": 3.5, "g": 900.0})
	for i in 5 + tier / 2:
		var dir := Vector2.from_angle(rng.randf() * TAU)
		parts.append({"k": 2, "p": pos + dir * radius * rng.randf_range(0.7, 1.35), "v": Vector2.ZERO,
			"r": rng.randf_range(3.0, 6.0 + tier), "c": col.lerp(INK, 0.35), "life": 0.0, "max": 0.9, "drag": 0.0, "g": 0.0})
	parts.append({"k": 1, "p": pos, "v": Vector2.ZERO, "r": radius * 0.6, "r1": radius * 1.7 + 20.0, "c": col.lerp(Color.WHITE, 0.25),
		"life": 0.0, "max": 0.45, "drag": 0.0, "g": 0.0, "w": 6.0 + tier, "a0": rng.randf() * TAU})


func puff(pos: Vector2, normal: Vector2, strength: float, radius: float) -> void:
	var tang := normal.orthogonal()
	var n := clampi(int(strength / 250.0), 2, 7)
	for i in n:
		var side := -1.0 if i % 2 == 0 else 1.0
		var v := tang * side * rng.randf_range(40.0, 120.0) * (0.6 + radius / 90.0) - normal * rng.randf_range(10.0, 60.0)
		parts.append({"k": 3, "p": pos + tang * side * rng.randf_range(0.0, radius * 0.3), "v": v,
			"r": rng.randf_range(3.0, 5.0) + radius * 0.06, "c": Color(0.96, 0.92, 0.82, 0.7) if rng.randf() < 0.7 else Color(0.55, 0.6, 0.75, 0.6),
			"life": 0.0, "max": rng.randf_range(0.35, 0.6), "drag": 4.0, "g": -40.0})


func _process(delta: float) -> void:
	var keep: Array = []
	for p in parts:
		p.life += delta
		if p.life >= p.max:
			continue
		p.v *= maxf(0.0, 1.0 - p.drag * delta)
		p.v.y += p.g * delta
		p.p += p.v * delta
		keep.append(p)
	parts = keep
	queue_redraw()


func _draw() -> void:
	for p in parts:
		var t: float = p.life / p.max
		match p.k:
			0:
				var c: Color = p.c
				draw_circle(p.p, p.r * (1.0 - t * 0.7), c, true, -1.0, true)
				draw_line(p.p, p.p - p.v * 0.02, Color(c, 0.6), p.r * 0.8 * (1.0 - t), true)
			1:
				var rr := lerpf(p.r, p.r1, 1.0 - pow(1.0 - t, 3.0))
				var c: Color = p.c
				c.a = 0.85 * (1.0 - t)
				draw_arc(p.p, rr, p.a0, p.a0 + TAU * 0.85, 40, c, p.w * (1.0 - t * 0.6), true)
			2:
				var c: Color = p.c
				c.a = 0.75 * (1.0 - t * t)
				draw_circle(p.p, p.r * minf(1.0, t * 8.0), c, true, -1.0, true)
			3:
				var c: Color = p.c
				c.a *= (1.0 - t)
				draw_circle(p.p, p.r * (1.0 + t * 1.8), c, true, -1.0, true)
