extends Control

const GRID_SIZE := 2                    # changed from 3 → 2
const TILE_SIZE := 170
const EMPTY_TILE := -3
const TILE_PATH := "res://assets/puzzle_assets/puzzle_tiles_1/tile_%d.jpg"
const SHUFFLE_MOVES := 40               # fewer moves needed for 2x2

@onready var FullImageClear: TextureRect = $FullImageClear
@onready var grid: GridContainer = $Grid
@onready var FullImageBlur: TextureRect = $FullImageBlur
@onready var message: Label = $Message

var tiles: Array = []        # tile nodes by tile_id (0..2)
var puzzle_state: Array = [] # length 4, contains tile_id or EMPTY_TILE


func _ready():
	_create_tiles()
	_shuffle_tiles()
	_update_grid()


# Create tile Button nodes and initialize solved puzzle_state
func _create_tiles():
	tiles.clear()
	puzzle_state.clear()

	# For a 2x2 grid → 3 tiles (0,1,2) + 1 empty
	for tile_id in range(GRID_SIZE * GRID_SIZE - 1): # 3 tiles
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)

		var tex: Texture2D = load(TILE_PATH % [tile_id + 1])
		if tex:
			btn.icon = tex
			btn.expand_icon = true

		btn.set_meta("tile_id", tile_id)
		btn.connect("pressed", Callable(self, "_on_tile_pressed").bind(tile_id))

		tiles.append(btn)
		puzzle_state.append(tile_id)

	# final slot = empty
	puzzle_state.append(EMPTY_TILE)


# Shuffle with random valid moves
func _shuffle_tiles():
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for i in SHUFFLE_MOVES:
		var empty_idx := puzzle_state.find(EMPTY_TILE)
		var neighbors := _get_adjacent_indices(empty_idx)

		var pick: int = neighbors[rng.randi_range(0, neighbors.size() - 1)]

		puzzle_state[empty_idx] = puzzle_state[pick]
		puzzle_state[pick] = EMPTY_TILE


# Update GridContainer to reflect puzzle_state
func _update_grid():
	for child in grid.get_children():
		grid.remove_child(child)
		if not (child in tiles):
			child.queue_free()

	for pos in range(GRID_SIZE * GRID_SIZE):
		var tile_id: int = puzzle_state[pos]

		if tile_id == EMPTY_TILE:
			var placeholder := Control.new()
			placeholder.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
			grid.add_child(placeholder)
		else:
			var tile: Button = tiles[tile_id]
			grid.add_child(tile)


func _on_tile_pressed(tile_id: int) -> void:
	var pos := puzzle_state.find(tile_id)
	if pos == -1:
		return

	var empty_pos := puzzle_state.find(EMPTY_TILE)

	if _is_adjacent(pos, empty_pos):
		puzzle_state[empty_pos] = puzzle_state[pos]
		puzzle_state[pos] = EMPTY_TILE

		_update_grid()

		if _is_solved():
			_on_puzzle_solved()


# Adjacent check for 2×2 grid
func _is_adjacent(a: int, b: int) -> bool:
	var ax := a % GRID_SIZE
	var ay := a / GRID_SIZE
	var bx := b % GRID_SIZE
	var by := b / GRID_SIZE

	return (abs(ax - bx) == 1 and ay == by) or (abs(ay - by) == 1 and ax == bx)


# Adjacent positions
func _get_adjacent_indices(pos: int) -> Array:
	var out := []

	var x := pos % GRID_SIZE
	var y := pos / GRID_SIZE

	if x > 0:
		out.append(pos - 1)
	if x < GRID_SIZE - 1:
		out.append(pos + 1)
	if y > 0:
		out.append(pos - GRID_SIZE)
	if y < GRID_SIZE - 1:
		out.append(pos + GRID_SIZE)

	return out


# Solved = tiles 0,1,2 in order + empty at index 3
func _is_solved() -> bool:
	for i in range(GRID_SIZE * GRID_SIZE - 1): # 0..2
		if puzzle_state[i] != i:
			return false

	return puzzle_state[GRID_SIZE * GRID_SIZE - 1] == EMPTY_TILE



func _reveal_full_image():
	FullImageClear.visible = true
	FullImageBlur.visible = true

	FullImageBlur.modulate = Color(1,1,1,1)
	grid.modulate = Color(1,1,1,1)

	var tween := create_tween()

	tween.parallel().tween_property(grid, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(FullImageBlur, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(message, "modulate:a", 0.0, 1.0)
	
	tween.tween_callback(func():
		print("Full clear image revealed!")
	)


func _on_puzzle_solved():
	print("Puzzle Complete!")
	_reveal_full_image()


func _on_solve_button_pressed() -> void:
	print("Solving puzzle instantly...")

	puzzle_state.clear()

	for i in range(GRID_SIZE * GRID_SIZE - 1):
		puzzle_state.append(i)

	puzzle_state.append(EMPTY_TILE)

	_update_grid()
	_on_puzzle_solved()
