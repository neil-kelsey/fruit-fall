class_name Fruit
extends RigidBody2D
## A fruit is a real RigidBody2D with a CircleShape2D. Rotation is never frozen;
## friction makes fruits roll over each other. Squash/stretch is visual only.

signal impacted(fruit: Fruit, point: Vector2, normal: Vector2, strength: float)
signal merge_request(a: Fruit, b: Fruit)

const FRICTION := 0.85          # fruit-fruit friction uses min() -> 0.85
const BOUNCE := 0.1             # Godot adds both bounces: fruit-fruit 0.2, fruit-wall 0.15
const MASS_PER_R2 := 1.0 / 400.0 # cherry (r=20) = 1.0, watermelon = 38
const MERGE_DELAY := 0.025  # s after first real contact
const MERGE_SLACK := 24.0   # px gap still counted as touching during the window
const GROW_TIME := 0.16

static var fruit_material: PhysicsMaterial

var tier := 0
var radius := 20.0
var target_radius := 20.0
var merging := false
var age := 0.0
var has_landed := false
var danger_time := 0.0
var total_spin := 0.0

var _shape: CircleShape2D
var _visual: Node2D
var _contact_time := {}
var _last_vel := Vector2.ZERO
var _squash := 0.0
var _squash_v := 0.0
var _squash_dir := Vector2.DOWN
var _grow_t := 1.0
var _grow_from := 0.0
var _pop := 0.0
var _impact_cd := 0.0
var _last_rot := 0.0


func setup(t: int, grow_from: float = -1.0) -> void:
	tier = t
	target_radius = FruitArt.RADII[t]
	if fruit_material == null:
		fruit_material = PhysicsMaterial.new()
		fruit_material.friction = FRICTION
		fruit_material.bounce = BOUNCE
	physics_material_override = fruit_material
	mass = target_radius * target_radius * MASS_PER_R2
	linear_damp = 0.05
	angular_damp = 2.0   # light rolling resistance so fruits come to rest
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	can_sleep = true
	contact_monitor = true
	max_contacts_reported = 8
	_shape = CircleShape2D.new()
	if grow_from > 0.0:
		_grow_from = grow_from
		_grow_t = 0.0
		radius = grow_from
		_pop = 1.0
	else:
		radius = target_radius
	_shape.radius = radius
	var cs := CollisionShape2D.new()
	cs.shape = _shape
	add_child(cs)
	_visual = preload("res://scripts/fruit_visual.gd").new()
	_visual.tier = t
	add_child(_visual)
	_last_rot = rotation
	_update_visual()


func _physics_process(delta: float) -> void:
	age += delta
	_impact_cd -= delta
	if _grow_t < 1.0:
		_grow_t = minf(1.0, _grow_t + delta / GROW_TIME)
		var e := 1.0 - pow(1.0 - _grow_t, 3.0)
		radius = lerpf(_grow_from, target_radius, e)
		_shape.radius = radius
	total_spin += absf(angle_difference(_last_rot, rotation))
	_last_rot = rotation

	var v := linear_velocity
	var count := get_contact_count()
	if count > 0:
		has_landed = true
	var dv := _last_vel - v
	var s := dv.length()
	if count > 0 and s > 170.0 and _impact_cd <= 0.0:
		var n := dv / s
		_squash_dir = n
		_squash = maxf(_squash, clampf(s / 4500.0, 0.0, 0.11))
		_squash_v = 0.0
		_impact_cd = 0.1
		impacted.emit(self, global_position + n * radius, n, s)
	_last_vel = v

	if merging:
		return
	# Merge rule: a real physics contact between two same-tier fruits starts a
	# short pending window; the merge fires if they are still touching or within
	# a few px after MERGE_DELAY. Fast glancing hits still merge, near-misses never do.
	for b in get_colliding_bodies():
		if b is Fruit and b.tier == tier and not b.merging:
			var id := b.get_instance_id()
			if not _contact_time.has(id):
				_contact_time[id] = 0.0
	for k in _contact_time.keys():
		var o = instance_from_id(k)
		if o == null or not is_instance_valid(o) or o.merging or not o.is_inside_tree():
			_contact_time.erase(k)
			continue
		var gap: float = global_position.distance_to(o.global_position) - radius - o.radius
		if gap > MERGE_SLACK:
			_contact_time.erase(k)
			continue
		_contact_time[k] += delta
		if _contact_time[k] >= MERGE_DELAY and get_instance_id() < k:
			merge_request.emit(self, o)
			return
		elif _contact_time[k] >= MERGE_DELAY * 2.0:
			merge_request.emit(o, self)
			return


func _process(delta: float) -> void:
	# Visual jelly spring for squash (does not touch the physics body).
	_squash_v += (-900.0 * _squash - 26.0 * _squash_v) * delta
	_squash += _squash_v * delta
	_pop = maxf(0.0, _pop - delta * 3.0)
	_update_visual()


func _update_visual() -> void:
	if _visual == null:
		return
	var a := clampf(_squash, -0.08, 0.12)
	var phi := _squash_dir.angle()
	var S := Transform2D(Vector2(1.0 - a, 0.0), Vector2(0.0, 1.0 + a * 0.5), Vector2.ZERO)
	var Rp := Transform2D(phi, Vector2.ZERO)
	var Rt := Transform2D(global_rotation, Vector2.ZERO)
	var sc := (radius / target_radius) * (1.0 + 0.12 * sin(PI * (1.0 - _pop)) * _pop * 2.0)
	_visual.transform = Rt.affine_inverse() * Rp * S * Rp.affine_inverse() * Rt * Transform2D(0.0, Vector2(sc, sc), 0.0, Vector2.ZERO)


## Called by Main when a same-tier fruit rests visually touching (gap < 1.5 px)
## without the solver reporting a contact.
func touch(o: Fruit) -> void:
	var id := o.get_instance_id()
	if not _contact_time.has(id):
		_contact_time[id] = 0.0


func nudge(impulse: Vector2) -> void:
	sleeping = false
	apply_central_impulse(impulse)
