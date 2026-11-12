extends Camera3D
## Kamera në vetën e tretë. Horizonti mbetet gjithmonë i drejtë (pa roll) dhe
## lojtari e ruan kontrollin e kamerës edhe gjatë rrezikut. Lëkundja është vetëm
## zhvendosje e vogël dhe fiket me opsionin "redukto lëkundjen".

var target
var yaw := 0.0
var pitch := 0.38
var distance := 6.5
var desired_distance := 6.5
var _shake := 0.0

func set_distance(d: float) -> void:
	desired_distance = d

func shake(amount: float) -> void:
	if GameSettings.reduce_shake:
		return
	_shake = maxf(_shake, amount)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.004
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if target == null:
		return
	yaw -= Input.get_axis("cam_left", "cam_right") * 2.2 * delta
	target.cam_yaw = yaw
	distance = lerpf(distance, desired_distance, minf(1.0, delta * 2.5))
	var focus: Vector3 = target.global_position + Vector3(0, 1.1, 0)
	var offset := Vector3(0, sin(pitch) * distance, cos(pitch) * distance).rotated(Vector3.UP, yaw)
	var goal := focus + offset
	global_position = global_position.lerp(goal, minf(1.0, delta * 8.0))
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 2.5)
		global_position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.12
	look_at(focus, Vector3.UP)
