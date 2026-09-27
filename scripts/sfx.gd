extends Node

var samples: Dictionary = {}

func _ready() -> void:
	samples["jump"] = _make_sound(370.0, 0.085, 0.15, false)
	samples["bounce"] = _make_sound(660.0, 0.14, 0.19, false)
	samples["dash"] = _make_sound(860.0, 0.12, 0.16, false)
	samples["hit"] = _make_sound(150.0, 0.11, 0.18, true)
	samples["death"] = _make_sound(115.0, 0.26, 0.17, true)
	samples["checkpoint"] = _make_sound(520.0, 0.24, 0.14, false)
	samples["win"] = _make_sound(760.0, 0.38, 0.15, false)
	samples["telegraph"] = _make_sound(285.0, 0.28, 0.13, false)
	samples["switch"] = _make_sound(590.0, 0.22, 0.16, false)
	samples["alarm"] = _make_sound(185.0, 0.32, 0.15, true)

func play(kind: String) -> void:
	if not samples.has(kind):
		return
	var player := AudioStreamPlayer.new()
	player.stream = samples[kind]
	player.volume_db = -8.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _make_sound(frequency: float, duration: float, amplitude: float, rough: bool) -> AudioStreamWAV:
	var sample_rate := 22050
	var data := PackedByteArray()
	var count := int(duration * sample_rate)
	data.resize(count * 2)
	for i in count:
		var time := float(i) / float(sample_rate)
		var envelope := pow(1.0 - float(i) / float(count), 1.5)
		var sweep := frequency * (1.0 + (0.32 if rough else -0.2) * time / duration)
		var wave := sin(TAU * sweep * time)
		if rough:
			wave = signf(wave) * 0.68 + sin(TAU * sweep * 0.5 * time) * 0.32
		var sample := int(clampf(wave * envelope * amplitude, -1.0, 1.0) * 32767.0)
		data[i * 2] = sample & 0xff
		data[i * 2 + 1] = (sample >> 8) & 0xff
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = sample_rate
	sound.stereo = false
	sound.data = data
	return sound
