extends Node2D

# 1. REFERENCING THE SPRITES
# We need to tell the script where our sprite nodes are.
@onready var p_mouth: Sprite2D = $Character/Mouth
@onready var p_eyes: Sprite2D = $Character/Eyes
@onready var p_brows: Sprite2D = $Character/Brows

# Target (Secret) Sprites
@onready var t_mouth: Sprite2D = $TargetCharacter/Mouth
@onready var t_eyes: Sprite2D = $TargetCharacter/Eyes
@onready var t_brows: Sprite2D = $TargetCharacter/Brows

# 2. DEFINING THE ASSETS
# We create empty arrays that we will fill inside the Godot Editor.
@export var mouth_textures: Array[Texture2D]
@export var eyes_textures: Array[Texture2D]
@export var brows_textures: Array[Texture2D]

# UI Nodes
@onready var label_score: Label = $CanvasLayer/LabelScore
@onready var label_attempts: Label = $CanvasLayer/LabelAttempts
@onready var label_game_over: Label = $CanvasLayer/LabelGameOver
# 3. TRACKING CURRENT SELECTION
# These numbers track which item in the array we are currently showing.
# Player Selections
var p_mouth_idx: int = 0
var p_eyes_idx: int = 0
var p_brows_idx: int = 0

# Target (Secret) Selections
var t_mouth_idx: int = 0
var t_eyes_idx: int = 0
var t_brows_idx: int = 0

# Game State
var attempts_left: int = 8
var is_game_over: bool = false

func _ready() -> void:
	# Initialize the Random Number Generator
	randomize()
	start_new_game()

func start_new_game() -> void:
	is_game_over = false
	attempts_left = 8
	label_game_over.text = "Game Over!"
	label_game_over.visible = false
	update_ui_labels(0) # 0 score initially
	
	# 1. Pick Random Indexes for the Target
	# The '%' symbol ensures the number is within the array size (0 to Size-1)
	if mouth_textures.size() > 0: t_mouth_idx = randi() % mouth_textures.size()
	if eyes_textures.size() > 0: t_eyes_idx = randi() % eyes_textures.size()
	if brows_textures.size() > 0: t_brows_idx = randi() % brows_textures.size()
	
	# 2. Update the Visuals for both characters
	# We hide the target visually (make it black) until the end
	$TargetCharacter.modulate = Color.BLACK 
	update_target_visuals()
	update_player_visuals()

# --- VISUAL UPDATES ---

func update_player_visuals() -> void:
	if mouth_textures.size() > 0: p_mouth.texture = mouth_textures[p_mouth_idx]
	if eyes_textures.size() > 0: p_eyes.texture = eyes_textures[p_eyes_idx]
	if brows_textures.size() > 0: p_brows.texture = brows_textures[p_brows_idx]

func update_target_visuals() -> void:
	if mouth_textures.size() > 0: t_mouth.texture = mouth_textures[t_mouth_idx]
	if eyes_textures.size() > 0: t_eyes.texture = eyes_textures[t_eyes_idx]
	if brows_textures.size() > 0: t_brows.texture = brows_textures[t_brows_idx]

func update_ui_labels(current_score: int) -> void:
	label_score.text = "Matches: " + str(current_score) + "/3"
	label_attempts.text = "Attempts Left: " + str(attempts_left)

# --- BUTTON INPUTS ---

func _on_btn_eyes_pressed() -> void:
	if is_game_over: return # Stop inputs if game ended
	p_eyes_idx = (p_eyes_idx + 1) % eyes_textures.size() # Short way to loop numbers
	update_player_visuals()

func _on_btn_brows_pressed() -> void:
	if is_game_over: return
	p_brows_idx = (p_brows_idx + 1) % brows_textures.size()
	update_player_visuals()

func _on_btn_mouth_pressed() -> void:
	if is_game_over: return
	p_mouth_idx = (p_mouth_idx + 1) % mouth_textures.size()
	update_player_visuals()

# --- THE GAME LOGIC ---

func _on_btn_confirm_pressed() -> void:
	if is_game_over: return
	
	attempts_left -= 1
	var correct_count = 0
	
	# Compare Player Index vs Target Index
	if p_eyes_idx == t_eyes_idx:
		correct_count += 1
	if p_brows_idx == t_brows_idx:
		correct_count += 1
	if p_mouth_idx == t_mouth_idx:
		correct_count += 1
		
	update_ui_labels(correct_count)
	
	# WIN CONDITION
	if correct_count == 3:
		game_over(true)
	# LOSE CONDITION
	elif attempts_left <= 0:
		game_over(false)

func game_over(did_win: bool) -> void:
	is_game_over = true
	# Reveal the secret character!
	$TargetCharacter.modulate = Color.WHITE 
	label_game_over.visible = true
	if did_win:
		label_game_over.text = "YOU WIN!"
		label_game_over.modulate = Color.GREEN
	else:
		label_game_over.text = "GAME OVER!"
		label_game_over.modulate = Color.RED
