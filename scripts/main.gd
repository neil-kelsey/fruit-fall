extends Node2D
## Fruit Fall: game state, scene assembly, input, merging, scoring, juice.

const DROP_COOLDOWN := 0.55
const GAME_OVER_TIME := 2.0
const SPAWN_WEIGHTS := [30, 26, 20, 14, 10]
const MERGE_POINTS := [0, 1, 3, 6, 10, 15, 21, 28, 36, 45, 55]
const WATERMELON_CLEAR := 100
const SAVE_PATH := "user://fruitfall.cfg"
const FruitScript := preload("res://scripts/fruit.gd")

enum State { TITLE, PLAYING, OVER }

var state := State.TITLE
var score := 0
var best := 0
var muted := false
var cur_tier := 0
var next_tier := -1
var cooldown := 0.0
var input_block := 0.0
var combo := 0
var combo_timer := 0.0
var trauma := 0.0
var font: FontFile
var washi_mat: ShaderMaterial
var sea_mat: ShaderMaterial
var theme_res: Theme
var camera: Camera2D
var fruits_node: Node2D
var dropper: Dropper
var fx: Fx
var sfx: Sfx
var hud: Control
var callouts: Control
var title: Control
var gameover: Control
var petals: Petals
var mute_btn: Button
var rng := RandomNumberGenerator.new()
var forced_queue: Array[int] = []
var stats := {"drops": 0, "merges": 0, "max_tier": 0, "fast": 0}
var autotest := false
var _guide_shapes: Array[CircleShape2D] = []
var _held_keys := 0.0
var ui: CanvasLayer


func _ready() -> void:
	rng.randomize()
	_load_cfg()
	var args := OS.get_cmdline_user_args()
	autotest = "--autotest" in args
	if autotest:
		rng.seed = 20261112
	font = load("res://fonts/YujiSyuku-Subset.ttf")
	washi_mat = ShaderMaterial.new()
	washi_mat.shader = load("res://shaders/washi.gdshader")
	sea_mat = ShaderMaterial.new()
	sea_mat.shader = load("res://shaders/seigaiha.gdshader")
	_build_theme()

	camera = Camera2D.new()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(camera)
	camera.make_current()

	# Oversized so the paper also fills the extra margin on taller/wider screens (stretch aspect "expand").
	var bg := ColorRect.new()
	bg.position = Vector2(-600, -900)
	bg.size = Vector2(1920, 3080)
	var bg_mat: ShaderMaterial = washi_mat.duplicate()
	bg_mat.set_shader_parameter("size", bg.size)
	bg.material = bg_mat
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var sea := ColorRect.new()
	sea.position = Vector2(Layout.INNER_L, Layout.BOX_TOP)
	sea.size = Vector2(Layout.INNER_R - Layout.INNER_L, Layout.FLOOR_Y - Layout.BOX_TOP)
	var sm: ShaderMaterial = sea_mat.duplicate()
	sm.set_shader_parameter("size", sea.size)
	sea.material = sm
	sea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sea)

	_build_walls()
	fruits_node = Node2D.new()
	add_child(fruits_node)
	var front := Node2D.new()
	front.set_script(load("res://scripts/box_front.gd"))
	add_child(front)
	fx = Fx.new()
	add_child(fx)
	dropper = Dropper.new()
	dropper.main = self
	add_child(dropper)
	sfx = Sfx.new()
	add_child(sfx)
	for r in FruitArt.RADII:
		var cs := CircleShape2D.new()
		cs.radius = r
		_guide_shapes.append(cs)

	ui = CanvasLayer.new()
	add_child(ui)
	hud = Control.new()
	hud.set_script(load("res://scripts/hud.gd"))
	hud.main = self
	hud.theme = theme_res
	ui.add_child(hud)
	callouts = Control.new()
	callouts.position = Vector2.ZERO
	callouts.size = Vector2(720, 1280)
	callouts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(callouts)
	gameover = Control.new()
	gameover.set_script(load("res://scripts/gameover.gd"))
	gameover.theme = theme_res
	ui.add_child(gameover)
	gameover.build(self)
	gameover.retry_pressed.connect(func(): sfx.play_click(); start_game())
	gameover.home_pressed.connect(func(): sfx.play_click(); show_title())
	title = Control.new()
	title.set_script(load("res://scripts/title.gd"))
	title.theme = theme_res
	ui.add_child(title)
	title.build(self)
	title.play_pressed.connect(func(): sfx.play_click(); start_game())
	petals = Petals.new()
	ui.add_child(petals)
	mute_btn = Button.new()
	mute_btn.theme = theme_res
	mute_btn.theme_type_variation = &"SecondaryButton"
	mute_btn.position = Vector2(596, 1206)
	mute_btn.size = Vector2(104, 52)
	mute_btn.focus_mode = Control.FOCUS_NONE
	mute_btn.add_theme_font_size_override("font_size", 24)
	mute_btn.pressed.connect(toggle_mute)
	ui.add_child(mute_btn)
	AudioServer.set_bus_volume_db(0, -3.0)
	AudioServer.add_bus_effect(0, AudioEffectHardLimiter.new())
	_apply_mute()
	show_title()
	get_viewport().size_changed.connect(_fit_screen)
	_fit_screen()
	if autotest:
		_autotest.call_deferred()


func _build_theme() -> void:
	theme_res = Theme.new()
	theme_res.default_font = font
	theme_res.default_font_size = 40
	var cream := Color("f5e8cc")
	var red := Color("c8282d")
	var mk := func(bg: Color, border: Color) -> StyleBoxFlat:
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg
		sb.border_color = border
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(6)
		sb.shadow_color = Color(0.15, 0.08, 0.04, 0.3)
		sb.shadow_offset = Vector2(0, 5)
		sb.shadow_size = 1
		return sb
	theme_res.set_stylebox("normal", "Button", mk.call(red, Color("7a1218")))
	theme_res.set_stylebox("hover", "Button", mk.call(Color("d8383c"), Color("7a1218")))
	theme_res.set_stylebox("pressed", "Button", mk.call(Color("a51e23"), Color("5e0d12")))
	theme_res.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		theme_res.set_color(c, "Button", cream)
	theme_res.set_type_variation(&"SecondaryButton", &"Button")
	theme_res.set_stylebox("normal", "SecondaryButton", mk.call(cream, red))
	theme_res.set_stylebox("hover", "SecondaryButton", mk.call(Color("fbf1dc"), red))
	theme_res.set_stylebox("pressed", "SecondaryButton", mk.call(Color("e9d8b4"), red))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		theme_res.set_color(c, "SecondaryButton", red)


func _build_walls() -> void:
	var body := StaticBody2D.new()
	var mat := PhysicsMaterial.new()
	mat.friction = 0.6
	mat.bounce = 0.05
	body.physics_material_override = mat
	var top := -800.0
	_add_rect(body, Rect2(Layout.INNER_L - 60.0, top, 60.0, Layout.FLOOR_Y - top + 60.0))
	_add_rect(body, Rect2(Layout.INNER_R, top, 60.0, Layout.FLOOR_Y - top + 60.0))
	_add_rect(body, Rect2(Layout.INNER_L - 60.0, Layout.FLOOR_Y, Layout.INNER_R - Layout.INNER_L + 120.0, 80.0))
	for pts in [[Vector2(Layout.INNER_L, Layout.FLOOR_Y - 14), Vector2(Layout.INNER_L, Layout.FLOOR_Y + 1), Vector2(Layout.INNER_L + 14, Layout.FLOOR_Y + 1)],
			[Vector2(Layout.INNER_R, Layout.FLOOR_Y - 14), Vector2(Layout.INNER_R - 14, Layout.FLOOR_Y + 1), Vector2(Layout.INNER_R, Layout.FLOOR_Y + 1)]]:
		var cs := CollisionShape2D.new()
		var poly := ConvexPolygonShape2D.new()
		poly.points = PackedVector2Array(pts)
		cs.shape = poly
		body.add_child(cs)
	add_child(body)


func _add_rect(body: Node, r: Rect2) -> void:
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	cs.shape = rs
	cs.position = r.get_center()
	body.add_child(cs)


# ---------------------------------------------------------------- state

func show_title() -> void:
	state = State.TITLE
	_clear_fruits()
	gameover.visible = false
	petals.start(1.2)
	title.refresh()
	title.visible = true
	hud.visible = false
	dropper.visible = false


func start_game() -> void:
	_clear_fruits()
	score = 0
	combo = 0
	trauma = 0.0
	stats = {"drops": 0, "merges": 0, "max_tier": 0, "fast": 0}
	cur_tier = _rand_tier()
	next_tier = _rand_tier()
	cooldown = 0.0
	input_block = 0.25
	dropper.set_held(cur_tier)
	dropper.visible = true
	title.visible = false
	gameover.visible = false
	hud.visible = true
	petals.stop()
	state = State.PLAYING


func _clear_fruits() -> void:
	for f in fruits_node.get_children():
		fruits_node.remove_child(f)
		f.queue_free()


func _rand_tier() -> int:
	if not forced_queue.is_empty():
		return forced_queue.pop_front()
	var total := 0
	for w in SPAWN_WEIGHTS:
		total += w
	var r := rng.randi_range(0, total - 1)
	for i in SPAWN_WEIGHTS.size():
		r -= SPAWN_WEIGHTS[i]
		if r < 0:
			return i
	return 0


func _game_over() -> void:
	state = State.OVER
	dropper.release()
	var nb := score > best
	if nb:
		best = score
		_save_cfg()
	sfx.play_over()
	trauma = minf(1.0, trauma + 0.35)
	petals.start(14.0)
	for f: Fruit in fruits_node.get_children():
		f.merging = true  # no more merges or scoring after game over
	print("GAME_OVER score=%d drops=%d merges=%d max_tier=%d" % [score, stats.drops, stats.merges, stats.max_tier])
	get_tree().create_timer(0.9).timeout.connect(func(): if state == State.OVER: gameover.show_result(score, best, nb))


# ---------------------------------------------------------------- input

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_M:
		toggle_mute()
		return
	if state != State.PLAYING:
		return
	if e is InputEventMouseMotion:
		dropper.target_x = get_global_mouse_position().x
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		dropper.target_x = get_global_mouse_position().x
		if not e.pressed and input_block <= 0.0:
			drop()
	elif e is InputEventKey and e.pressed and not e.echo:
		if e.keycode in [KEY_SPACE, KEY_ENTER, KEY_DOWN, KEY_S]:
			drop()


func drop() -> void:
	if state != State.PLAYING or dropper.held_tier < 0 or cooldown > 0.0:
		return
	var f: Fruit = FruitScript.new()
	f.setup(cur_tier)
	f.position = dropper.held_pos()
	f.rotation = dropper.held_rot()
	f.linear_velocity = Vector2(dropper.held_vx() * 0.3, 40.0)
	f.angular_velocity = dropper.theta_v * 0.6
	_connect_fruit(f)
	fruits_node.add_child(f)
	sfx.play_drop()
	dropper.release()
	cur_tier = next_tier
	next_tier = _rand_tier()
	hud.on_next()
	cooldown = DROP_COOLDOWN
	combo = 0
	stats.drops += 1


func _connect_fruit(f: Fruit) -> void:
	f.impacted.connect(_on_impact)
	f.merge_request.connect(_on_merge_request)


func toggle_mute() -> void:
	muted = not muted
	_apply_mute()
	_save_cfg()


func _apply_mute() -> void:
	AudioServer.set_bus_mute(0, muted)
	mute_btn.text = "MUTED" if muted else "SOUND"


# ---------------------------------------------------------------- loop

func _process(delta: float) -> void:
	input_block -= delta
	combo_timer -= delta
	if combo_timer <= 0.0:
		combo = 0
	if state == State.PLAYING:
		var dir := 0.0
		if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
			dir -= 1.0
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
			dir += 1.0
		if dir != 0.0:
			dropper.target_x += dir * 640.0 * delta
		if cooldown > 0.0:
			cooldown -= delta
			if cooldown <= 0.0:
				dropper.set_held(cur_tier)
	trauma = maxf(0.0, trauma - delta * 1.5)
	var sh := trauma * trauma
	camera.offset = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 26.0 * sh


func _physics_process(delta: float) -> void:
	if state == State.TITLE:
		return
	var maxd := 0.0
	var buckets := {}
	for f: Fruit in fruits_node.get_children():
		if f.merging:
			continue
		if not buckets.has(f.tier):
			buckets[f.tier] = []
		buckets[f.tier].append(f)
		if f.has_landed and f.age > 0.6 and f.global_position.y - f.radius < Layout.DANGER_Y:
			f.danger_time += delta
		else:
			f.danger_time = maxf(0.0, f.danger_time - delta * 2.0)
		maxd = maxf(maxd, f.danger_time)
		if autotest and f.has_landed and f.age > 1.5 and f.linear_velocity.length() > 1400.0:
			stats.fast += 1
	# visually-touching same-tier fruits (resting with a sub-pixel gap) also merge
	for arr in buckets.values():
		for i in arr.size():
			for j in range(i + 1, arr.size()):
				var a: Fruit = arr[i]
				var b: Fruit = arr[j]
				if a.global_position.distance_to(b.global_position) - a.radius - b.radius < 1.5:
					a.touch(b)
	dropper.danger = clampf(maxd / GAME_OVER_TIME * 1.5, 0.0, 1.0)
	if state == State.PLAYING and maxd >= GAME_OVER_TIME:
		_game_over()
	# predicted landing for the dotted guide
	if dropper.held_tier >= 0:
		var start := Vector2(dropper.held_pos().x, Layout.HOLD_Y)
		var q := PhysicsShapeQueryParameters2D.new()
		q.shape = _guide_shapes[dropper.held_tier]
		q.transform = Transform2D(0.0, start)
		q.motion = Vector2(0.0, Layout.FLOOR_Y - start.y)
		var res := get_world_2d().direct_space_state.cast_motion(q)
		dropper.guide_y = start.y + q.motion.y * res[0] if res.size() > 0 else -1.0


# ---------------------------------------------------------------- physics events

func _on_impact(f: Fruit, point: Vector2, normal: Vector2, strength: float) -> void:
	if strength < 240.0:
		return
	fx.puff(point, normal, strength, f.radius)
	sfx.play_thunk(f.tier, strength)


func _on_merge_request(a: Fruit, b: Fruit) -> void:
	if state != State.PLAYING or a.merging or b.merging:
		return
	a.merging = true
	b.merging = true
	_do_merge.call_deferred(a, b)


func _do_merge(a: Fruit, b: Fruit) -> void:
	if not is_instance_valid(a) or not is_instance_valid(b):
		return
	var t := a.tier
	var mid := (a.global_position + b.global_position) * 0.5
	var vel := (a.linear_velocity + b.linear_velocity) * 0.5
	var spin := (a.angular_velocity + b.angular_velocity) * 0.5
	var rot := a.rotation
	for f in [a, b]:
		fruits_node.remove_child(f)
		f.queue_free()
	var new_t := t + 1
	combo = combo + 1 if combo_timer > 0.0 else 1
	combo_timer = 0.8
	stats.merges += 1
	stats.max_tier = maxi(stats.max_tier, new_t)
	var pts: int = WATERMELON_CLEAR if t >= 9 else MERGE_POINTS[new_t]
	if combo > 1:
		pts += int(pts * 0.5 * (combo - 1))
	score += pts
	hud.on_score()
	var newf: Fruit = null
	var R := FruitArt.RADII[mini(new_t, 9)]
	if t < 9:
		newf = FruitScript.new()
		newf.setup(new_t, FruitArt.RADII[t])
		var rr := FruitArt.RADII[t]
		newf.position = Vector2(clampf(mid.x, Layout.INNER_L + rr, Layout.INNER_R - rr), minf(mid.y, Layout.FLOOR_Y - rr))
		newf.rotation = rot
		newf.linear_velocity = vel * 0.4 + Vector2(0.0, -150.0)
		newf.angular_velocity = spin * 0.5 + rng.randf_range(-2.0, 2.0)
		newf.has_landed = true
		newf.age = 1.0
		_connect_fruit(newf)
		fruits_node.add_child(newf)
	# wake neighbours and give them a small outward pop
	for o: Fruit in fruits_node.get_children():
		if o == newf or o.merging:
			continue
		var d := o.global_position - mid
		var dist := d.length()
		if dist < R + o.radius + 60.0:
			var k := 1.0 - clampf(dist / (R + o.radius + 60.0), 0.0, 1.0)
			o.nudge(d.normalized() * o.mass * (30.0 + 50.0 * k))
	var col := FruitArt.COLORS[mini(new_t, 9)]
	fx.burst(mid, col, mini(new_t, 9), R)
	sfx.play_merge(new_t, combo)
	if new_t >= 4:
		trauma = minf(1.0, trauma + 0.12 * (new_t - 3))
	var label := "Watermelon clear!" if t >= 9 else FruitArt.NAMES[new_t] + "!"
	if new_t >= 3 or t >= 9:
		_callout(label + "  +%d" % pts, mid + Vector2(0, -R - 20.0), col.lerp(FruitArt.INK, 0.2), 34 + new_t * 2)
	elif combo < 2:
		_callout("+%d" % pts, mid + Vector2(0, -R - 10.0), Color("f5e8cc"), 30)
	if combo >= 2:
		_callout("COMBO ×%d" % combo, Vector2(360, 400), Color("c8282d"), 44 + mini(combo, 6) * 4)
	if autotest:
		print("MERGE %s+%s -> %s at (%.0f, %.0f) combo=%d score=%d" % [FruitArt.NAMES[t], FruitArt.NAMES[t], ("clear" if t >= 9 else FruitArt.NAMES[new_t]), mid.x, mid.y, combo, score])


func _callout(text: String, pos: Vector2, col: Color, size: int) -> void:
	var l := Label.new()
	l.text = text
	var ls := LabelSettings.new()
	ls.font = font
	ls.font_size = size
	ls.font_color = col
	ls.outline_size = 10
	ls.outline_color = Color("f5e8cc") if col.get_luminance() < 0.6 else FruitArt.INK
	ls.shadow_color = Color(0, 0, 0, 0.25)
	ls.shadow_offset = Vector2(2, 3)
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	callouts.add_child(l)
	l.reset_size()
	l.pivot_offset = l.size * 0.5
	l.position = Vector2(clampf(pos.x - l.size.x * 0.5, 10.0, 710.0 - l.size.x), pos.y - l.size.y * 0.5)
	l.scale = Vector2(0.3, 0.3)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "scale", Vector2.ONE, 0.1)
	tw.parallel().tween_property(l, "position:y", l.position.y - 70.0, 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.45).set_delay(0.5)
	tw.tween_callback(l.queue_free)


# ---------------------------------------------------------------- save

func _load_cfg() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best = int(cfg.get_value("game", "best", 0))
		muted = bool(cfg.get_value("game", "muted", false))


## Centre the 720x1280 design inside whatever the viewport expanded to (phones taller than 16:9, tablets wider).
func _fit_screen() -> void:
	var vs := get_viewport().get_visible_rect().size
	var off := ((vs - Vector2(Layout.W, Layout.H)) * 0.5).max(Vector2.ZERO).floor()
	camera.position = -off
	ui.offset = off


func _save_cfg() -> void:
	if autotest:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("game", "best", best)
	cfg.set_value("game", "muted", muted)
	cfg.save(SAVE_PATH)


# ---------------------------------------------------------------- automated test

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://shots") if OS.has_feature("editor") else OS.get_user_data_dir() + "/shots"
	DirAccess.make_dir_recursive_absolute(dir)
	var img := get_viewport().get_texture().get_image()
	img.save_png(dir + "/" + name + ".png")
	print("SHOT ", name)


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _report(label: String) -> void:
	var n := 0
	var sleeping_n := 0
	var spin_sum := 0.0
	var max_spin := 0.0
	var speed_sum := 0.0
	for f: Fruit in fruits_node.get_children():
		n += 1
		if f.sleeping:
			sleeping_n += 1
		spin_sum += f.total_spin
		max_spin = maxf(max_spin, f.total_spin)
		speed_sum += f.linear_velocity.length()
	print("%s fruits=%d sleeping=%d avg_speed=%.1f total_rot=%.1frad max_rot=%.1frad merges=%d fast=%d score=%d" % [label, n, sleeping_n, speed_sum / maxf(1, n), spin_sum, max_spin, stats.merges, stats.fast, score])


func _autotest() -> void:
	var clip := "--clip" in OS.get_cmdline_user_args()
	muted = false
	await _wait(1.5)
	await _shot("title")
	start_game()
	forced_queue = [0, 1, 1, 2, 0, 0]
	cur_tier = 0
	next_tier = 0
	dropper.set_held(0)
	# 1) two cherries must merge into a strawberry
	for x in [250.0, 262.0]:
		dropper.target_x = x
		await _wait(0.65)
		drop()
	for _n in 14:
		await get_tree().physics_frame
		if "--debug" in OS.get_cmdline_user_args():
			for f: Fruit in fruits_node.get_children():
				print("  dbg t=%d pos=(%.0f,%.0f) v=(%.0f,%.0f) contacts=%d bodies=%s" % [f.tier, f.position.x, f.position.y, f.linear_velocity.x, f.linear_velocity.y, f.get_contact_count(), str(f.get_colliding_bodies().map(func(b): return b.name))])
	await _shot("merge_moment")
	await _wait(1.0)
	_report("after_cherry_test")
	# 2) build a pile with varied drops, watch for rolling
	var xs := [140.0, 560.0, 330.0, 420.0, 200.0, 600.0, 300.0, 480.0, 120.0, 380.0, 520.0, 240.0, 450.0, 160.0, 610.0, 350.0, 280.0, 500.0, 210.0, 430.0, 580.0, 330.0]
	var i := 0
	for x in xs:
		dropper.target_x = x
		await _wait(0.42)
		drop()
		await _wait(0.4)
		i += 1
		if i % 4 == 0:
			_report("t%02d" % i)
		if i == 14:
			await _shot("gameplay_pile")
		if state != State.PLAYING:
			break
	await _wait(2.5)
	_report("settled")
	await _shot("gameplay_settled")
	if clip:
		await _wait(0.5)
	# 3) force a game over by stacking in the middle
	var t0 := Time.get_ticks_msec()
	forced_queue = []
	for n in 40:
		forced_queue.append([8, 5, 7, 6, 4][n % 5])
	var k := 0
	while state == State.PLAYING and k < 60:
		dropper.target_x = [360.0, 200.0, 520.0, 300.0, 440.0, 120.0, 600.0][k % 7]
		await _wait(0.3)
		drop()
		await _wait(0.35)
		k += 1
	await _wait(2.6)
	_report("end")
	await _shot("gameover")
	print("AUTOTEST_DONE state=%d" % state)
	get_tree().quit()
