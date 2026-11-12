extends Area3D
## Pengesë që fshin rrugën, e sinkronizuar me rrahjen e muzikës (lexohet me sy dhe me vesh).

var obstacle_id := "fshirese"
var axis := Vector3.RIGHT
var amplitude := 3.0
var period_beats := 4.0
var phase := 0.0
var stage
var _origin := Vector3.ZERO

func _ready() -> void:
	_origin = position
	body_entered.connect(_on_body)

func _physics_process(_delta: float) -> void:
	var period := period_beats * AudioDirector.beat_len
	position = _origin + axis * amplitude * sin(TAU * AudioDirector.song_time / period + phase)

func _on_body(body: Node) -> void:
	if stage == null or not body.has_method("is_invulnerable"):
		return
	if body.is_invulnerable():
		return
	stage.fail_player(obstacle_id)
