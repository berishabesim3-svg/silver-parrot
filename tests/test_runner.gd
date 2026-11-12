extends Node
## Prova funksionale për rrugën kritike të çdo stazhi.
## Nisja:  godot --headless --path . res://tests/test_runner.tscn
## Kodi i daljes: 0 = të gjitha kaluan, 1 = ka dështime.

const Stage01 := preload("res://stages/stage_01.tscn")
const Stage10 := preload("res://stages/stage_10.tscn")
const StationScript := preload("res://stage/phrase_station.gd")

var _passed := 0
var _failed := 0

func _ready() -> void:
	Campaign.persist = false
	Telemetry.persist = false
	GameSettings.persist = false
	GameSettings.wide_rhythm = false
	await _test_tolerance_latch()
	await _test_structure()
	await _test_critical_path(Stage01, "1", "A", false)
	await _test_critical_path(Stage01, "1", "B", false)
	await _test_fail_and_retry()
	await _test_music_layers()
	await _test_critical_path(Stage10, "10", "A", true)
	await _test_critical_path(Stage10, "10", "B", false)
	print("\n=== REZULTATI: %d kaluan, %d dështuan ===" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  OK    ", label)
	else:
		_failed += 1
		print("  DËSHT ", label)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func _spawn(scene: PackedScene) -> Node:
	var s = scene.instantiate()
	add_child(s)
	await _frames(3)
	s.player.invulnerable_override = true
	return s

func _drop(stage) -> void:
	stage.queue_free()
	await _frames(2)

func _play_station(st) -> bool:
	st.auto_tick = false
	if st.state == "idle":
		st.activate()
	var guard := 0
	while st.state != "done" and guard < 5000:
		guard += 1
		st.tick(0.02)
		if st.ready_for_note():
			st.receive_note(st.motif[st.step])
	return st.state == "done"

func _test_tolerance_latch() -> void:
	print("PROVA: toleranca ritmike nuk ndryshon në mes të një veprimi")
	var st = StationScript.new()
	st.auto_tick = false
	st.mode = "echo"
	st.motif = [0, 1, 2]
	add_child(st)
	st.activate()
	while st.state != "response":
		st.tick(0.02)
	var latched: float = st.tol
	GameSettings.wide_rhythm = true
	st.tick(0.02)
	_check(is_equal_approx(st.tol, latched), "toleranca mbetet %.2f gjatë përgjigjes së nisur" % latched)
	_check(_play_station(st), "fraza përfundon me tolerancën e kyçur")
	var st2 = StationScript.new()
	st2.auto_tick = false
	st2.mode = "lead"
	add_child(st2)
	st2.activate()
	_check(is_equal_approx(st2.tol, GameSettings.RHYTHM_TOL_WIDE), "prova e re merr tolerancën e gjerë")
	GameSettings.wide_rhythm = false
	st.queue_free()
	st2.queue_free()

func _test_structure() -> void:
	print("PROVA: struktura e stazheve (dy rrugë, ribashkim, checkpoint-e, kulm)")
	for scene in [Stage01, Stage10]:
		Campaign.reset()
		var s = await _spawn(scene)
		var id: String = s.cfg["id"]
		_check(s.structure["routes"].size() == 2, "stazhi %s ka dy rrugë" % id)
		_check(s.structure["rejoin"] == "cp2" and s.checkpoints.has("cp2"), "stazhi %s ka pikë ribashkimi" % id)
		_check(s.structure["checkpoints"].size() >= 4, "stazhi %s ka 4 checkpoint-e" % id)
		_check(s.structure["trials"].size() == 3 and s.structure["climax"] != "", "stazhi %s ka tri prova dhe kulm" % id)
		_check(s.waypoints("A").size() == s.waypoints("B").size() + 1, "stazhi %s: rrugët kanë gjatësi të krahasueshme" % id)
		await _drop(s)

func _test_critical_path(scene: PackedScene, id: String, route: String, with_ally: bool) -> void:
	print("PROVA: rruga kritike, stazhi %s, rruga %s%s" % [id, route, " (me aleat)" if with_ally else ""])
	Campaign.reset()
	if with_ally:
		Campaign.help_ally("gjemba")
		Campaign.learn_motif("thirrja", [0, 2, 1])
		Campaign.learn_motif("pergjigjja", [1, 2, 0])
	var s = await _spawn(scene)
	for wp in s.waypoints(route):
		s.player.teleport(wp + Vector3(0, 0.6, 0))
		await _frames(6)
	_check(s.route_taken == route, "rruga e regjistruar është %s" % route)
	_check(s.current_cp == "cp2", "checkpoint-i i ribashkimit u arrit (cp2)")
	_check(_play_station(s.stations["prova3"]), "Prova 3: fraza u krye")
	_check(s.current_cp == "cp3", "checkpoint cp3 pas frazës")
	for wp in s.climax_waypoints():
		s.player.teleport(wp + Vector3(0, 0.6, 0))
		await _frames(6)
	_check(s.current_zone == "z_fund", "lojtari arriti platformën e kulmit")
	_check(_play_station(s.stations["kulmi"]), "Kulmi: fraza me kthesë u krye")
	_check(s.finished, "stazhi u mbyll")
	_check(Campaign.stage_done(id), "fushata regjistroi stazhin %s" % id)
	_check(Telemetry.data[id]["routes"].get(route, 0) == 1, "telemetria regjistroi rrugën")
	if id == "1":
		_check(Campaign.has_ally("gjemba"), "pasoja: Gjemba u regjistrua si aleate")
		_check(Campaign.get_motif("thirrja", []) == [0, 2, 1], "motivi 'thirrja' u ruajt për Stazhin 10")
	else:
		_check(s.has_ally_bridge == with_ally, "pasoja nga Stazhi 1: ura e Gjembës %s" % ("ekziston" if with_ally else "mungon"))
		_check(s.stations["kulmi"].motif.size() == 6, "kori bashkon dy motivet e Stazhit 1")
		_check(Campaign.has_ally("laguna"), "laguna u regjistrua si e zgjuar")
	await _drop(s)

func _test_fail_and_retry() -> void:
	print("PROVA: humbja është e qartë dhe rifillimi nga checkpoint është i shpejtë")
	Campaign.reset()
	var s = await _spawn(Stage01)
	for wp in s.waypoints("A").slice(0, 6):
		s.player.teleport(wp + Vector3(0, 0.6, 0))
		await _frames(6)
	_check(s.current_cp == "cp1", "cp1 u arrit")
	var t0 := Time.get_ticks_msec()
	s.player.teleport(Vector3(0, -30, -45))
	var back := false
	for i in 120:
		await get_tree().physics_frame
		if s.player.global_position.y > -1.0 and s.player.control_enabled:
			back = true
			break
	var dt := (Time.get_ticks_msec() - t0) / 1000.0
	_check(back, "lojtari u rikthye te checkpoint-i")
	_check(s.player.global_position.distance_to(s.checkpoints["cp1"]) < 2.0, "pozicioni është te cp1")
	_check(dt < 1.0, "koha deri te riprovimi %.2f s (kufiri 1.0 s)" % dt)
	_check(Telemetry.total_fails("1") == 1, "dështimi u regjistrua sipas pengesës")
	_check(Telemetry.data["1"]["retry_times"].size() == 1, "koha deri te riprovimi u regjistrua")
	await _drop(s)

func _test_music_layers() -> void:
	print("PROVA: shtresat e muzikës ndjekin rrezikun dhe ndërrohen në rrahje")
	Campaign.reset()
	var s = await _spawn(Stage01)
	s.player.teleport(Vector3(0, 0.6, -11))
	await _frames(6)
	_check(AudioDirector.layer_pending_or_target("danger") > 0.0, "zona e provës kërkon shtresën e rrezikut")
	AudioDirector.advance(AudioDirector.beat_len)
	_check(AudioDirector.layer_target("danger") > 0.0, "shtresa e rrezikut hyn në rrahjen e radhës")
	s.player.teleport(Vector3(0, 0.6, -52))
	await _frames(6)
	AudioDirector.advance(AudioDirector.beat_len)
	_check(is_zero_approx(AudioDirector.layer_target("danger")), "pushimi e ul rrezikun")
	await _drop(s)
