extends CharacterBody2D

enum State {PATROL, CHASE, DEAD}

var max_hp = 10
var hp: int
var current_state = State.PATROL
var direction = Vector2.LEFT
var patrol_speed = 50.0
var chase_speed = 80.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var player = null
var can_turn = true

@onready var sprite = $Sprite2D
@onready var hp_bar = $HPBar
@onready var raycast_edge = $RayEdge
@onready var raycast_wall = $RayWall
@onready var player_detection = $DetectionArea

func _ready() -> void:
	hp = max_hp
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	match current_state:
		State.PATROL:
			patrol_state(delta)
		State.CHASE:
			chase_state(delta)
		State.DEAD:
			dead_state(delta)
	
	move_and_slide()

	update_animation()

func patrol_state(delta):
	velocity.x = direction.x * patrol_speed
	
	if can_turn and is_on_floor():
		if not raycast_edge.is_colliding() and raycast_edge.enabled:
			turn_around()
		elif raycast_wall.is_colliding():
			turn_around()

func turn_around():
	if can_turn:
		can_turn = false
		direction *= -1
		
		raycast_wall.target_position.x *= -1
		raycast_edge.target_position.x *= -1
		
		# $Sprite2D.flip_h = direction.x > 0
		await get_tree().create_timer(0.5).timeout
		can_turn = true

func chase_state(delta):
	if player != null:
		var player_direction = (player.global_position - global_position).normalized()
		velocity.x = player_direction.x * chase_speed

		# $Sprite2D.flip_h = velocity.x > 0
	else:
		current_state = State.PATROL

func dead_state(delta):
	velocity = Vector2.ZERO
	
	# if $AnimationPlayer.current_animation != "death":
	#     $AnimationPlayer.play("death")

func take_damage(value: int):
	hp -= value
	hp_bar.value = hp
	
	if hp <= 0:
		current_state = State.DEAD
	else:
		sprite.modulate = Color(1, 0, 0)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)
		pass

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body
		current_state = State.CHASE

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player = null
		await get_tree().create_timer(1.0).timeout
		if current_state != State.DEAD:
			current_state = State.PATROL

func update_animation():
	pass
	# This will be implemented later, but here's how you might structure it
	# match current_state:
	#     State.PATROL:
	#         $AnimationPlayer.play("walk")
	#     State.CHASE:
	#         $AnimationPlayer.play("run")
	#     State.DEAD:
	#         $AnimationPlayer.play("death")
