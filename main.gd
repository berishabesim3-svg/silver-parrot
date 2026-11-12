extends Control
## Menyja kryesore: zgjedhja e stazhit, opsionet e aksesueshmërisë, gjendja e fushatës.

var _status: Label

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.position = Vector2(80, 60)
	box.custom_minimum_size = Vector2(520, 0)
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	var title := Label.new()
	title.text = "SILVER PARROT"
	title.add_theme_font_size_override("font_size", 48)
	box.add_child(title)
	var b1 := _button(box, "Stazhi 1 - Jehona e Parë")
	b1.pressed.connect(func(): get_tree().change_scene_to_file("res://stages/stage_01.tscn"))
	var b10 := _button(box, "Stazhi 10 - Kori i Lagunës")
	b10.pressed.connect(func(): get_tree().change_scene_to_file("res://stages/stage_10.tscn"))
	_toggle(box, "Redukto lëkundjen e kamerës", GameSettings.reduce_shake, _set_opt.bind("reduce_shake"))
	_toggle(box, "Redukto flash-et", GameSettings.reduce_flash, _set_opt.bind("reduce_flash"))
	_toggle(box, "Tolerancë më e gjerë ritmike", GameSettings.wide_rhythm, _set_opt.bind("wide_rhythm"))
	var reset := _button(box, "Rifillo fushatën")
	reset.pressed.connect(_on_reset)
	_status = Label.new()
	box.add_child(_status)
	var help := Label.new()
	help.text = "Lëvizje WASD / leva e majtë   Kamera Q-E, miu / leva e djathtë\nNgritje + planim Space / A   Frenim Shift / LB   Shmangie C / B\nNota J K L / X Y RB   Meny Esc / Back"
	box.add_child(help)
	b1.grab_focus()
	_refresh()

func _button(parent: Node, text: String) -> Button:
	var b := Button.new()
	b.text = text
	parent.add_child(b)
	return b

func _toggle(parent: Node, text: String, value: bool, on_change: Callable) -> void:
	var c := CheckButton.new()
	c.text = text
	c.button_pressed = value
	c.toggled.connect(on_change)
	parent.add_child(c)

func _refresh() -> void:
	_status.text = "Fushata  stazhe: %s   aleatë: %s   aftësi: %s" % [str(Campaign.stages.keys()), str(Campaign.allies.keys()), str(Campaign.skills.keys())]

func _set_opt(value: bool, key: String) -> void:
	GameSettings.set(key, value)
	GameSettings.save_settings()

func _on_reset() -> void:
	Campaign.reset()
	_refresh()
