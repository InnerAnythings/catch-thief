extends Node2D

# 1. REFERENCING THE SPRITES
# We need to tell the script where our sprite nodes are.
@onready var mouth_sprite: Sprite2D = $Character/Mouth
@onready var eyes_sprite: Sprite2D = $Character/Eyes
@onready var brows_sprite: Sprite2D = $Character/Brows

# 2. DEFINING THE ASSETS
# We create empty arrays that we will fill inside the Godot Editor.
@export var mouth_textures: Array[Texture2D]
@export var eyes_textures: Array[Texture2D]
@export var brows_textures: Array[Texture2D]

# 3. TRACKING CURRENT SELECTION
# These numbers track which item in the array we are currently showing.
var current_mouth_index: int = 0
var current_eyes_index: int = 0
var current_brows_index: int = 0

func _ready() -> void:
	# Start by loading the first option for every part
	update_character_visuals()

# This function applies the textures based on the current index numbers
func update_character_visuals() -> void:
	# Check if the array has items, then set the texture
	if mouth_textures.size() > 0:
		mouth_sprite.texture = mouth_textures[current_mouth_index]
	
	if eyes_textures.size() > 0:
		eyes_sprite.texture = eyes_textures[current_eyes_index]
		
	if brows_textures.size() > 0:
		brows_sprite.texture = brows_textures[current_brows_index]

# --- BUTTON FUNCTIONS ---

func _on_btn_eyes_pressed() -> void:
	# Move to the next number
	current_eyes_index += 1
	# If we go past the last item, go back to 0 (Loop)
	if current_eyes_index >= eyes_textures.size():
		current_eyes_index = 0
	update_character_visuals()

func _on_btn_brows_pressed() -> void:
	current_brows_index += 1
	if current_brows_index >= brows_textures.size():
		current_brows_index = 0
	update_character_visuals()

func _on_btn_mouth_pressed() -> void:
	current_mouth_index += 1
	if current_mouth_index >= mouth_textures.size():
		current_mouth_index = 0
	update_character_visuals()