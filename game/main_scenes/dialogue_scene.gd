extends Control

@onready var illust = $Illust
@onready var dialogue_label = $DialogueBox/DialogueLabel
@onready var character_name: Label = $DialogueBox/CharacterName
@onready var next_button = $NextButton
@onready var fade_rect: ColorRect = $FadeRect

# --- Exported variables for easy editing in inspector
@export var illusts: Array[Texture2D] = []
@export var illust_line_ranges: Array[int] = [] # new — defines when to change image
@export var puzzle_scene: String = "res://main_scenes/puzzle.tscn"

# --- Dialogue lines
var dialogues = [
	{"name": "Player", "text": "Did I just die? What the fuck just happened… Now I can’t remember my past. Just who am I?"},
	{"name": "???", "text": "You are not dead."},
	{"name": "Player", "text": "Who is that?"},
	{"name": "???", "text": "Follow this light and I will show you the next path you must step forward… Our great Voyager."},
	{"name": "Player", "text": "Huh?"},
	{"name": "Player", "text": "Wait oh shit! This is so bright I can’t see!!"},
	{"name": "Player", "text": "What the… Where am I? This place looks so cozy. Let me stroll for a while."},
	{"name": "Player", "text": "I must be dreaming and I can’t figure out my name and who am I?"},
	{"name": "Player", "text": "All I remembered was a whisper saying I am their Voyager…"},
	{"name": "Player", "text": "Huh… wait holy-"},
	{"name": "Girl in the tree", "text": "Mmm mmm yes it so good~."},
	{"name": "Player", "text": "Is she… Masturbating?"},
	{"name": "Girl in the tree", "text": " hmm? Hey you! I know you saw me here! I want you to come here."},
	{"name": "Player", "text": "Ehh.. What do you want, miss?"},
	{"name": "Girl in the tree:", "text": "aahh finally! The Voyager is here, I am bored doing only fingering my pussy."},
	{"name": "Rachel", "text": "Come here and call me Rachel and please my pussy is itchy, I need your cock~"},
]

var current_line := 0

func _ready():
	next_button.pressed.connect(_on_next_pressed)
	_update_dialogue()
	_update_illust()

func _on_next_pressed():
	current_line += 1
	if current_line < dialogues.size():
		_update_dialogue()
		_update_illust()
	else:
		_go_to_puzzle()

func _update_dialogue():
	var line = dialogues[current_line]
	dialogue_label.text = line["text"]
	character_name.text = line["name"]

func slide_illust(new_texture: Texture2D):
	var start_pos = illust.position
	var offscreen = start_pos + Vector2(-300, 0) # slide left

	var tween := create_tween()

	# slide old image out
	tween.tween_property(illust, "position", offscreen, 0.3)

	tween.tween_callback(func():
		illust.texture = new_texture
		illust.position = start_pos + Vector2(300, 0) # spawn right
	)

	# slide new image in
	tween.tween_property(illust, "position", start_pos, 0.3)

func fade_transition(new_texture: Texture2D, duration := 0.5) -> void:
	var tween = create_tween()
	
	# Fade IN (cover screen)
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration/2)
	await tween.finished
	
	# Change the image while screen is covered
	illust.texture = new_texture
	
	# Fade OUT (reveal screen)
	tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration/2)
	await tween.finished
	
func _update_illust():
	var index = 0
	for i in range(illust_line_ranges.size()):
		if current_line < illust_line_ranges[i]:
			index = i
			break
	
	# Use fade transition instead of directly setting the texture
	if illusts[index] != illust.texture:
		fade_transition(illusts[index], 0.5)

func _go_to_puzzle():
	get_tree().change_scene_to_file(puzzle_scene)
