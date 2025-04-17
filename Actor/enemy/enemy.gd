extends CharacterBody2D

enum State { CHASE, DEAD, ATTACK }

var max_hp = 5
var hp: int
var current_state = State.CHASE
var direction = Vector2.LEFT
var chase_speed = 80.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var player = null
var can_turn = true
var jump_velocity = -200.0
var is_jumping = false
var jump_cooldown = false
var attack_cooldown = false
var attack_damage = 2
var attack_in_progress = false

@onready var sprite = $Sprite2D
@onready var hp_bar = $HPBar
@onready var raycast_edge = $RayEdge
@onready var ray_attack = $RayAttack
@onready var animation_player = $AnimationPlayer


func _ready() -> void:
	hp = max_hp
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta):
	apply_gravity(delta)

	match current_state:
		State.CHASE:
			chase_state(delta)
		State.DEAD:
			dead_state(delta)
		State.ATTACK:
			attack_state(delta)
			
	move_and_slide()
	update_animation()


func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		is_jumping = false

func turn_around():
	if can_turn and player != null:
		can_turn = false
		direction = Vector2.RIGHT if player.global_position.x > global_position.x else Vector2.LEFT
		raycast_edge.target_position.x = direction.x * abs(raycast_edge.target_position.x)
		ray_attack.target_position.x = direction.x * abs(ray_attack.target_position.x)
		sprite.flip_h = direction.x < 0
		await get_tree().create_timer(0.5).timeout
		can_turn = true

func chase_state(delta):
	if player != null:
		var move_direction = (player.global_position - global_position).normalized()
		velocity.x = move_direction.x * chase_speed

		if (move_direction.x > 0 and direction.x < 0) or (move_direction.x < 0 and direction.x > 0):
			turn_around()

		if is_on_wall() and is_on_floor() and not jump_cooldown:
			jump()

		if ray_attack.is_colliding() and ray_attack.get_collider() == player and not attack_cooldown:
			current_state = State.ATTACK

func attack_state(delta):
	velocity.x = 0
	if not attack_in_progress:
		attack_in_progress = true
		attack()

func attack():
	if player == null or current_state == State.DEAD:
		return

	print("Attacking player!")
	if ray_attack.is_colliding() and ray_attack.get_collider() == player:
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)
	animation_player.play("attack")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		attack_in_progress = false
		current_state = State.CHASE
		attack_cooldown = true
		await get_tree().create_timer(1.0).timeout
		attack_cooldown = false

func jump():
	velocity.y = jump_velocity
	is_jumping = true
	jump_cooldown = true
	await get_tree().create_timer(0.5).timeout
	jump_cooldown = false

func dead_state(delta):
	velocity = Vector2.ZERO
	queue_free()

func take_damage(value: int):
	hp -= value
	hp_bar.value = hp
	if hp <= 0:
		current_state = State.DEAD
	else:
		hited()

func hited():
	sprite.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1)

func update_animation():	
	match current_state:
		State.CHASE:
			animation_player.play("run")
		State.DEAD:
			animation_player.play("death")
		State.ATTACK:
			animation_player.play("attack")
