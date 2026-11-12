extends Area3D
## Shtjellë ere: 4 rrahje ndezur, 4 fikur. Paralajmërohet një rrahje përpara
## me titër dhe me vizatim gjysmë të tejdukshëm.

var push := Vector3.RIGHT * 7.0
var mesh: MeshInstance3D
var _bodies: Array = []
var active := false

func _ready() -> void:
	body_entered.connect(func(b): _bodies.append(b))
	body_exited.connect(_on_exit)
	AudioDirector.beat.connect(_on_beat)
	_apply(false)

func _on_exit(b: Node) -> void:
	_bodies.erase(b)
	if "external_push" in b:
		b.external_push = Vector3.ZERO

func _on_beat(index: int) -> void:
	var step := index % 8
	if step == 3:
		AudioDirector.announce("ere", "Erë pas 1 rrahjeje")
	_apply(step >= 4)

func _apply(on: bool) -> void:
	active = on
	if mesh:
		mesh.visible = on
	for b in _bodies:
		if "external_push" in b:
			b.external_push = push if on else Vector3.ZERO
