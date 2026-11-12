extends CanvasLayer
## HUD: udhëzime, titra për çdo ngjarje zanore, ikonat e notave, pulsi i rrahjes,
## shtresat e muzikës dhe sinjali i dështimit (pa flash kur është zgjedhur reduktimi).

const NOTE_SHAPES := ["●", "▲", "■"]
const NOTE_KEYS := ["J / X", "K / Y", "L / RB"]
const NOTE_COLORS := [Color(0.35, 0.7, 1.0), Color(1.0, 0.85, 0.2), Color(1.0, 0.45, 0.4)]

var _root: Control
var _prompt: Label
var _caption: Label
var _flaps: Label
var _layers: Label
var _toast: Label
var _beat: ColorRect
var _flash: ColorRect
var _slots: Array = []
var _summary: Label
var _toast_t := 0.0
var _caption_t := 0.0

func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(1, 0.3, 0.2, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash)
	_prompt = _label(Vector2(40, 24), 26)
	_layers = _label(Vector2(40, 64), 16)
	_toast = _label(Vector2(40, 100), 22)
	_toast.modulate = Color(0.6, 1.0, 0.6)
	_caption = _label(Vector2(40, 600), 20)
	_flaps = _label(Vector2(40, 640), 22)
	_beat = ColorRect.new()
	_beat.position = Vector2(1200, 30)
	_beat.size = Vector2(28, 28)
	_beat.color = Color(1, 1, 1, 0.3)
	_root.add_child(_beat)
	for i in 6:
		var l := _label(Vector2(420 + i * 80, 520), 44)
		l.text = ""
		_slots.append(l)
	_summary = _label(Vector2(300, 200), 26)
	_summary.visible = false
	var legend := _label(Vector2(820, 640), 16)
	legend.text = "● J/X   ▲ K/Y   ■ L/RB"
	AudioDirector.beat.connect(_on_beat)
	AudioDirector.cue.connect(_on_cue)

func _label(pos: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	_root.add_child(l)
	return l

func set_prompt(text: String) -> void:
	_prompt.text = text

func caption(text: String) -> void:
	_caption.text = "[tingull] " + text
	_caption_t = 3.0

func toast(text: String) -> void:
	_toast.text = text
	_toast_t = 2.5

func set_flaps(n: int, max_n: int) -> void:
	var s := "Krahë: "
	for i in max_n:
		s += "◆" if i < n else "◇"
	_flaps.text = s

func set_layers(danger: float, coop: float, recovery: float) -> void:
	_layers.text = "Muzika  rrezik %d%%  bashkëpunim %d%%  rikuperim %d%%" % [int(danger * 100), int(coop * 100), int(recovery * 100)]

func show_note(slot: int, note_index: int, kind: String) -> void:
	if slot < 0 or slot >= _slots.size():
		return
	var l: Label = _slots[slot]
	l.text = NOTE_SHAPES[note_index % 3]
	var c: Color = NOTE_COLORS[note_index % 3]
	match kind:
		"thirrje":
			l.modulate = Color(c.r, c.g, c.b, 0.6)
		"ndihme":
			l.modulate = Color(c.r, c.g, c.b, 0.45)
		"tani":
			l.modulate = c
		_:
			l.modulate = Color(0.6, 1.0, 0.6)

func clear_notes() -> void:
	for l in _slots:
		l.text = ""

func flash_fail(text: String) -> void:
	toast(text)
	if not GameSettings.reduce_flash:
		_flash.color.a = 0.35

func show_summary(text: String) -> void:
	_summary.text = text
	_summary.visible = true

func _on_beat(_index: int) -> void:
	_beat.color.a = 1.0

func _process(delta: float) -> void:
	_beat.color.a = move_toward(_beat.color.a, 0.3, delta * 3.0)
	_flash.color.a = move_toward(_flash.color.a, 0.0, delta * 1.2)
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0:
			_toast.text = ""
	if _caption_t > 0.0:
		_caption_t -= delta
		if _caption_t <= 0.0:
			_caption.text = ""

func _on_cue(_kind: String, text: String) -> void:
	caption(text)
