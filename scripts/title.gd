extends Control
## Title screen: ukiyo-e wave banner, Fuji, flying crane, rolling fruit parade.
signal play_pressed

var main: Node
var best_label: Label


class Art extends Control:
	var main: Node
	var t := 0.0

	func _process(d: float) -> void:
		t += d
		queue_redraw()

	func _draw() -> void:
		var font: Font = main.font
		# sky + sun
		draw_rect(Rect2(-600, -900, 1920, 1200), Color("f0dcb4"))
		draw_circle(Vector2(140, 96), 50, Color("d6453d"), true, -1.0, true)
		# kasumi mist bands
		for b in [[Vector2(-20, 60), 300.0], [Vector2(380, 120), 360.0], [Vector2(60, 170), 260.0]]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color("f8ecd2")
			sb.set_corner_radius_all(14)
			draw_style_box(sb, Rect2(b[0], Vector2(b[1], 28)))
		# Fuji
		var fuji := PackedVector2Array([Vector2(380, 300), Vector2(530, 150), Vector2(590, 150), Vector2(740, 300)])
		draw_colored_polygon(fuji, Color("a83a3f"))
		var snow := PackedVector2Array([Vector2(530, 150), Vector2(590, 150), Vector2(617, 177), Vector2(600, 172), Vector2(588, 186), Vector2(572, 172), Vector2(556, 186), Vector2(542, 170), Vector2(503, 177)])
		draw_colored_polygon(snow, Color("fbf7ee"))
		draw_polyline(PackedVector2Array([Vector2(380, 300), Vector2(530, 150), Vector2(590, 150), Vector2(740, 300)]), FruitArt.INK, 3.0, true)
		# great wave layers
		for layer in 3:
			var pts := PackedVector2Array()
			var base := 222.0 + layer * 24.0
			pts.append(Vector2(0, 302))
			for i in 49:
				var x := i * 15.0
				pts.append(Vector2(x, base + sin(x * 0.018 + t * (0.8 + layer * 0.3) + layer * 1.7) * 18.0 + sin(x * 0.05 + t) * 4.0))
			pts.append(Vector2(720, 302))
			var col: Color = [Color("2e5d94"), Color("23477a"), Color("1a2f57")][layer]
			FruitArt.safe_poly(self, pts, col)
			var crest := pts.slice(1, pts.size() - 1)
			draw_polyline(crest, Color("f8ecd2"), 3.0, true)
			for i in range(2, crest.size(), 6):
				draw_circle(crest[i] + Vector2(0, -3), 5.0, Color("fbf7ee"), true, -1.0, true)
		draw_line(Vector2(0, 300), Vector2(720, 300), FruitArt.INK, 3.0, true)
		var cx := fmod(t * 70.0, 980.0) - 130.0
		Dropper.draw_crane(self, Vector2(cx, 110 + sin(t * 2.0) * 8.0), 1.0, sin(t * 6.0))
		# title text
		draw_string(font, Vector2(6, 446), "FRUIT FALL", HORIZONTAL_ALIGNMENT_CENTER, 720, 100, Color("c8282d", 0.45))
		draw_string(font, Vector2(0, 440), "FRUIT FALL", HORIZONTAL_ALIGNMENT_CENTER, 720, 100, FruitArt.INK)
		draw_string(font, Vector2(0, 500), "果 実 落 下", HORIZONTAL_ALIGNMENT_CENTER, 720, 38, Color("c8282d"))
		# tray frame
		var sb2 := StyleBoxFlat.new()
		sb2.bg_color = Color("3b2014")
		sb2.set_corner_radius_all(8)
		sb2.border_color = FruitArt.INK
		sb2.set_border_width_all(3)
		draw_style_box(sb2, Rect2(64, 536, 592, 254))
		draw_string(font, Vector2(0, 1230), "an ukiyo-e merging puzzle", HORIZONTAL_ALIGNMENT_CENTER, 720, 26, Color(FruitArt.INK, 0.5))


class Parade extends Control:
	var t := 0.0
	const SC := 0.41

	func _process(d: float) -> void:
		t += d
		queue_redraw()

	func _draw() -> void:
		var x := 86.0
		var floor_y := 772.0
		for i in 10:
			var r := FruitArt.RADII[i] * SC
			var rock := sin(t * 1.4 + i * 0.7) * 0.45
			var c := Vector2(x + r + rock * r, floor_y - r)
			draw_set_transform(c, rock, Vector2(SC, SC))
			FruitArt.draw_fruit(self, i, FruitArt.RADII[i])
			x += r * 2.0 + 0.5
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(Rect2(76, 548, 568, 230), Color("c9a24a"), false, 2.0)


func build(m: Node) -> void:
	main = m
	position = Vector2.ZERO
	size = Vector2(720, 1280)
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(720, 1280)
	bg.material = main.washi_mat
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var art := Art.new()
	art.main = main
	art.position = Vector2.ZERO
	art.size = Vector2(720, 1280)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	var sea := ColorRect.new()
	sea.position = Vector2(76, 548)
	sea.size = Vector2(568, 230)
	var m2: ShaderMaterial = main.sea_mat.duplicate()
	m2.set_shader_parameter("size", sea.size)
	m2.set_shader_parameter("R", 22.0)
	sea.material = m2
	sea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sea)
	var par := Parade.new()
	par.position = Vector2.ZERO
	par.size = Vector2(720, 1280)
	par.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(par)
	var play := Button.new()
	play.text = "PLAY"
	play.position = Vector2(200, 850)
	play.size = Vector2(320, 104)
	play.add_theme_font_size_override("font_size", 56)
	play.pressed.connect(func(): play_pressed.emit())
	add_child(play)
	best_label = Label.new()
	best_label.position = Vector2(0, 980)
	best_label.size = Vector2(720, 50)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.add_theme_color_override("font_color", Color("c8282d"))
	best_label.add_theme_font_size_override("font_size", 34)
	add_child(best_label)


func refresh() -> void:
	best_label.text = "BEST  %d" % main.best
