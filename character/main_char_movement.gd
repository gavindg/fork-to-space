extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

# basic movements: w/a/s/d to move up/left/down/right
# features: double jump - space when in the air; dash - shift; wall-jump - space when colliding against a wall

# Regular movements
const SPEED = 300.0
const JUMP_VELOCITY = -500.0


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# double-jump
var has_jumped = false
var has_double_jumped = false
const double_jump_speed = -500

# dash
var is_dashing = false
var has_dashed = false
var dash_speed = 500

# wall-jump
var can_wall_jump = false
var wall_jump_direction = 0
var wall_jump_speed_againstwall = 300
var wall_jump_speed_upwards = -500

# special movement status (which prevents other input from interfering with those special movements)
var is_special_movement = false



func _physics_process(delta):
	animation_handler()
	
	# reset jump and double jump status
	if is_on_floor():
		has_jumped = false
		has_double_jumped = false
		has_dashed = false
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		
		
	# handle collision and wall_jump
	# collide with the left wall and jmup right-up-wards
	if $left_RayCast2D.is_colliding():
		var collider = $left_RayCast2D.get_collider()
		if collider is TileMap && Input.is_action_pressed("left"):
			can_wall_jump = true
			wall_jump_direction = 1

	# collide with the right wall and jmup left-up-wards
	elif $right_RayCast2D.is_colliding():
		var collider = $right_RayCast2D.get_collider()
		if collider is TileMap && Input.is_action_pressed("right"):
			can_wall_jump = true
			wall_jump_direction = -1
	else:
		can_wall_jump = false
		
	if is_special_movement == false:
		# Handle jump.
		if Input.is_action_just_pressed("jump"):
			# if the character is colliding against the wall and could do wall jump
			if can_wall_jump == true:
				# do wall_jump
				wall_jump(wall_jump_direction)
			
			# if the character could jump for the first time
			elif !has_jumped && is_on_floor():
				velocity.y = JUMP_VELOCITY
				has_jumped = true
			# if not, check for availbility to jump again
			else:
				if !has_double_jumped:
					velocity.y = double_jump_speed
					has_double_jumped = true
				
		var direction = Input.get_axis("left", "right")
		# Handle dash
		# do one more check since the is_special_movement status keeps changing
		if not is_special_movement:
			if not is_dashing:
				direction = Input.get_axis("left", "right")
				# set horizontal direction for animation
				if direction != 0:
					last_move_direction = direction
				if direction:
					velocity.x = direction * SPEED
				else:
					velocity.x = move_toward(velocity.x, 0, SPEED)
			# do dash
			if Input.is_action_just_pressed("dash") && has_dashed == false:
				dash()
			
	move_and_slide()
	


# you can dash to one of the eight directions depending on which (one or two) keys you are holding
enum directions {
	up,
	up_right,
	right,
	down_right,
	down,
	down_left,
	left,
	up_left
}


# the character should be able to dash for a fixed distance for one of the 8 directions on the ground or in the air
# you can dash once before you land to the ground again
func dash():
	is_special_movement = true
	var x_direction = Input.get_axis("left", "right")
	var y_direction = Input.get_axis("up", "down")

	velocity.x = x_direction * dash_speed
	velocity.y = y_direction * dash_speed

	has_dashed = true
	is_dashing = true

	await get_tree().create_timer(0.25).timeout
	is_dashing = false
	is_special_movement = false




# the character should be able to kick the wall to jump to an opposite direction
func wall_jump(wall_jump_dir):
	is_special_movement = true
	if wall_jump_dir == 0:
		return
	velocity.x = wall_jump_dir * wall_jump_speed_againstwall
	velocity.y = wall_jump_speed_upwards
	await get_tree().create_timer(0.3).timeout
	is_special_movement = false
	can_wall_jump = false
	
	
# below are health mechanism

func take_damage():
	Globals.player_health -= 10
	print("current health: ", Globals.player_health)
	var parent = get_parent()
	var sibling = parent.get_node("user_interface_CanvasLayer")
	if sibling and sibling.has_method("update_health_bar"):
		sibling.update_health_bar()
	if Globals.player_health <= 0:
		die()


func die():
	#Globals.player_health = 100 # for testing: reset character health
	queue_free()
	
	
var last_move_direction = 0

func animation_handler() -> void:
	if velocity.x != 0 && is_on_floor():
		if velocity.x < 0:
			animation_player.play("run_left")
		else:
			animation_player.play("run_right")
	elif is_on_floor():
		if last_move_direction < 0:
			animation_player.play("idle_left")
		else:
			animation_player.play("idle_right")
	else:
		if last_move_direction < 0:
			animation_player.play("jump_left")
		else:
			animation_player.play("jump_right")
