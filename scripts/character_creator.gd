extends Node2D

const ATTEMPTS_START = 8

# 1. REFERENCING THE SPRITES
# We need to tell the script where our sprite nodes are.
@onready var p_body: Sprite2D = $Character/Head
@onready var p_mouth: Sprite2D = $Character/Mouth
@onready var p_eyes: Sprite2D = $Character/Eyes
@onready var p_brows: Sprite2D = $Character/Brows

# Target (Secret) Sprites
@onready var t_body: Sprite2D = $TargetCharacter/Head
@onready var t_mouth: Sprite2D = $TargetCharacter/Mouth
@onready var t_eyes: Sprite2D = $TargetCharacter/Eyes
@onready var t_brows: Sprite2D = $TargetCharacter/Brows

# 2. DEFINING THE ASSETS
# We create empty arrays that we will fill inside the Godot Editor.
@export var mouth_textures: Array[Texture2D]
@export var eyes_textures: Array[Texture2D]
@export var brows_textures: Array[Texture2D]

@export var character_scene: PackedScene
@export var score_sounds: Array[AudioStream]

# Audio player used to play feedback for confirm results (index 0..4)
var audio_player: AudioStreamPlayer

# Define Skin Colors (White -> Dark Grey)
var skin_colors: Array[Color] = [
	Color("ffffff"), # White
	Color("cccccc"), # Light Grey
	Color("999999"), # Grey
	Color("666666"), # Dark Grey
	Color("333333")  # Very Dark Grey
]

# UI Nodes
@onready var label_score: Label = $CanvasLayer/LabelScore
@onready var label_attempts: Label = $CanvasLayer/LabelAttempts
@onready var label_game_over: Label = $CanvasLayer/LabelGameOver
@onready var btn_restart: Button = $CanvasLayer/BtnRestart

@onready var history_list: VBoxContainer = $CanvasLayer/ScrollContainer/HistoryList
# 3. TRACKING CURRENT SELECTION
# These numbers track which item in the array we are currently showing.
# Player Selections
var p_mouth_idx: int = 0
var p_eyes_idx: int = 0
var p_brows_idx: int = 0
var p_skin_idx: int = 0

# Target (Secret) Selections
var t_mouth_idx: int = 0
var t_eyes_idx: int = 0
var t_brows_idx: int = 0
var t_skin_idx: int = 0

# Game State
var attempts_left: int = ATTEMPTS_START
var is_game_over: bool = false

func _ready() -> void:
	# Initialize the Random Number Generator
	randomize()

	# Create an AudioStreamPlayer to play feedback sounds
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

	start_new_game()

func start_new_game() -> void:
	is_game_over = false
	attempts_left = ATTEMPTS_START
	label_game_over.text = "Game Over!"
	label_game_over.visible = false
	btn_restart.visible = false  # Hide restart button

	for child in history_list.get_children():
		child.queue_free()
	update_ui_labels(0) # 0 score initially
	
	# 1. Pick Random Indexes for the Target
	# The '%' symbol ensures the number is within the array size (0 to Size-1)
	if mouth_textures.size() > 0: t_mouth_idx = randi() % mouth_textures.size()
	if eyes_textures.size() > 0: t_eyes_idx = randi() % eyes_textures.size()
	if brows_textures.size() > 0: t_brows_idx = randi() % brows_textures.size()
	t_skin_idx = randi() % skin_colors.size()

	if mouth_textures.size() > 0: p_mouth_idx = randi() % mouth_textures.size()
	if eyes_textures.size() > 0: p_eyes_idx = randi() % eyes_textures.size()
	if brows_textures.size() > 0: p_brows_idx = randi() % brows_textures.size()
	p_skin_idx = randi() % skin_colors.size()
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
	p_body.modulate = skin_colors[p_skin_idx]

func update_target_visuals() -> void:
	if mouth_textures.size() > 0: t_mouth.texture = mouth_textures[t_mouth_idx]
	if eyes_textures.size() > 0: t_eyes.texture = eyes_textures[t_eyes_idx]
	if brows_textures.size() > 0: t_brows.texture = brows_textures[t_brows_idx]
	t_body.modulate = skin_colors[t_skin_idx]

func update_ui_labels(current_score: int) -> void:
	label_score.text = "Matches: " + str(current_score) + "/4"
	label_attempts.text = "Attempts Left: " + str(attempts_left)

func get_next_index(current: int, direction: int, max_size: int) -> int:
	if max_size == 0: return 0
	# We add max_size before modulo to handle negative numbers correctly
	# Example: (-1 + 5) % 5 = 4. 
	return (current + direction + max_size) % max_size

# --- HISTORY GENERATOR ---
func add_history_entry(score: int) -> void:
	# 1. Create a container for this row
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20) # Add space between items
	
	# 2. Add Label for Attempt Number
	var lbl_num = Label.new()
	lbl_num.text = str(ATTEMPTS_START - attempts_left) + "." # "1.", "2." etc
	lbl_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl_num)
	
	# 3. Create a Container for the Mini Character
	# Node2Ds (Sprites) don't work directly in UI boxes, so we wrap them in a Control node.
	var char_container = Control.new()
	char_container.custom_minimum_size = Vector2(150, 150) # Space reserved for the character
	
	# 4. INSTANTIATE THE SCENE
	if character_scene:
		var mini_char = character_scene.instantiate()
		
		# Set the Scale (Make it small to fit the box!)
		# Adjust '0.2' depending on how big your original images are.
		mini_char.scale = Vector2(0.2, 0.2) 
		
		# Center it in the container (Offset by half the container size)
		mini_char.position = Vector2(50, 50)
		
		# 5. APPLY TEXTURES (Look up the nodes inside the new instance)
		# We use get_node() because this is a new separate instance, not the one on screen.
		
		# Body/Skin
		if mini_char.has_node("Head"):
			mini_char.get_node("Head").modulate = skin_colors[p_skin_idx]
			
		# Mouth
		if mini_char.has_node("Mouth") and mouth_textures.size() > 0:
			mini_char.get_node("Mouth").texture = mouth_textures[p_mouth_idx]
			
		# Eyes
		if mini_char.has_node("Eyes") and eyes_textures.size() > 0:
			mini_char.get_node("Eyes").texture = eyes_textures[p_eyes_idx]
			
		# Brows
		if mini_char.has_node("Brows") and brows_textures.size() > 0:
			mini_char.get_node("Brows").texture = brows_textures[p_brows_idx]
			
		# Add the mini character to the container
		char_container.add_child(mini_char)
		
	row.add_child(char_container)
	
	# 6. Add Score Label
	var lbl_score = Label.new()
	lbl_score.text = "Score: " + str(score)
	lbl_score.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	if score == 4: lbl_score.modulate = Color.GREEN
	elif score == 0: lbl_score.modulate = Color.RED
	else: lbl_score.modulate = Color.YELLOW
		
	row.add_child(lbl_score)
	
	# 7. Add to the list
	history_list.add_child(row)
	
	# Scroll to bottom
	await get_tree().process_frame
	$CanvasLayer/ScrollContainer.scroll_vertical = $CanvasLayer/ScrollContainer.get_v_scroll_bar().max_value


# Helper to make small icons
func create_mini_texture(tex: Texture2D) -> TextureRect:
	var tr = TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(30, 30) # Size of the icon
	# Add a grey background to see it better
	var bg = ColorRect.new()
	bg.color = Color(0,0,0,0.5)
	bg.show_behind_parent = true
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.add_child(bg)
	return tr

# This function builds a "Mini Character" by stacking TextureRects
func create_composite_character() -> Control:
	# A container to hold the layers
	var container = Control.new()
	container.custom_minimum_size = Vector2(60, 60) # Size of the mini image
	
	# We need the base texture of the body to start
	# We grab it directly from the player sprite
	var body_tex = p_body.texture 
	
	# -- LAYER 1: BODY --
	var layer_body = TextureRect.new()
	layer_body.texture = body_tex
	layer_body.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer_body.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer_body.set_anchors_preset(Control.PRESET_FULL_RECT) # Fill the container
	layer_body.modulate = skin_colors[p_skin_idx] # Apply skin color!
	container.add_child(layer_body)
	
	# -- LAYER 2: MOUTH --
	if mouth_textures.size() > 0:
		var layer_mouth = TextureRect.new()
		layer_mouth.texture = mouth_textures[p_mouth_idx]
		layer_mouth.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer_mouth.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		layer_mouth.set_anchors_preset(Control.PRESET_FULL_RECT)
		container.add_child(layer_mouth)

	# -- LAYER 3: EYES --
	if eyes_textures.size() > 0:
		var layer_eyes = TextureRect.new()
		layer_eyes.texture = eyes_textures[p_eyes_idx]
		layer_eyes.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer_eyes.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		layer_eyes.set_anchors_preset(Control.PRESET_FULL_RECT)
		container.add_child(layer_eyes)

	# -- LAYER 4: BROWS --
	if brows_textures.size() > 0:
		var layer_brows = TextureRect.new()
		layer_brows.texture = brows_textures[p_brows_idx]
		layer_brows.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer_brows.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		layer_brows.set_anchors_preset(Control.PRESET_FULL_RECT)
		container.add_child(layer_brows)
		
	return container

# --- BUTTON INPUTS ---
# EYES
func _on_btn_eyes_prev_pressed() -> void:
	p_eyes_idx = get_next_index(p_eyes_idx, -1, eyes_textures.size())
	update_player_visuals()

func _on_btn_eyes_next_pressed() -> void:
	p_eyes_idx = get_next_index(p_eyes_idx, 1, eyes_textures.size())
	update_player_visuals()

# BROWS
func _on_btn_brows_prev_pressed() -> void:
	p_brows_idx = get_next_index(p_brows_idx, -1, brows_textures.size())
	update_player_visuals()

func _on_btn_brows_next_pressed() -> void:
	p_brows_idx = get_next_index(p_brows_idx, 1, brows_textures.size())
	update_player_visuals()

# MOUTH
func _on_btn_mouth_prev_pressed() -> void:
	p_mouth_idx = get_next_index(p_mouth_idx, -1, mouth_textures.size())
	update_player_visuals()

func _on_btn_mouth_next_pressed() -> void:
	p_mouth_idx = get_next_index(p_mouth_idx, 1, mouth_textures.size())
	update_player_visuals()

# SKIN
func _on_btn_skin_prev_pressed() -> void:
	p_skin_idx = get_next_index(p_skin_idx, -1, skin_colors.size())
	update_player_visuals()

func _on_btn_skin_next_pressed() -> void:
	p_skin_idx = get_next_index(p_skin_idx, 1, skin_colors.size())
	update_player_visuals()

# --- THE GAME LOGIC ---

func _on_btn_confirm_pressed() -> void:
	if is_game_over: return
	
	attempts_left -= 1
	var correct_count = 0
	
	# Compare Player Index vs Target Index
	if p_eyes_idx == t_eyes_idx: correct_count += 1
	if p_brows_idx == t_brows_idx: correct_count += 1
	if p_mouth_idx == t_mouth_idx: correct_count += 1
	if p_skin_idx == t_skin_idx: correct_count += 1
		
	update_ui_labels(correct_count)
	
	add_history_entry(correct_count)

	# Play the feedback sound for this score (if assigned)
	if score_sounds and score_sounds.size() > correct_count:
		var s = score_sounds[correct_count]
		if s:
			audio_player.stream = s
			audio_player.play()

	# WIN CONDITION
	if correct_count == 4:
		game_over(true)
	# LOSE CONDITION
	elif attempts_left <= 0:
		game_over(false)

func game_over(did_win: bool) -> void:
	is_game_over = true
	# Reveal the secret character!
	$TargetCharacter.modulate = Color.WHITE 
	label_game_over.visible = true
	btn_restart.visible = true
	if did_win:
		label_game_over.text = "YOU WIN!"
		label_game_over.modulate = Color.GREEN
	else:
		label_game_over.text = "GAME OVER!"
		label_game_over.modulate = Color.RED


func _on_btn_restart_pressed() -> void:
	start_new_game()
