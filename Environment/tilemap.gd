extends TileMap

signal enemy_defeated(points) 

const Enemy = preload("res://Actor/enemy/enemy.tscn")

var generation_width = 100
var underground_depth = 50  
var altitude_noise = FastNoiseLite.new()
var player
var active_enemies = []
var max_enemies = 10 
var spawn_cooldown = 2.0
var spawn_timer = 0.0
var min_spawn_distance = 200
var max_spawn_distance = 400
var distance_traveled = 0
var player_start_position = Vector2.ZERO

func _ready() -> void:
	altitude_noise.seed = randi()
	altitude_noise.frequency = 0.010
	player = get_parent().get_child(2)
	player_start_position = player.position
	spawn_timer = 2.0

func _process(delta: float) -> void:
	generate(player.position)
	distance_traveled = max(distance_traveled, player.position.x - player_start_position.x)

	clean_up_enemies()
	manage_enemy_spawning(delta)

func clean_up_enemies():
	var i = 0
	while i < active_enemies.size():
		if !is_instance_valid(active_enemies[i]):
			active_enemies.remove_at(i)
			emit_signal("enemy_defeated", 10)
		else:
			i += 1

func manage_enemy_spawning(delta):
	if spawn_timer > 0:
		spawn_timer -= delta
	elif active_enemies.size() < max_enemies:
		spawn_new_enemy()
		spawn_timer = spawn_cooldown

func generate(player_position):
	var player_tile_pos = local_to_map(player_position)
	var start_x = player_tile_pos.x - generation_width/2
	var end_x = start_x + generation_width
	
	for world_x in range(start_x, end_x):
		var surface_y = get_surface_height(world_x)

		set_cell(0, Vector2i(world_x, surface_y), 0, Vector2i(0, 0))
		for y in range(surface_y + 1, surface_y + underground_depth):
			set_cell(0, Vector2i(world_x, y), 0, Vector2i(0, 1))

func spawn_new_enemy():
	var direction = 1
	if randf() < 0.2:
		direction = -1

	var spawn_distance = min_spawn_distance + randf() * (max_spawn_distance - min_spawn_distance)
	var spawn_x_pos = player.position.x + (direction * spawn_distance)
	var spawn_x_tile = int(spawn_x_pos / tile_set.tile_size.x)
	var surface_y = get_surface_height(spawn_x_tile)
	
	var enemy_pos = map_to_local(Vector2i(spawn_x_tile, surface_y - 2))
	var enemy = Enemy.instantiate()
	
	enemy.position = enemy_pos
	get_parent().add_child(enemy)
	active_enemies.append(enemy)
	
	print("Spawned enemy at: ", enemy_pos, " Active enemies: ", active_enemies.size())

func get_surface_height(world_x):
	var noise_value = altitude_noise.get_noise_2d(world_x, 0)
	return int(noise_value * 20) + 40
