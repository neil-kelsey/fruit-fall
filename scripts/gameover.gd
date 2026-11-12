extends Control
## Game-over scroll that unrolls, with a 終 hanko, score, best and buttons.
signal retry_pressed
signal home_pressed

var main: Node
var unroll := 0.0
var fade := 0.0
var score := 0
var best := 0
var new_best := false
var content: Control


class Art extends Control:
	var go: Control

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var u: float = go.unroll
		draw_rect(Rect2(0, 0, 720, 1280), Color(0.06, 0.08, 0.18, 0.5 * minf(1.0, u * 2.0)))
		var h := 40.0 + 600.0 * Dropper.ease_out(u)
		var c := Vector2(360, 640)
		var paper := Rect2(c.x - 250, c.y - h * 0.5, 500, h)
		draw_rect(paper, Color("f4e7cb"))
		draw_rect(Rect2(paper.position + Vector2(18, 0), Vector2(464, h)), Color("efdcb8"), false, 2.0)
		draw_rect(paper, FruitArt.INK, false, 2.5)
		for y in [paper.position.y, paper.end.y]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color("4a2a18")
			sb.set_corner_radius_all(12)
			sb.border_color = FruitArt.INK
			sb.set_border_width_all(2)
			draw_style_box(sb, Rect2(c.x - 280, y - 14, 560, 28))
			for side in [-1.0, 1.0]:
				draw_circle(Vector2(c.x + side * 286, y), 12, Color("c9a24a"), true, -1.0, true)
				draw_circle(Vector2(c.x + side * 286, y), 12, FruitArt.INK, false, 2.0, true)
		if go.fade <= 0.0:
			return
		var a: float = go.fade
		var font: Font = go.main.font
		var ink := Color(FruitArt.INK, a)
		var red := Color("c8282d", a)
		# 終 hanko
		draw_set_transform(Vector2(360, 420), 0.08, Vector2.ONE * (1.0 + (1.0 - a) * 0.6))
		var hs := StyleBoxFlat.new()
		hs.bg_color = red
		hs.set_corner_radius_all(8)
		draw_style_box(hs, Rect2(-48, -48, 96, 96))
		draw_string(font, Vector2(-48, 26), "終", HORIZONTAL_ALIGNMENT_CENTER, 96, 72, Color("f5e8cc", a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_string(font, Vector2(0, 540), "GAME OVER", HORIZONTAL_ALIGNMENT_CENTER, 720, 52, ink)
		draw_string(font, Vector2(0, 600), "SCORE", HORIZONTAL_ALIGNMENT_CENTER, 720, 28, red)
		draw_string(font, Vector2(0, 690), str(go.score), HORIZONTAL_ALIGNMENT_CENTER, 720, 96, ink)
		draw_string(font, Vector2(0, 750), ("NEW BEST!" if go.new_best else "BEST  %d" % go.best), HORIZONTAL_ALIGNMENT_CENTER, 720, 34, red)


func build(m: Node) -> void:
	main = m
	position = Vector2.ZERO
	size = Vector2(720, 1280)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var art := Art.new()
	art.go = self
	art.position = Vector2.ZERO
	art.size = Vector2(720, 1280)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	content = Control.new()
	content.position = Vector2.ZERO
	content.size = Vector2(720, 1280)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	var retry := Button.new()
	retry.text = "RETRY"
	retry.position = Vector2(150, 800)
	retry.size = Vector2(200, 84)
	retry.pressed.connect(func(): retry_pressed.emit())
	content.add_child(retry)
	var home := Button.new()
	home.text = "HOME"
	home.position = Vector2(370, 800)
	home.size = Vector2(200, 84)
	home.theme_type_variation = &"SecondaryButton"
	home.pressed.connect(func(): home_pressed.emit())
	content.add_child(home)
	visible = false


func show_result(s: int, b: int, nb: bool) -> void:
	score = s
	best = b
	new_best = nb
	unroll = 0.0
	fade = 0.0
	content.modulate.a = 0.0
	visible = true
	var tw := create_tween()
	tw.tween_property(self, "unroll", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "fade", 1.0, 0.35)
	tw.parallel().tween_property(content, "modulate:a", 1.0, 0.35)
