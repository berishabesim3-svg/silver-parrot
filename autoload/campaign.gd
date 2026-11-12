extends Node
## Gjendja e fushatës: aftësitë e mësuara, aleatët e ndihmuar, motivet dhe stazhet e kryera.

const PATH := "user://campaign.json"
var persist := true
var skills := {}
var allies := {}
var motifs := {}
var stages := {}

func _ready() -> void:
	load_state()

func reset() -> void:
	skills = {}
	allies = {}
	motifs = {}
	stages = {}
	save_state()

func learn_skill(skill: String) -> bool:
	if skills.has(skill):
		return false
	skills[skill] = true
	save_state()
	return true

func help_ally(ally: String) -> void:
	allies[ally] = true
	save_state()

func has_ally(ally: String) -> bool:
	return allies.has(ally)

func learn_motif(motif_name: String, notes: Array) -> void:
	motifs[motif_name] = notes.duplicate()
	save_state()

func get_motif(motif_name: String, fallback: Array) -> Array:
	if motifs.has(motif_name):
		var out: Array = []
		for n in motifs[motif_name]:
			out.append(int(n))
		return out
	return fallback.duplicate()

func complete_stage(stage_id: String, info: Dictionary) -> void:
	stages[stage_id] = info
	save_state()

func stage_done(stage_id: String) -> bool:
	return stages.has(stage_id)

func save_state() -> void:
	if not persist:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"skills": skills, "allies": allies, "motifs": motifs, "stages": stages}))

func load_state() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) == TYPE_DICTIONARY:
		skills = d.get("skills", {})
		allies = d.get("allies", {})
		motifs = d.get("motifs", {})
		stages = d.get("stages", {})
