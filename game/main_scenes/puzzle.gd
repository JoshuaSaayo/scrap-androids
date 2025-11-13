extends Control

const GRID_SIZE := 3
const TILE_SIZE := 170
const EMPTY_TILE := -3
const TILE_PATH := "res://assets/puzzle_assets/puzzle_tiles_1/tile_%d.jpg"
const SHUFFLE_MOVES := 100

@onready var FullImageClear: TextureRect = $FullImageClear
@onready var grid: GridContainer = $Grid
@onready var FullImageBlur: TextureRect = $FullImageBlur


var tiles: Array = []        # tile nodes by tile_id (0..8)
var puzzle_state: Array = [] # length 9, contains tile_id or EMPTY_TILE

func _ready():
	_create_tiles()
	_shuffle_tiles()
	_update_grid()

# Create tile Button nodes and initialize solved puzzle_state
func _create_tiles():
	tiles.clear()
	puzzle_state.clear()
	
	# Create GRID_SIZE * GRID_SIZE - 1 tile Button nodes (tile ids 0..7 for 3x3 grid)
	for tile_id in range(GRID_SIZE * GRID_SIZE - 1):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
		# set the tile image as the button's icon (Texture2D)
		var tex: Texture2D = load(TILE_PATH % [tile_id + 1])
		if tex:
			btn.icon = tex
			btn.expand_icon = true
		# store the tile id on the button and connect pressed
		btn.set_meta("tile_id", tile_id)
		btn.connect("pressed", Callable(self, "_on_tile_pressed").bind(tile_id))
		tiles.append(btn)
		puzzle_state.append(tile_id)
	# last cell is empty
	puzzle_state.append(EMPTY_TILE)

# Shuffle by doing many random valid moves from solved state -> always solvable
func _shuffle_tiles():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in SHUFFLE_MOVES:
		var empty_idx := puzzle_state.find(EMPTY_TILE)
		var neighbors := _get_adjacent_indices(empty_idx)
		var pick: int = neighbors[rng.randi_range(0, neighbors.size() - 1)]
		# swap neighbor into empty
		puzzle_state[empty_idx] = puzzle_state[pick]
		puzzle_state[pick] = EMPTY_TILE

# Update GridContainer children to match puzzle_state order
func _update_grid():
	# Remove all children from grid
	for child in grid.get_children():
		grid.remove_child(child)
		if not (child in tiles):
			child.queue_free()

	# Recreate grid layout based on puzzle_state
	for pos in range(GRID_SIZE * GRID_SIZE):
		var tile_id: int = puzzle_state[pos]
		if tile_id == EMPTY_TILE:
			# Create empty placeholder
			var placeholder := Control.new()
			placeholder.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
			grid.add_child(placeholder)
		else:
			# Add the actual tile button
			var tile: Button = tiles[tile_id]
			grid.add_child(tile)

# When a tile (tile_id) is pressed
func _on_tile_pressed(tile_id: int) -> void:
	# find current position of this tile (0..8)
	var pos := puzzle_state.find(tile_id)
	if pos == -1:
		return # should not happen
	var empty_pos := puzzle_state.find(EMPTY_TILE)
	if _is_adjacent(pos, empty_pos):
		# swap into empty
		puzzle_state[empty_pos] = puzzle_state[pos]
		puzzle_state[pos] = EMPTY_TILE
		_update_grid()
		if _is_solved():
			_on_puzzle_solved()

# Return true if positions a and b are adjacent on the 3x3 grid
func _is_adjacent(a: int, b: int) -> bool:
	var ax := a % GRID_SIZE
	var ay := a / GRID_SIZE
	var bx := b % GRID_SIZE
	var by := b / GRID_SIZE
	return (abs(ax - bx) == 1 and ay == by) or (abs(ay - by) == 1 and ax == bx)

# Utility: get neighbor indices (up/down/left/right) for a given position index
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

# Check finished state (tiles 0..7 in order and last is empty)
func _is_solved() -> bool:
	for i in range(GRID_SIZE * GRID_SIZE - 1):
		if puzzle_state[i] != i:
			return false
	return puzzle_state[GRID_SIZE * GRID_SIZE - 1] == EMPTY_TILE

func _reveal_full_image():
	FullImageClear.visible = true
	FullImageBlur.visible = true

	FullImageBlur.modulate = Color(1,1,1,1)
	grid.modulate = Color(1,1,1,1)

	var tween := create_tween()

	# fade out puzzle grid
	tween.parallel().tween_property(grid, "modulate:a", 0.0, 1.0)

	# fade out blurred overlay
	tween.parallel().tween_property(FullImageBlur, "modulate:a", 0.0, 1.0)

	# optional: callback after reveal
	tween.tween_callback(func():
		print("Full clear image revealed!")
	)

func _on_puzzle_solved():
	print("Puzzle Complete!")
	_reveal_full_image()


func _on_solve_button_pressed() -> void:
	print("Solving puzzle instantly for testing...")
	puzzle_state.clear()

	# Fill puzzle_state in correct order
	for i in range(GRID_SIZE * GRID_SIZE - 1):
		puzzle_state.append(i)
	puzzle_state.append(EMPTY_TILE)  # last slot empty

	_update_grid()
	_on_puzzle_solved()  # directly trigger reveal
