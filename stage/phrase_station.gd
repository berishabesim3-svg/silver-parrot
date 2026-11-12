extends Node3D
## Frazë muzikore me kafshët.
##  - "echo": kafsha thërret motivin, lojtari e përsërit në ritëm.
##  - "lead": lojtari e nis vetë motivin nga kujtesa, kafshët përgjigjen.
## Toleranca ritmike kyçet kur nis përgjigjja dhe nuk ndryshon deri në fund të asaj prove.

signal completed(station_id: String)
signal failed_attempt(station_id: String, reason: String)
signal cue_note(slot: int, note_index: int, kind: String)
signal cue_clear

var station_id := "fraze"
var motif: Array = [0, 2, 1]
var mode := "echo"
var auto_tick := true
var assist_from_start := false

var state := "idle"   # idle, call, response, pause, done
var t := 0.0
var tol := 0.0
var step := 0
var fails := 0
var assist := false
var anticipated := false
var _calls := 0
var _prompts := 0
var _lead_t0 := -1.0
var _early_all := true
var _echo: Array = []
var _echo_t := 0.0

func _process(delta: float) -> void:
	if auto_tick:
		tick(delta)

func beat() -> float:
	return AudioDirector.beat_len

func activate() -> void:
	if state == "idle":
		_start_attempt()

func _start_attempt() -> void:
	t = 0.0
	step = 0
	_calls = 0
	_prompts = 0
	_lead_t0 = -1.0
	_early_all = true
	cue_clear.emit()
	if mode == "echo":
		state = "call"
	else:
		_begin_response()

func _begin_response() -> void:
	state = "response"
	tol = GameSettings.rhythm_tolerance()   # kyçet këtu
	assist = assist_from_start or fails >= 2
	Telemetry.retry()
	if mode == "lead" and assist:
		for i in motif.size():
			cue_note.emit(i, motif[i], "ndihme")

func expected(i: int) -> float:
	if mode == "echo":
		return (motif.size() + 1 + i) * beat()
	return _lead_t0 + i * beat()

func ready_for_note(lead: float = 0.05) -> bool:
	if state != "response":
		return false
	if mode == "lead" and _lead_t0 < 0.0:
		return true
	return t >= expected(step) - lead

func tick(dt: float) -> void:
	match state:
		"call":
			t += dt
			while _calls < motif.size() and t >= _calls * beat():
				AudioDirector.play_note(motif[_calls], "animal")
				cue_note.emit(_calls, motif[_calls], "thirrje")
				_calls += 1
			if t >= motif.size() * beat():
				_begin_response()
		"response":
			t += dt
			if mode == "echo":
				while _prompts < motif.size() and t >= expected(_prompts):
					cue_note.emit(_prompts, motif[_prompts], "tani")
					_prompts += 1
			if (mode == "echo" or _lead_t0 >= 0.0) and t > expected(step) + tol:
				_fail("vonë")
		"pause":
			t += dt
			if t >= beat():
				_start_attempt()
		"done":
			if not _echo.is_empty():
				_echo_t += dt
				if _echo_t >= beat():
					_echo_t = 0.0
					AudioDirector.play_note(_echo.pop_front(), "animal")

func receive_note(index: int) -> void:
	if state != "response":
		return
	if mode == "lead" and _lead_t0 < 0.0:
		if index != motif[0]:
			_fail("notë e gabuar")
			return
		_lead_t0 = t
		cue_note.emit(0, index, "lojtar")
		step = 1
		return
	var offset := t - expected(step)
	if step == 0 and offset < -tol:
		return   # ende pa nisur: lojtari po provon instrumentin
	if absf(offset) > tol:
		_fail("jashtë ritmit")
		return
	if index != motif[step]:
		_fail("notë e gabuar")
		return
	if offset > 0.0:
		_early_all = false
	cue_note.emit(step, index, "lojtar")
	step += 1
	if step >= motif.size():
		_succeed()

func _fail(reason: String) -> void:
	fails += 1
	Telemetry.fail("fraze:" + station_id)
	state = "pause"
	t = 0.0
	failed_attempt.emit(station_id, reason)

func _succeed() -> void:
	state = "done"
	if mode == "echo":
		anticipated = _early_all
	else:
		anticipated = not assist
		_echo = motif.duplicate()
	if anticipated:
		Telemetry.anticipated(station_id)
	completed.emit(station_id)
