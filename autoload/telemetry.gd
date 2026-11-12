extends Node
## Matjet: dështime sipas pengesës, koha deri te riprovimi, përdorimi i dy rrugëve
## dhe momenti kur lojtari parashikon sinjalin pa ndihmë.

const PATH := "user://telemetry.json"
var persist := true
var data := {}
var _stage := ""
var _stage_start := 0
var _fail_at := -1

func begin_stage(stage_id: String) -> void:
	_stage = stage_id
	_stage_start = Time.get_ticks_msec()
	_fail_at = -1
	data[stage_id] = {"fails": {}, "retry_times": [], "routes": {}, "anticipations": [], "duration": 0.0}

func _cur() -> Dictionary:
	if not data.has(_stage):
		begin_stage(_stage if _stage != "" else "pa_stazh")
	return data[_stage]

func stage_time() -> float:
	return (Time.get_ticks_msec() - _stage_start) / 1000.0

func fail(obstacle: String) -> void:
	var d := _cur()
	d["fails"][obstacle] = int(d["fails"].get(obstacle, 0)) + 1
	_fail_at = Time.get_ticks_msec()

func retry() -> void:
	if _fail_at < 0:
		return
	_cur()["retry_times"].append((Time.get_ticks_msec() - _fail_at) / 1000.0)
	_fail_at = -1

func route(route_id: String) -> void:
	var d := _cur()
	d["routes"][route_id] = int(d["routes"].get(route_id, 0)) + 1

func anticipated(signal_id: String) -> void:
	_cur()["anticipations"].append({"signal": signal_id, "t": stage_time()})

func end_stage() -> void:
	_cur()["duration"] = stage_time()
	save()

func total_fails(stage_id: String) -> int:
	var n := 0
	if data.has(stage_id):
		for k in data[stage_id]["fails"]:
			n += int(data[stage_id]["fails"][k])
	return n

func save() -> void:
	if not persist:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))
