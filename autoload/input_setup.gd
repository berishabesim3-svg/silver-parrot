extends Node
## Harta e kontrolleve (tastierë + gamepad), e ndërtuar në kod që të jetë një burim i vetëm.

func _ready() -> void:
	_add("move_forward", [KEY_W], [], [[JOY_AXIS_LEFT_Y, -1.0]])
	_add("move_back", [KEY_S], [], [[JOY_AXIS_LEFT_Y, 1.0]])
	_add("move_left", [KEY_A], [], [[JOY_AXIS_LEFT_X, -1.0]])
	_add("move_right", [KEY_D], [], [[JOY_AXIS_LEFT_X, 1.0]])
	_add("cam_left", [KEY_Q, KEY_LEFT], [], [[JOY_AXIS_RIGHT_X, -1.0]])
	_add("cam_right", [KEY_E, KEY_RIGHT], [], [[JOY_AXIS_RIGHT_X, 1.0]])
	_add("flap", [KEY_SPACE], [JOY_BUTTON_A])
	_add("brake", [KEY_SHIFT], [JOY_BUTTON_LEFT_SHOULDER])
	_add("dodge", [KEY_C, KEY_CTRL], [JOY_BUTTON_B])
	_add("note_1", [KEY_J], [JOY_BUTTON_X])
	_add("note_2", [KEY_K], [JOY_BUTTON_Y])
	_add("note_3", [KEY_L], [JOY_BUTTON_RIGHT_SHOULDER])
	_add("confirm", [KEY_ENTER], [JOY_BUTTON_START])
	_add("back_to_menu", [KEY_ESCAPE], [JOY_BUTTON_BACK])

func _add(action: String, keys: Array, buttons: Array = [], axes: Array = []) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.3)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	for b in buttons:
		var e2 := InputEventJoypadButton.new()
		e2.button_index = b
		InputMap.action_add_event(action, e2)
	for a in axes:
		var e3 := InputEventJoypadMotion.new()
		e3.axis = a[0]
		e3.axis_value = a[1]
		InputMap.action_add_event(action, e3)
