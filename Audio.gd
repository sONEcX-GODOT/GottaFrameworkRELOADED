extends Node
class_name Sound
@export var var_sound: Dictionary = {
	"punch": "sounds/Punch1.wav",
	"hit": "sounds/Hit1.wav",
	"superpunch": "sounds/SuperPunch.wav", 
	"ringD": "sounds/ringD.wav", 
	"jump_M": "sounds/jumpM.wav",
	"jumpL": "sounds/jumpL.wav", 
	"close": "sounds/close.wav", 
	"brake": "sounds/brake.wav", 
	"button_st": "sounds/start_bt.wav", 
	"OK_qte": "sounds/OK_qte_sn.wav", 
	"sonic_stepR": "sounds/sonic1.wav",
	"sonic_stepL": "sounds/sonic2.wav", 
	"boost_start": "sounds/sn_boost.wav",
	"select": "sounds/jumpS.wav",
	"jumpF": "sounds/jumpF.wav",
	"select_jump": "sounds/select.wav", 
	"jump": "sounds/sn_jump.wav",
	"stomp": "sounds/sn_stomping.wav",
	"lsd": "sounds/sn_lightdash.wav",
	"drift": "sounds/sn_drift_main.wav",
	"land": "sounds/sn_stomping_land.wav",
	"step": "sounds/sn_quickstep.wav", 
	"homing": "sounds/sn_homing.wav", 
	"hope": "sounds/44_es_jump.wav", 
	"ballon": "sounds/ballon.wav",
	"slide": "sounds/slide.wav",
	"slide_rep": "sounds/slide1.wav", 
	"spring": "sounds/spring.wav", 
	"boost_1": "sounds/Boost_Start1.wav",
	"boost_2": "sounds/Boost_Start2.wav",
	"boost_3": "sounds/Boost_Start3.wav", 
	"boost": "sounds/boost_jet.wav", 
	"ring": "sounds/ring.wav",
	"spread": "sounds/spread.wav",
	"10ring": "sounds/10ring.wav", 
	"panel": "sounds/pad.wav", 
	"fake": "sounds/fake.wav", 
	"start": "sounds/start.wav",
	"exp": "sounds/exp.wav", 
	"start_rail": "sounds/start_rail.wav", 
	"rail": "sounds/rail.wav",
	"rank": "sounds/rank.wav", 
	"result": "sounds/clear.mp3",
	"total": "sounds/resS.mp3", 
	"goal": "sounds/Goal.wav", 
	"OK": "sounds/QTE_OK.wav",
	"click": "sounds/QTE_Click.wav",
	"lose": "sounds/QTE_Lose.wav", 
	"S": "sounds/S.wav",
	"A": "sounds/A.wav",
	"B": "sounds/B.wav",
	"C": "sounds/C.wav", 
	"D": "sounds/D.wav",
	"E": "sounds/E.wav"
}
var loaded_sounds: Dictionary = {}
func _ready() -> void:
	for sound_name in var_sound:
		var path = "res://" + var_sound[sound_name]
		if ResourceLoader.exists(path):
			loaded_sounds[sound_name] = load(path)
		else:
			push_error("Sound-Datei nicht gefunden: " + path)
func play(sound_name: String) -> void:
	if not loaded_sounds.has(sound_name):
		return
	var asp = AudioStreamPlayer.new()
	asp.set_meta("sound_type", sound_name)
	var stream = loaded_sounds[sound_name].duplicate()
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	elif stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = false
	asp.stream = stream
	add_child(asp)
	asp.play()
	asp.finished.connect(func(): asp.queue_free())
func stop(sound_name: String) -> void:
	for child in get_children():
		if child is AudioStreamPlayer and child.has_meta("sound_type") and child.get_meta("sound_type") == sound_name:
			child.queue_free()
func play_loop(sound_name: String) -> void:
	if not loaded_sounds.has(sound_name):
		return
	for child in get_children():
		if child is AudioStreamPlayer and not child.is_queued_for_deletion() and child.has_meta("sound_type") and child.get_meta("sound_type") == sound_name + "_loop":
			if not child.playing:
				child.play()
			return
	var asp = AudioStreamPlayer.new()
	asp.set_meta("sound_type", sound_name + "_loop")
	var stream = loaded_sounds[sound_name].duplicate()
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		if stream.loop_end <= 0 and stream.format != AudioStreamWAV.FORMAT_IMA_ADPCM:
			var bytes_per_sample := 2 if stream.format == AudioStreamWAV.FORMAT_16_BITS else 1
			var channels := 2 if stream.stereo else 1
			stream.loop_begin = 0
			stream.loop_end = stream.data.size() / (bytes_per_sample * channels)
	elif stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	asp.stream = stream
	add_child(asp)
	asp.play()
func stop_loop(sound_name: String) -> void:
	for child in get_children():
		if child is AudioStreamPlayer and child.has_meta("sound_type") and child.get_meta("sound_type") == sound_name + "_loop":
			child.stop()
			remove_child(child)
			child.queue_free()
