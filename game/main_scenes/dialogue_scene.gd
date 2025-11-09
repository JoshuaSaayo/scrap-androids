extends Control

@onready var illust = $Illust
@onready var dialogue_label = $DialogueBox/DialogueLabel
@onready var next_button = $NextButton

# --- Exported variables for easy editing in inspector
@export var illusts: Array[Texture2D] = []
@export var puzzle_scene: String = "res://main_scenes/puzzle.tscn"

# --- Dialogue lines
var dialogues = [
	"Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
	"Vestibulum ac diam sit amet quam vehicula elementum.",
	"Curabitur arcu erat, accumsan id imperdiet et, porttitor at sem.",
	"Sed porttitor lectus nibh. Vivamus magna justo.",
	"Cras ultricies ligula sed magna dictum porta.",
	"Donec rutrum congue leo eget malesuada.",
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
		if current_line % 3 == 0: # every 3 lines, update illustration
			_update_illust()
	else:
		_go_to_puzzle()

func _update_dialogue():
	dialogue_label.text = dialogues[current_line]

func _update_illust():
	var illust_index = current_line / 3
	if illust_index < illusts.size():
		illust.texture = illusts[illust_index]

func _go_to_puzzle():
	get_tree().change_scene_to_file(puzzle_scene)
