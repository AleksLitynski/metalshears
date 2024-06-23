class_name SoundManager

extends Node
# TODO: support different sfx based on situation and cycle through a few of them for variety.

enum BGM { NONE, TITLE, MAIN, CUTTING }
enum SFX { CLEAN_CUT, BLOODY_CUT, VERY_BLOODY_CUT, MISS_CUT }

var clean_cut_sfx = preload("res://sounds/sfx/sword-sound-2-36274.mp3")
var bloody_cut_sfx = preload("res://sounds/sfx/tomato-squishwet-103934.mp3")
var very_bloody_cut_sfx = preload("res://sounds/sfx/breeze-of-blood-122253.mp3")
var miss_cut_sfx = preload("res://sounds/sfx/sword-swipes-7174-1.mp3")

@onready var title_bgm_player = $TitleBgmPlayer as AudioStreamPlayer
@onready var main_bgm_player = $MainBgmPlayer as AudioStreamPlayer
@onready var cutting_bgm_player = $CuttingBgmPlayer as AudioStreamPlayer
@onready var sfx_player = $SfxPlayer as AudioStreamPlayer
@onready var animation_player = $AnimationPlayer as AnimationPlayer

var current_bgm = BGM.NONE

# Called when the node enters the scene tree for the first time.
func _ready():
	# Uncomment and run scene to perform sound check.
	# play_sound_check()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

# Public functions

# Play or switch to a new background music
# set crossfade_speed to higher values if engine time is adusted.
func play_bgm(bgm, crossfade_speed = 1):
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
		animation_player.play("CrossfadeCuttingToMain", -1, crossfade_speed)
	elif (bgm == BGM.CUTTING):
		title_bgm_player.stop()
		animation_player.play("CrossfadeMainToCutting", -1, crossfade_speed)
	else:
		print("Unknown bgm: " + bgm)
	
	current_bgm = bgm

# Play sound effect

func play_sfx(sfx):
	sfx_player.stop()
	if (sfx == SFX.CLEAN_CUT):
		sfx_player.stream = clean_cut_sfx
	elif (sfx == SFX.BLOODY_CUT):
		sfx_player.stream = bloody_cut_sfx
	elif (sfx == SFX.VERY_BLOODY_CUT):
		sfx_player.stream = very_bloody_cut_sfx
	elif (sfx == SFX.MISS_CUT):
		sfx_player.stream = miss_cut_sfx
	else:
		print("Unknown sfx: " + sfx)
	
	sfx_player.play(0)

# Internal functions

func play_sound_check():
	play_bgm(BGM.TITLE)
	await get_tree().create_timer(5).timeout
	play_bgm(BGM.MAIN)
	await get_tree().create_timer(5).timeout
	play_bgm(BGM.CUTTING)
	await get_tree().create_timer(5).timeout
	play_sfx(SFX.CLEAN_CUT)
	await get_tree().create_timer(1).timeout
	play_sfx(SFX.BLOODY_CUT)
	play_bgm(BGM.MAIN)
	await get_tree().create_timer(5).timeout
	play_bgm(BGM.NONE)
