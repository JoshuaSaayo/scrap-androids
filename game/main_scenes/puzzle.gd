extends Control

const GRID_SIZE := 2
const TILE_SIZE := 342
const EMPTY_TILE := -3
const TILE_PATH := "res://assets/puzzle_assets/puzzle_tiles_1/tile_%d.jpg"
const SHUFFLE_MOVES := 40

@onready var grid: GridContainer = $Grid
@onready var full_image_blur: TextureRect = $FullImageBlur
@onready var sweep_rect: TextureRect = $SweepRect
@onready var sparkles: GPUParticles2D = $BackgroundSparkles
@onready var sweep_trail: GPUParticles2D = $SweepTrails
@onready var slide_sparks: GPUParticles2D = $SlideSparks
@onready var animation_container: Node2D = $rachel_ls

var tiles: Array = []
var puzzle_state: Array = []
var is_animating := false
var puzzle_solved := false  # Track if puzzle is already solved
var animation_player: AnimationPlayer


func _ready():
	_create_tiles()
	_shuffle_tiles()
	_update_grid()
	slide_sparks.emitting = false
	
	# Hide animation container initially and find the AnimationPlayer
	animation_container.visible = false
	_find_animation_player()


func _find_animation_player():
	# Look for AnimationPlayer in the animation_container
	animation_player = _find_animation_player_recursive(animation_container)
	if animation_player:
		print("Found AnimationPlayer: ", animation_player.name)
	else:
		print("No AnimationPlayer found in animation_container")


func _find_animation_player_recursive(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_animation_player_recursive(child)
		if result:
			return result
	
	return null


func _create_tiles():
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
	
	for i in SHUFFLE_MOVES:
		var empty_idx := puzzle_state.find(EMPTY_TILE)
		var neighbors := _get_adjacent_indices(empty_idx)
		var pick: int = neighbors.pick_random()
		
		puzzle_state[empty_idx] = puzzle_state[pick]
		puzzle_state[pick] = EMPTY_TILE


func _update_grid():
	for child in grid.get_children():
		grid.remove_child(child)
		if not tiles.has(child):
			child.queue_free()
	
	for tile_id in puzzle_state:
		if tile_id == EMPTY_TILE:
			var placeholder := Control.new()
			placeholder.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
			grid.add_child(placeholder)
		else:
			grid.add_child(tiles[tile_id])


func _on_tile_pressed(tile_id: int) -> void:
	if is_animating or puzzle_solved:
		return
	
	var pos := puzzle_state.find(tile_id)
	var empty_pos := puzzle_state.find(EMPTY_TILE)
	
	if pos != -1 and _is_adjacent(pos, empty_pos):
		is_animating = true
		var pressed_button: Button = tiles[tile_id]
		
		# Calculate movement
		var from_pos := Vector2(pos % GRID_SIZE, pos / GRID_SIZE)
		var to_pos := Vector2(empty_pos % GRID_SIZE, empty_pos / GRID_SIZE)
		var direction := to_pos - from_pos
		
		# Swap positions
		puzzle_state[empty_pos] = puzzle_state[pos]
		puzzle_state[pos] = EMPTY_TILE
		
		_animate_tile_move(pressed_button, direction)


func _animate_tile_move(tile: Button, direction: Vector2) -> void:
	var move_distance := Vector2(direction.x * TILE_SIZE, direction.y * TILE_SIZE)
	var initial_position := tile.position
	
	# Setup sparks
	slide_sparks.global_position = tile.global_position + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	slide_sparks.process_material.direction = Vector3(-direction.x, -direction.y, 0)
	slide_sparks.emitting = true
	
	# Animate movement
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(tile, "position", initial_position + move_distance, 0.3)
	tween.parallel().tween_method(_update_sparks_position.bind(tile), 0.0, 1.0, 0.3)
	
	tween.finished.connect(func():
		slide_sparks.emitting = false
		_update_grid()
		tile.position = initial_position
		is_animating = false
		
		if _is_solved():
			puzzle_solved = true
			_on_puzzle_solved()
	)


func _update_sparks_position(progress: float, moving_tile: Button) -> void:
	if slide_sparks.emitting:
		slide_sparks.global_position = moving_tile.global_position + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)


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
	for i in range(GRID_SIZE * GRID_SIZE - 1):
		if puzzle_state[i] != i:
			return false
	return puzzle_state[GRID_SIZE * GRID_SIZE - 1] == EMPTY_TILE


func _on_puzzle_solved():
	sparkles.emitting = true
	
	var tween := create_tween()
	tween.tween_property(grid, "modulate:a", 0.0, 0.6)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.finished.connect(func():
		grid.visible = false
		_start_sweep_reveal()
	)


func _start_sweep_reveal():
	full_image_blur.visible = true
	sweep_rect.visible = true
	sweep_rect.size.x = 0
	sweep_rect.modulate.a = 1.0
	sweep_trail.emitting = true

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(sweep_rect, "size:x", full_image_blur.size.x, 1.0)
	tween.parallel().tween_method(
		func(value): sweep_trail.position.x = sweep_rect.position.x + value,
		0.0, full_image_blur.size.x, 1.0
	)
	
	tween.finished.connect(_transition_to_animation)


func _transition_to_animation():
	# Show the animation container
	animation_container.visible = true
	animation_container.modulate.a = 0.0
	
	var transition_tween = create_tween()
	transition_tween.set_trans(Tween.TRANS_SINE)
	transition_tween.set_ease(Tween.EASE_OUT)
	
	# Extend sweep to full screen
	transition_tween.parallel().tween_property(sweep_rect, "size", get_viewport().get_visible_rect().size, 1.0)
	transition_tween.parallel().tween_property(sweep_rect, "position", Vector2.ZERO, 1.0)
	
	# Move fairy dust
	transition_tween.parallel().tween_method(
		func(value): sweep_trail.position.x = value,
		sweep_trail.position.x, get_viewport().get_visible_rect().size.x, 1.0
	)
	
	# Fade in animation, fade out blur
	transition_tween.parallel().tween_property(animation_container, "modulate:a", 1.0, 1.0)
	transition_tween.parallel().tween_property(full_image_blur, "modulate:a", 0.0, 0.6)
	
	transition_tween.finished.connect(_cleanup_puzzle_elements)
	
	# Play the animation
	_play_animation()

func _play_animation():
	if animation_player:
		print("Playing LS animation")
		if animation_player.has_animation("lewdscene"):
			animation_player.play("lewdscene")
		else:
			print("ERROR: LS animation not found in AnimationPlayer")
	else:
		print("No AnimationPlayer found")

func _cleanup_puzzle_elements():
	sweep_trail.emitting = false
	sparkles.emitting = false
	sweep_rect.visible = false
	full_image_blur.visible = false


func _on_solve_button_pressed() -> void:
	if is_animating or puzzle_solved:
		return
	
	puzzle_solved = true
	puzzle_state.clear()
	for i in range(GRID_SIZE * GRID_SIZE - 1):
		puzzle_state.append(i)
	puzzle_state.append(EMPTY_TILE)
	
	_update_grid()
	_on_puzzle_solved()
