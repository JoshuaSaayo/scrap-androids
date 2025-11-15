extends Control

const GRID_SIZE := 2
const TILE_SIZE := 170
const EMPTY_TILE := -3
const TILE_PATH := "res://assets/puzzle_assets/puzzle_tiles_1/tile_%d.jpg"
const SHUFFLE_MOVES := 40

@onready var grid: GridContainer = $Grid
@onready var full_image_blur: TextureRect = $FullImageBlur
@onready var message: Label = $Message
@onready var sweep_rect: TextureRect = $SweepRect
@onready var sparkles: GPUParticles2D = $BackgroundSparkles


var tiles: Array = []
var puzzle_state: Array = []


func _ready():
	_create_tiles()
	_shuffle_tiles()
	_update_grid()


func _create_tiles():
	tiles.clear()
	puzzle_state.clear()

	for tile_id in range(GRID_SIZE * GRID_SIZE - 1):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)

		var tex: Texture2D = load(TILE_PATH % (tile_id + 1))
		if tex:
			btn.icon = tex
			btn.expand_icon = true

		btn.set_meta("tile_id", tile_id)
		btn.pressed.connect(_on_tile_pressed.bind(tile_id))

		tiles.append(btn)
		puzzle_state.append(tile_id)

	puzzle_state.append(EMPTY_TILE)


func _shuffle_tiles():
	var rng := RandomNumberGenerator.new()
	var empty_idx: int

	for i in SHUFFLE_MOVES:
		empty_idx = puzzle_state.find(EMPTY_TILE)
		var neighbors := _get_adjacent_indices(empty_idx)
		var pick: int = neighbors.pick_random()

		puzzle_state[empty_idx] = puzzle_state[pick]
		puzzle_state[pick] = EMPTY_TILE


func _update_grid():
	# Clear existing children
	for child in grid.get_children():
		grid.remove_child(child)
		if not tiles.has(child):
			child.queue_free()

	# Add current state
	for tile_id in puzzle_state:
		if tile_id == EMPTY_TILE:
			var placeholder := Control.new()
			placeholder.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
			grid.add_child(placeholder)
		else:
			grid.add_child(tiles[tile_id])


func _on_tile_pressed(tile_id: int) -> void:
	var pos := puzzle_state.find(tile_id)
	var empty_pos := puzzle_state.find(EMPTY_TILE)

	if pos != -1 and _is_adjacent(pos, empty_pos):
		puzzle_state[empty_pos] = puzzle_state[pos]
		puzzle_state[pos] = EMPTY_TILE
		_update_grid()

		if _is_solved():
			_on_puzzle_solved()


func _is_adjacent(a: int, b: int) -> bool:
	var ax := a % GRID_SIZE
	var ay := a / GRID_SIZE
	var bx := b % GRID_SIZE
	var by := b / GRID_SIZE

	return (abs(ax - bx) == 1 and ay == by) or (abs(ay - by) == 1 and ax == bx)


func _get_adjacent_indices(pos: int) -> Array:
	var x := pos % GRID_SIZE
	var y := pos / GRID_SIZE
	var neighbors := []

	if x > 0: neighbors.append(pos - 1)
	if x < GRID_SIZE - 1: neighbors.append(pos + 1)
	if y > 0: neighbors.append(pos - GRID_SIZE)
	if y < GRID_SIZE - 1: neighbors.append(pos + GRID_SIZE)

	return neighbors


func _is_solved() -> bool:
	for i in GRID_SIZE * GRID_SIZE - 1:
		if puzzle_state[i] != i:
			return false
	return puzzle_state[GRID_SIZE * GRID_SIZE - 1] == EMPTY_TILE

func _finish_sweep():
	full_image_blur.visible = false  # blur gone
	sweep_rect.visible = false       # hide sweep bar

	# Stop the background sparkles after reveal
	sparkles.emitting = false

	# Small delay then move to animation scene
	get_tree().create_timer(0.5).timeout.connect(_go_to_animation_scene)
	
func _start_sweep_reveal():
	# Start with SweepRect collapsed
	sweep_rect.visible = true
	sweep_rect.size.x = 0
	sweep_rect.modulate.a = 1.0              # fully visible white bar

	full_image_blur.visible = true

	# Tween: expand SweepRect left→right
	var tween := create_tween()
	tween.tween_property(
		sweep_rect, "size:x",
		full_image_blur.size.x,
		0.8
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# After sweep finishes
	tween.finished.connect(_finish_sweep)
	
func _on_puzzle_solved():
	grid.visible = false                      # hide puzzle tiles
	message.visible = false

	sparkles.emitting = true                  # background sparkles ON
	_start_sweep_reveal()                     # begin sweep wipe


func _reveal_full_image():
	full_image_blur.visible = true

	var tween := create_tween()
	tween.parallel().tween_property(grid, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(full_image_blur, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(message, "modulate:a", 0.0, 1.0)
	
	tween.finished.connect(func(): print("Full clear image revealed!"))


func _on_solve_button_pressed() -> void:
	puzzle_state.clear()
	
	for i in GRID_SIZE * GRID_SIZE - 1:
		puzzle_state.append(i)
	puzzle_state.append(EMPTY_TILE)

	_update_grid()
	_on_puzzle_solved()

func _go_to_animation_scene():
	get_tree().change_scene_to_file("res://lewds/lewdscenes/rachel_ls.tscn")
