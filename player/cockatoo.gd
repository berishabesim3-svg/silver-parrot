extends CharacterBody3D
## Kontrolluesi i përbashkët: ngritje, planim, frenim, ulje precize, shmangie, fraza muzikore.
## I njëjti skript përdoret në çdo stazh.

signal flapped(flaps_left: int)
signal landed(precise: bool, speed: float)
signal dodged
signal note_played(index: int)
signal glided
signal braked

const VisualScript := preload("res://player/cockatoo_visual.gd")

const GRAVITY := 22.0
const WALK_SPEED := 5.5
const AIR_SPEED := 8.5
const FLAP_IMPULSE := 8.5
const MAX_FLAPS := 3
const GLIDE_FALL := 2.2
const BRAKE_FALL := 6.0
const BRAKE_DECEL := 18.0
const PRECISE_SPEED := 3.5
const STUMBLE_TIME := 0.35
const DODGE_SPEED := 13.0
const DODGE_TIME := 0.28
const DODGE_COOLDOWN := 0.9

var cam_yaw := 0.0
var flaps_left := MAX_FLAPS
var control_enabled := true
var external_push := Vector3.ZERO
var invulnerable_override := false
var gliding := false
var visual

var _stumble := 0.0
var _dodge_t := 0.0
var _dodge_cd := 0.0
var _dodge_dir := Vector3.FORWARD
var _was_on_floor := true
var _air_time := 0.0
var _glide_time := 0.0

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.1
	shape.shape = capsule
	shape.position = Vector3(0, 0.55, 0)
	add_child(shape)
	visual = VisualScript.new()
	add_child(visual)

func is_invulnerable() -> bool:
	return invulnerable_override or _dodge_t > 0.0

func teleport(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	_stumble = 0.0
	_dodge_t = 0.0
	_air_time = 0.0
	_was_on_floor = true
	flaps_left = MAX_FLAPS

func _physics_process(delta: float) -> void:
	var can_act := control_enabled and _stumble <= 0.0
	var input := Vector2.ZERO
	if can_act:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, cam_yaw)
	var on_floor := is_on_floor()
	var braking := can_act and Input.is_action_pressed("brake")

	_stumble = maxf(0.0, _stumble - delta)
	_dodge_cd = maxf(0.0, _dodge_cd - delta)

	if can_act and Input.is_action_just_pressed("dodge") and _dodge_cd <= 0.0:
		_dodge_dir = dir.normalized() if dir.length() > 0.1 else -global_transform.basis.z
		_dodge_t = DODGE_TIME
		_dodge_cd = DODGE_COOLDOWN
		dodged.emit()

	if _dodge_t > 0.0:
		_dodge_t -= delta
		velocity.x = _dodge_dir.x * DODGE_SPEED
		velocity.z = _dodge_dir.z * DODGE_SPEED
	else:
		var speed := WALK_SPEED if on_floor else AIR_SPEED
		var target := dir * speed
		var accel := 40.0 if on_floor else 14.0
		if braking:
			target = Vector3.ZERO
			accel = BRAKE_DECEL
			if not on_floor:
				braked.emit()
		velocity.x = move_toward(velocity.x, target.x, accel * delta)
		velocity.z = move_toward(velocity.z, target.z, accel * delta)

	gliding = false
	if on_floor:
		flaps_left = MAX_FLAPS
		_air_time = 0.0
		_glide_time = 0.0
	else:
		_air_time += delta
		velocity.y -= GRAVITY * delta
		if control_enabled and Input.is_action_pressed("flap") and velocity.y < 0.0 and not braking:
			gliding = true
			velocity.y = maxf(velocity.y, -GLIDE_FALL)
			_glide_time += delta
			if _glide_time > 0.5:
				glided.emit()
				_glide_time = -1000.0
		elif braking:
			velocity.y = maxf(velocity.y, -BRAKE_FALL)
		velocity.x += external_push.x * delta
		velocity.z += external_push.z * delta

	if can_act and Input.is_action_just_pressed("flap") and flaps_left > 0:
		velocity.y = FLAP_IMPULSE
		flaps_left -= 1
		visual.flap()
		flapped.emit(flaps_left)

	if can_act:
		if Input.is_action_just_pressed("note_1"):
			note_played.emit(0)
		if Input.is_action_just_pressed("note_2"):
			note_played.emit(1)
		if Input.is_action_just_pressed("note_3"):
			note_played.emit(2)

	if dir.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(1.0, 10.0 * delta))

	var h_speed := Vector2(velocity.x, velocity.z).length()
	move_and_slide()

	var now_floor := is_on_floor()
	if now_floor and not _was_on_floor and _air_time > 0.25:
		var precise := h_speed <= PRECISE_SPEED
		if precise:
			visual.squash(0.4)
		else:
			# Ulje e rëndë: trupi i madh rrëshqet dhe pengohet për pak.
			_stumble = STUMBLE_TIME
			visual.squash(1.0)
		landed.emit(precise, h_speed)
	_was_on_floor = now_floor
	visual.set_gliding(gliding)
