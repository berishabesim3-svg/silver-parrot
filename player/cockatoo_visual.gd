extends Node3D
## Trup i përkohshëm procedural i kakadusë: i bardhë, kreshtë e verdhë, sy shprehës, bark i rëndë.
## Zëvendësohet me modelin përfundimtar sipas referencave; API-ja (set_emotion, flap, squash) mbetet.

const EMOTIONS := {
	"kureshtje": {"crest": 35.0, "eye": 1.25, "lean": 8.0},
	"alarm": {"crest": 75.0, "eye": 1.5, "lean": -12.0},
	"krenari": {"crest": 60.0, "eye": 1.0, "lean": -6.0},
	"butesi": {"crest": 10.0, "eye": 0.85, "lean": 4.0},
	"fokus": {"crest": 5.0, "eye": 0.9, "lean": 14.0},
	"lehtesim": {"crest": 20.0, "eye": 1.1, "lean": 0.0},
}

var emotion := "kureshtje"
var _crest_angle := 35.0
var _eye_scale := 1.25
var _lean := 8.0
var _squash := 0.0
var _flap := 0.0
var _gliding := false
var _body_root: Node3D
var _feathers: Array = []
var _eyes: Array = []
var _wings: Array = []

func _ready() -> void:
	_body_root = Node3D.new()
	add_child(_body_root)
	var white := Color(0.97, 0.97, 0.95)
	_part(SphereMesh.new(), Vector3(0, 0.45, 0.05), Vector3(0.8, 0.85, 0.9), white)
	_part(SphereMesh.new(), Vector3(0, 0.98, -0.1), Vector3(0.5, 0.5, 0.5), white)
	_part(BoxMesh.new(), Vector3(0, 0.93, -0.38), Vector3(0.12, 0.16, 0.2), Color(0.25, 0.25, 0.28))
	_part(BoxMesh.new(), Vector3(0, 0.4, 0.55), Vector3(0.3, 0.06, 0.45), white)
	_part(BoxMesh.new(), Vector3(-0.15, 0.03, -0.05), Vector3(0.12, 0.06, 0.25), Color(0.4, 0.4, 0.42))
	_part(BoxMesh.new(), Vector3(0.15, 0.03, -0.05), Vector3(0.12, 0.06, 0.25), Color(0.4, 0.4, 0.42))
	for side in [-1.0, 1.0]:
		var eye := _part(SphereMesh.new(), Vector3(0.17 * side, 1.03, -0.28), Vector3(0.09, 0.09, 0.09), Color(0.05, 0.05, 0.05))
		_eyes.append(eye)
		var wing := _part(SphereMesh.new(), Vector3(0.42 * side, 0.5, 0.1), Vector3(0.14, 0.55, 0.7), Color(0.93, 0.93, 0.9))
		_wings.append(wing)
	for i in 5:
		var pivot := Node3D.new()
		pivot.position = Vector3((i - 2) * 0.05, 1.2, -0.05)
		_body_root.add_child(pivot)
		var f := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.05, 0.38, 0.09)
		f.mesh = bm
		f.position = Vector3(0, 0.19, 0)
		f.material_override = _mat(Color(1.0, 0.85, 0.1))
		pivot.add_child(f)
		_feathers.append(pivot)

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m

func _part(mesh: Mesh, pos: Vector3, scl: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.scale = scl
	mi.material_override = _mat(c)
	_body_root.add_child(mi)
	return mi

func set_emotion(e: String) -> void:
	if EMOTIONS.has(e):
		emotion = e

func flap() -> void:
	_flap = 1.0

func squash(amount: float) -> void:
	_squash = clampf(amount, 0.0, 1.0)

func set_gliding(g: bool) -> void:
	_gliding = g

func _process(delta: float) -> void:
	var target: Dictionary = EMOTIONS[emotion]
	_crest_angle = lerpf(_crest_angle, float(target["crest"]), minf(1.0, delta * 8.0))
	_eye_scale = lerpf(_eye_scale, float(target["eye"]), minf(1.0, delta * 8.0))
	_lean = lerpf(_lean, float(target["lean"]), minf(1.0, delta * 5.0))
	_squash = move_toward(_squash, 0.0, delta * 3.0)
	_flap = move_toward(_flap, 0.0, delta * 4.0)
	for i in _feathers.size():
		var spread := deg_to_rad((i - 2) * 9.0) * (_crest_angle / 75.0)
		_feathers[i].rotation.x = deg_to_rad(85.0 - _crest_angle) + spread
	for eye in _eyes:
		eye.scale = Vector3.ONE * 0.09 * _eye_scale
	# Pesha komike: trupi shtypet në ulje dhe lëkundet ngadalë.
	_body_root.scale = Vector3(1.0 + _squash * 0.35, 1.0 - _squash * 0.4, 1.0 + _squash * 0.35)
	_body_root.rotation.x = deg_to_rad(-_lean)
	var wing_open := 0.0
	if _gliding:
		wing_open = 1.2
	wing_open += sin(_flap * PI) * 1.4
	_wings[0].rotation.z = wing_open
	_wings[1].rotation.z = -wing_open
