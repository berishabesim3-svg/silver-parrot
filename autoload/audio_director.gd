extends Node
## Muzikë adaptive me shtresa (bazë, rrezik, bashkëpunim, rikuperim) + ora e ritmit.
## Ndryshimet e shtresave zbatohen në rrahjen e radhës, që sinjalet të bien me ngjarjet.
## Çdo ngjarje zanore ka edhe sinjal vizual përmes "cue" (HUD e shfaq si titra).

signal beat(index: int)
signal cue(kind: String, text: String)
signal note(index: int, who: String)

const BPM := 96.0
const RATE := 22050
const LOOP_BEATS := 4
const NOTE_FREQ := [440.0, 523.25, 659.25]
const LAYERS := ["base", "danger", "coop", "recovery"]

var beat_len := 60.0 / BPM
var song_time := 0.0
var beat_index := 0
var auto_clock := true
var _players := {}
var _target := {"base": 1.0, "danger": 0.0, "coop": 0.0, "recovery": 0.0}
var _current := {"base": 0.0, "danger": 0.0, "coop": 0.0, "recovery": 0.0}
var _pending := {}
var _note_streams: Array = []
var _note_players: Array = []
var _next_note_player := 0

func _ready() -> void:
	for layer in LAYERS:
		var p := AudioStreamPlayer.new()
		p.stream = _make_loop(layer)
		p.volume_db = -60.0
		add_child(p)
		_players[layer] = p
	for p2 in _players.values():
		p2.play()
	for f in NOTE_FREQ:
		_note_streams.append(_make_pluck(f))
	for i in 4:
		var np := AudioStreamPlayer.new()
		add_child(np)
		_note_players.append(np)

func _process(delta: float) -> void:
	if auto_clock:
		advance(delta)
	for layer in LAYERS:
		_current[layer] = move_toward(_current[layer], _target[layer], delta * 1.5)
		_players[layer].volume_db = linear_to_db(maxf(_current[layer], 0.001))

## Ecën orën e ritmit. Provat e thërrasin drejtpërdrejt për kohë të përcaktuar.
func advance(dt: float) -> void:
	song_time += dt
	while song_time >= (beat_index + 1) * beat_len:
		beat_index += 1
		for k in _pending:
			_target[k] = _pending[k]
		_pending.clear()
		beat.emit(beat_index)

func set_layer(layer: String, value: float) -> void:
	_pending[layer] = clampf(value, 0.0, 1.0)

func layer_target(layer: String) -> float:
	return float(_target[layer])

func layer_pending_or_target(layer: String) -> float:
	return float(_pending.get(layer, _target[layer]))

func play_note(index: int, who: String) -> void:
	var p: AudioStreamPlayer = _note_players[_next_note_player]
	_next_note_player = (_next_note_player + 1) % _note_players.size()
	p.stream = _note_streams[index % _note_streams.size()]
	p.pitch_scale = 1.0 if who == "player" else 0.5
	p.play()
	note.emit(index, who)

func announce(kind: String, text: String) -> void:
	cue.emit(kind, text)

func _make_wav(samples: PackedFloat32Array, looped: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	if looped:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav

func _make_loop(kind: String) -> AudioStreamWAV:
	var total := int(RATE * beat_len * LOOP_BEATS)
	var s := PackedFloat32Array()
	s.resize(total)
	var arp := [440.0, 523.25, 659.25, 523.25]
	for n in total:
		var t := float(n) / RATE
		var v := 0.0
		match kind:
			"base":
				var bp := fmod(t, beat_len) / beat_len
				v = 0.22 * sin(TAU * 110.0 * t) + 0.25 * exp(-6.0 * bp) * sin(TAU * 220.0 * t)
			"danger":
				var hp := fmod(t, beat_len * 0.5) / (beat_len * 0.5)
				v = 0.4 * exp(-8.0 * hp) * sin(TAU * 82.5 * fmod(t, beat_len * 0.5))
			"coop":
				var half := beat_len * 0.5
				var idx := int(t / half) % arp.size()
				var tt := fmod(t, half)
				v = 0.2 * exp(-5.0 * tt / half) * sin(TAU * float(arp[idx]) * tt)
			"recovery":
				var swell := 0.5 - 0.5 * cos(TAU * t / (beat_len * LOOP_BEATS))
				v = 0.14 * swell * (sin(TAU * 330.0 * t) + sin(TAU * 496.0 * t))
		s[n] = v
	return _make_wav(s, true)

func _make_pluck(freq: float) -> AudioStreamWAV:
	var total := int(RATE * 0.6)
	var s := PackedFloat32Array()
	s.resize(total)
	for n in total:
		var t := float(n) / RATE
		s[n] = exp(-6.0 * t) * 0.5 * (sin(TAU * freq * t) + 0.3 * sin(TAU * 2.0 * freq * t))
	return _make_wav(s, false)
