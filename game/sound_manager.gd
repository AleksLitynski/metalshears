class_name SoundManager

extends Node
# TODO: add crossfades when switching bgm https://www.gdquest.com/tutorial/godot/audio/background-music-transition/
# TODO: support different sfx based on situation and cycle through a few of them for variety.
# TODO: use Godot's audio busses to adjust volumes overall and add effects.

enum BGM { NONE, TITLE, MAIN, CUTTING }

@onready var title_bgm_player = $TitleBgmPlayer as AudioStreamPlayer
@onready var main_bgm_player = $MainBgmPlayer as AudioStreamPlayer
@onready var cutting_bgm_player = $CuttingBgmPlayer as AudioStreamPlayer
@onready var sfx_player = $SfxPlayer as AudioStreamPlayer

var current_bgm = BGM.NONE

# Called when the node enters the scene tree for the first time.
func _ready():
	play_sound_check()
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

# Internal functions

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
