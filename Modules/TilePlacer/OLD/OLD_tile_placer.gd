extends Node2D

# export variables -- objects
@export var world : TileMap = null
@export var player : CharacterBody2D = null

# export variables -- tile to place
@export var block_atlas_coords : Vector2i = Vector2i(0, 0)
@export var block_atlas_id : int = 0
@export var player_block_placement_radius := 300.0

# for printing debug statements
@export var debug_messages : bool = false

@onready var screen_center : Vector2 = Vector2()

func _unhandled_input(event: InputEvent) -> void:
	# on click
	if player == null:
		if debug_messages:
			pass
			#print("player could not be found")
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if world == null || player == null:
			if debug_messages:
				print("[TilePlacer]: nothing to do; tilemap is ", world, "player is ", player)
			return
		
		# first check if click was within the player's placement radius
		var click_pos : Vector2 = event.global_position  # get click position
		if in_range(click_pos):
			# convert global click coords to map coords
			var coords = world.local_to_map(world.to_local(click_pos))
			
			# TODO: check here if there's already a block in that position...
			
			# place block
			world.set_cell(0, coords, block_atlas_id, block_atlas_coords)
			
			# debug
			if debug_messages:
				print("click @", event.global_position)
				print("placing @", coords)
				
		# if the click was too far
		elif debug_messages:
			print("click (too far) @", event.position)
			print("player @", player.global_position)
			print("distance:", click_pos.distance_to(player.global_position))


func in_range(click_pos) -> bool:
	return click_pos.distance_to(player.global_position) < player_block_placement_radius;
