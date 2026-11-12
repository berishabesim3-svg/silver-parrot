extends Node3D
## Baza e përbashkët e stazheve. Çifti 1<->10 përdor të njëjtin ritëm:
##   Prova 1 (hapat e ajrit) -> checkpoint -> Prova 2 (dy rrugë A/B) -> ribashkim
##   -> Prova 3 (frazë) -> Kulmi (kalim + frazë me kthesë) -> fund.
## Nënklasat japin vetëm konfigurimin (_stage_config).

signal stage_finished(stage_id: String)

const CockatooScript := preload("res://player/cockatoo.gd")
const CameraScript := preload("res://player/follow_camera.gd")
const HudScript := preload("res://ui/hud.gd")
const SweeperScript := preload("res://stage/sweeper.gd")
const GustScript := preload("res://stage/gust.gd")
const StationScript := preload("res://stage/phrase_station.gd")

const KILL_Y := -12.0
const RESPAWN_DELAY := 0.45
const CP_ORDER := ["start", "cp1", "cp2", "cp3"]
const CAM_DIST := {"kureshtje": 6.5, "alarm": 8.0, "krenari": 5.5, "butesi": 5.0, "fokus": 7.0, "lehtesim": 6.0}

var cfg := {}
var player
var camera
var hud
var checkpoints := {}
var current_cp := "start"
var current_zone := "z_hyrje"
var stations := {}
var route_taken := ""
var finished := false
var has_ally_bridge := false
var structure := {"routes": [], "rejoin": "", "checkpoints": [], "climax": "", "trials": []}
var _respawning := false
var _recovery_beats := 0
var _zone_emotion := "kureshtje"
var _emotion_hold := 0.0
var _m := 1.0

func _stage_config() -> Dictionary:
	return {}

func _ready() -> void:
	cfg = _stage_config()
	_m = float(cfg.get("mirror", 1.0))
	Telemetry.begin_stage(cfg["id"])
	_build_environment()
	_build_course()
	_spawn_player()
	AudioDirector.beat.connect(_on_beat)
	AudioDirector.set_layer("danger", 0.0)
	AudioDirector.set_layer("coop", 0.0)
	AudioDirector.set_layer("recovery", 0.0)
	hud.set_prompt(_text("z_hyrje"))
	AudioDirector.announce("hyrje", cfg.get("intro_cue", "Një motiv dëgjohet larg"))

# ---------- ndërtimi ----------

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = cfg.get("sky", Color(0.55, 0.75, 0.95))
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.shadow_enabled = true
	add_child(sun)

func _mat(c: Color, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

## Platformë me sipërfaqen e sipërme në "top".
func _platform(top: Vector3, size_xz: Vector2, c: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = top - Vector3(0, 0.5, 0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size_xz.x, 1.0, size_xz.y)
	shape.shape = box
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mi.mesh = bm
	mi.material_override = _mat(c)
	body.add_child(mi)
	add_child(body)
	return body

func _area(center: Vector3, size: Vector3, scr: Script = null) -> Area3D:
	var a := Area3D.new()
	if scr:
		a.set_script(scr)
	a.position = center
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	a.add_child(shape)
	return a

func _zone(id: String, center: Vector3, size: Vector3, kind: String, emotion: String, danger: float, coop: float = 0.0, cp: String = "", route: String = "") -> void:
	var a := _area(center, size)
	add_child(a)
	var z := {"id": id, "kind": kind, "emotion": emotion, "danger": danger, "coop": coop, "cp": cp, "route": route}
	a.body_entered.connect(func(b): _enter_zone(b, z))
	if cp != "":
		checkpoints[cp] = Vector3(center.x, center.y - size.y * 0.5 + 0.2, center.z)
		structure["checkpoints"].append(cp)

func _sweeper(pos: Vector3, obstacle_id: String, amplitude: float, period_beats: float, phase: float) -> void:
	var s = _area(pos, Vector3(1.2, 1.6, 1.2), SweeperScript)
	s.obstacle_id = obstacle_id
	s.amplitude = amplitude
	s.period_beats = period_beats
	s.phase = phase
	s.stage = self
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.2, 1.6, 1.2)
	mi.mesh = bm
	mi.material_override = _mat(Color(0.85, 0.3, 0.2))
	s.add_child(mi)
	add_child(s)

func _gust(center: Vector3, size: Vector3) -> void:
	var g = _area(center, size, GustScript)
	g.push = Vector3(7.0 * _m, 0, 0)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(Color(0.8, 0.95, 1.0), 0.25)
	g.add_child(mi)
	g.mesh = mi
	add_child(g)

func _station(key: String, pos: Vector3) -> void:
	var sc: Dictionary = cfg["stations"][key]
	var st = StationScript.new()
	st.station_id = sc["id"]
	st.mode = sc["mode"]
	st.motif = sc["motif"]
	st.assist_from_start = bool(sc.get("assist_from_start", false))
	st.position = pos
	add_child(st)
	var animal := MeshInstance3D.new()
	animal.mesh = SphereMesh.new()
	animal.scale = Vector3(0.9, 0.7, 1.1)
	animal.position = Vector3(2.5, 0.35, -2.0)
	animal.material_override = _mat(sc.get("color", Color(0.55, 0.4, 0.3)))
	st.add_child(animal)
	st.cue_note.connect(func(slot, idx, kind): hud.show_note(slot, idx, kind))
	st.cue_clear.connect(func(): hud.clear_notes())
	st.completed.connect(_on_station_done.bind(key))
	st.failed_attempt.connect(_on_station_fail)
	stations[key] = st

func _x(v: Vector3) -> Vector3:
	return Vector3(v.x * _m, v.y, v.z)

func _build_course() -> void:
	var ground: Color = cfg.get("ground", Color(0.45, 0.65, 0.4))
	var perch: Color = cfg.get("perch", Color(0.6, 0.45, 0.3))
	# Hyrja + Prova 1
	_platform(Vector3(0, 0, 0), Vector2(10, 10), ground)
	_platform(Vector3(0, 0, -11), Vector2(4, 4), ground)
	_platform(Vector3(0, 1.5, -20), Vector2(4, 4), ground)
	_platform(Vector3(0, 0, -33), Vector2(4, 4), ground)
	_platform(Vector3(0, 0.5, -42), Vector2(2.5, 2.5), perch)
	_platform(Vector3(0, 0, -52), Vector2(12, 8), ground)
	# Prova 2, rruga A: purteka të larta (frenim + ulje precize)
	for p in [Vector3(-8, 2, -62), Vector3(-10, 3.5, -70), Vector3(-10, 3, -79), Vector3(-7, 2, -88)]:
		_platform(_x(p), Vector2(2.5, 2.5), perch)
	# Prova 2, rruga B: shteg i ulët me fshirëse (shmangie)
	_platform(_x(Vector3(9, 0, -76)), Vector2(4, 34), ground)
	_sweeper(_x(Vector3(9, 0.8, -66)), "fshirese_1", 2.6, 4.0, 0.0)
	_sweeper(_x(Vector3(9, 0.8, -76)), "fshirese_2", 2.6, 4.0, PI * 0.5)
	_sweeper(_x(Vector3(9, 0.8, -86)), "fshirese_3", 2.6, 2.0, 0.0)
	# Ribashkimi + Prova 3
	_platform(Vector3(0, 0, -98), Vector2(14, 10), ground)
	_platform(Vector3(0, 0, -112), Vector2(8, 8), ground)
	_station("prova3", Vector3(0, 0, -112))
	# Kulmi
	_platform(Vector3(0, 1, -122), Vector2(2.5, 2.5), perch)
	_platform(Vector3(0, 0, -131), Vector2(5, 5), ground)
	_sweeper(Vector3(0, 0.8, -131), "fshirese_kulmi", 2.0, 2.0, 0.0)
	_platform(Vector3(0, 1.5, -140), Vector2(2.5, 2.5), perch)
	_platform(Vector3(0, 0, -152), Vector2(10, 10), ground)
	_station("kulmi", Vector3(0, 0, -152))
	if bool(cfg.get("gusts", false)):
		_gust(Vector3(0, 2.5, -27), Vector3(8, 7, 8))
		_gust(Vector3(0, 2.5, -136), Vector3(8, 7, 5))
	# Pasoja nga stazhi i mëparshëm: aleati i ndihmuar ndërton një urë në kulm.
	if cfg.get("ally_bridge", "") != "" and Campaign.has_ally(cfg["ally_bridge"]):
		has_ally_bridge = true
		_platform(Vector3(0, 0.7, -136), Vector2(2.2, 2.2), Color(0.55, 0.4, 0.3))
	# Zonat: emocioni, muzika, checkpoint-et, rrugët
	_zone("z_hyrje", Vector3(0, 3, 0), Vector3(10, 6, 10), "pushim", "kureshtje", 0.0, 0.0, "start")
	_zone("z_prova1", Vector3(0, 4, -27), Vector3(8, 10, 34), "prove", "fokus", 0.5)
	_zone("z_cp1", Vector3(0, 3, -52), Vector3(12, 6, 8), "pushim", "lehtesim", 0.0, 0.0, "cp1")
	_zone("z_rrugaA", _x(Vector3(-9, 6, -75)), Vector3(8, 12, 32), "prove", "fokus", 0.7, 0.0, "", "A")
	_zone("z_rrugaB", _x(Vector3(9, 3, -76)), Vector3(4, 6, 34), "prove", "alarm", 0.8, 0.0, "", "B")
	_zone("z_cp2", Vector3(0, 3, -98), Vector3(14, 6, 10), "pushim", "lehtesim", 0.0, 0.0, "cp2")
	_zone("z_prova3", Vector3(0, 3, -112), Vector3(8, 6, 8), "prove", "butesi", 0.0, 0.6)
	_zone("z_kulmi", Vector3(0, 5, -134), Vector3(8, 12, 26), "kulm", "alarm", 1.0, 0.3)
	_zone("z_fund", Vector3(0, 3, -152), Vector3(10, 6, 10), "kulm", "butesi", 0.2, 1.0)
	checkpoints["cp3"] = Vector3(0, 0.2, -112)
	structure["checkpoints"].append("cp3")
	structure["routes"] = ["A", "B"]
	structure["rejoin"] = "cp2"
	structure["climax"] = "z_kulmi"
	structure["trials"] = ["z_prova1", "z_rrugaA|z_rrugaB", "z_prova3"]

func _spawn_player() -> void:
	player = CockatooScript.new()
	add_child(player)
	player.teleport(checkpoints["start"] + Vector3(0, 0.3, 0))
	camera = CameraScript.new()
	add_child(camera)
	camera.target = player
	camera.global_position = player.global_position + Vector3(0, 3, 6)
	camera.current = true
	hud = HudScript.new()
	add_child(hud)
	player.flapped.connect(func(_n): _learn("ngritje", "Ngritje"))
	player.glided.connect(func(): _learn("planim", "Planim"))
	player.braked.connect(func(): _learn("frenim", "Frenim"))
	player.dodged.connect(func(): _learn("shmangie", "Shmangie"))
	player.landed.connect(_on_landed)
	player.note_played.connect(_on_player_note)

## Pikat e rrugës kritike për secilën rrugë (përdoren nga provat dhe nga dokumentimi).
func waypoints(route: String) -> Array:
	var out: Array = [Vector3(0, 0, 0), Vector3(0, 0, -11), Vector3(0, 1.5, -20), Vector3(0, 0, -33), Vector3(0, 0.5, -42), Vector3(0, 0, -52)]
	if route == "A":
		for p in [Vector3(-8, 2, -62), Vector3(-10, 3.5, -70), Vector3(-10, 3, -79), Vector3(-7, 2, -88)]:
			out.append(_x(p))
	else:
		for p in [Vector3(9, 0, -61), Vector3(9, 0, -76), Vector3(9, 0, -91)]:
			out.append(_x(p))
	out.append(Vector3(0, 0, -98))
	out.append(Vector3(0, 0, -112))
	return out

func climax_waypoints() -> Array:
	return [Vector3(0, 1, -122), Vector3(0, 0, -131), Vector3(0, 1.5, -140), Vector3(0, 0, -152)]

# ---------- ngjarjet ----------

func _text(zone_id: String) -> String:
	return str(cfg.get("text", {}).get(zone_id, ""))

func _learn(skill: String, label: String) -> void:
	if Campaign.learn_skill(skill):
		hud.toast("Aftësi e re: " + label)

func _set_emotion(e: String, hold: float = 0.0) -> void:
	player.visual.set_emotion(e)
	camera.set_distance(float(CAM_DIST.get(e, 6.5)))
	_emotion_hold = hold

func _enter_zone(body: Node, z: Dictionary) -> void:
	if body != player or finished:
		return
	current_zone = z["id"]
	_zone_emotion = z["emotion"]
	_set_emotion(_zone_emotion)
	AudioDirector.set_layer("danger", z["danger"])
	AudioDirector.set_layer("coop", z["coop"])
	var t := _text(z["id"])
	if t != "":
		hud.set_prompt(t)
	if z["kind"] == "prove" or z["kind"] == "kulm":
		AudioDirector.announce("rrezik", "Ritmi shtohet: " + z["id"].trim_prefix("z_"))
	if z["cp"] != "":
		_reach_checkpoint(z["cp"])
	if z["route"] != "" and route_taken != z["route"]:
		route_taken = z["route"]
		Telemetry.route(route_taken)
	if z["id"] == "z_prova3":
		stations["prova3"].activate()
	if z["id"] == "z_fund":
		stations["kulmi"].activate()

func _reach_checkpoint(id: String) -> void:
	if CP_ORDER.find(id) > CP_ORDER.find(current_cp):
		current_cp = id
		hud.toast("Checkpoint: " + id)
		AudioDirector.announce("checkpoint", "Tingull checkpoint-i")

func _on_landed(precise: bool, _speed: float) -> void:
	if precise:
		_learn("ulje_precize", "Ulje precize")
		_set_emotion("krenari", 1.0)
		AudioDirector.announce("ulje", "Ulje e butë")
	else:
		camera.shake(0.5)
		AudioDirector.announce("ulje", "Përplasje e rëndë, rrëshqitje")

func _on_player_note(index: int) -> void:
	AudioDirector.play_note(index, "player")
	for key in stations:
		stations[key].receive_note(index)

func _on_station_fail(_id: String, reason: String) -> void:
	hud.toast("Provoje sërish: " + reason)
	_set_emotion("alarm", 0.6)

func _on_station_done(_id: String, key: String) -> void:
	_learn("fraze", "Frazë muzikore")
	AudioDirector.set_layer("coop", 1.0)
	AudioDirector.announce("pergjigje", "Kafsha përgjigjet me motivin")
	_set_emotion("butesi", 2.0)
	if key == "prova3":
		_reach_checkpoint("cp3")
	elif key == "kulmi":
		_finish()

func fail_player(obstacle: String) -> void:
	if _respawning or finished:
		return
	_respawning = true
	Telemetry.fail(obstacle)
	hud.flash_fail("Dështim: " + obstacle)
	AudioDirector.announce("deshtim", "Tingull rënieje")
	camera.shake(1.0)
	_set_emotion("alarm", 0.4)
	player.control_enabled = false
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	player.teleport(checkpoints[current_cp] + Vector3(0, 0.3, 0))
	player.external_push = Vector3.ZERO
	player.control_enabled = true
	_respawning = false
	Telemetry.retry()
	AudioDirector.set_layer("recovery", 1.0)
	AudioDirector.set_layer("danger", 0.0)
	_recovery_beats = 4
	_set_emotion("lehtesim", 1.5)

func _finish() -> void:
	if finished:
		return
	finished = true
	Telemetry.end_stage()
	var rewards: Dictionary = cfg.get("rewards", {})
	for ally in rewards.get("allies", []):
		Campaign.help_ally(ally)
	var motifs: Dictionary = rewards.get("motifs", {})
	for name_key in motifs:
		Campaign.learn_motif(name_key, motifs[name_key])
	var d: Dictionary = Telemetry.data[cfg["id"]]
	Campaign.complete_stage(cfg["id"], {"route": route_taken, "fails": Telemetry.total_fails(cfg["id"]), "duration": d["duration"], "flags": rewards.get("flags", [])})
	AudioDirector.set_layer("danger", 0.0)
	_set_emotion("krenari", 99.0)
	hud.clear_notes()
	hud.show_summary("%s\n\nRruga: %s   Dështime: %d   Koha: %d s\n%s\n\nEnter / Start: kthehu në meny" % [cfg["title"], route_taken, Telemetry.total_fails(cfg["id"]), int(d["duration"]), cfg.get("outro", "")])
	stage_finished.emit(cfg["id"])

func _on_beat(_index: int) -> void:
	if _recovery_beats > 0:
		_recovery_beats -= 1
		if _recovery_beats == 0:
			AudioDirector.set_layer("recovery", 0.0)

func _process(delta: float) -> void:
	if player == null:
		return
	hud.set_flaps(player.flaps_left, player.MAX_FLAPS)
	hud.set_layers(AudioDirector.layer_target("danger"), AudioDirector.layer_target("coop"), AudioDirector.layer_target("recovery"))
	if _emotion_hold > 0.0:
		_emotion_hold -= delta
		if _emotion_hold <= 0.0 and not finished:
			_set_emotion(_zone_emotion)
	if Input.is_action_just_pressed("back_to_menu") or (finished and Input.is_action_just_pressed("confirm")):
		if get_tree().current_scene == self:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://main.tscn")

func _physics_process(_delta: float) -> void:
	if player and not _respawning and not finished and player.global_position.y < KILL_Y:
		fail_player("rënie:" + current_zone)
