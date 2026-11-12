extends Node
## Opsionet e aksesueshmërisë. Vlerat lexohen vetëm në fillim të një veprimi
## (shih phrase_station.gd: toleranca "kyçet" kur nis përgjigjja).

const PATH := "user://settings.json"
const RHYTHM_TOL := 0.22
const RHYTHM_TOL_WIDE := 0.42

var reduce_shake := false
var reduce_flash := false
var wide_rhythm := false
var persist := true

func _ready() -> void:
	load_settings()

func rhythm_tolerance() -> float:
	return RHYTHM_TOL_WIDE if wide_rhythm else RHYTHM_TOL

func save_settings() -> void:
	if not persist:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"reduce_shake": reduce_shake, "reduce_flash": reduce_flash, "wide_rhythm": wide_rhythm}))

func load_settings() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) == TYPE_DICTIONARY:
		reduce_shake = bool(d.get("reduce_shake", false))
		reduce_flash = bool(d.get("reduce_flash", false))
		wide_rhythm = bool(d.get("wide_rhythm", false))
