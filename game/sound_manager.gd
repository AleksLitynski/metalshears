class_name SoundManager

extends Node

var title_bgm = preload("res://sounds/bgm/metal-gear-136567.mp3")
var main_bgm = preload("res://sounds/bgm/jazz-bossa-nova-163669-loop-version.mp3")
var cutting_bgm = preload("res://sounds/bgm/melodic-metal-186403.mp3")

var sword_sfx = preload("res://sounds/sfx/sword-sound-2-36274.mp3")

enum BGM { NONE, TITLE, MAIN, CUTTING }

var title_bgm_player = create_bgm_stream_player(title_bgm, "TitleBgmPlayer")
var main_bgm_player = create_bgm_stream_player(main_bgm, "MainBgmPlayer")
var cutting_bgm_player = create_bgm_stream_player(cutting_bgm, "CuttingBgmPlayer")
var sfx_player = create_sfx_stream_player(sword_sfx)

var current_bgm = BGM.NONE

# Called when the node enters the scene tree for the first time.
func _ready():
	play_sound_check()
	#await get_tree().create_timer(2).timeout
	#main_bgm_player.stop()
	#main_bgm_player.seek(0)
	#main_bgm_player.play(0)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Public functions

# Play or switch to a new background music
func play_bgm(bgm):
	if (bgm == BGM.NONE):
		title_bgm_player.stop()
		main_bgm_player.stop()
		cutting_bgm_player.stop()
	elif (bgm == BGM.TITLE):
		title_bgm_player.play(0)
		main_bgm_player.stop()
		cutting_bgm_player.stop()
	elif (bgm == BGM.MAIN):
		title_bgm_player.stop()
		main_bgm_player.play()
		cutting_bgm_player.stop()
	elif (bgm == BGM.CUTTING):
		title_bgm_player.stop()
		main_bgm_player.stop()
		cutting_bgm_player.play()
	else:
		print("Unknown bgm: " + bgm)

# Play sound effect
func play_sfx():
	sfx_player.play(0)

func play_sound_check():
	play_bgm(BGM.TITLE)
	await get_tree().create_timer(2).timeout
	play_bgm(BGM.MAIN)
	await get_tree().create_timer(2).timeout
	play_bgm(BGM.CUTTING)
	await get_tree().create_timer(2).timeout
	play_sfx()
	await get_tree().create_timer(1).timeout
	play_sfx()
	play_bgm(BGM.NONE)

# Internal functions

func create_bgm_stream_player(stream, name):
	var stream_player = create_audio_stream_player()
	stream_player.stream = stream
	stream.loop = true
	stream_player.name = name
	return stream_player

func create_sfx_stream_player(stream, name = "SfxStreamPlayer"):
	var stream_player = create_audio_stream_player()
	stream_player.stream = stream
	stream.loop = false
	stream_player.name = name
	return stream_player

func create_audio_stream_player():
	var audio_stream_player = AudioStreamPlayer.new()
	add_child(audio_stream_player)
	return audio_stream_player;
