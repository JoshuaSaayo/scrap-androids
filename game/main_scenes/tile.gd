extends Button

@export var tile_index: int
@onready var tex_rect = $TextureRect

func set_image(texture: Texture2D):
	tex_rect.texture = texture
