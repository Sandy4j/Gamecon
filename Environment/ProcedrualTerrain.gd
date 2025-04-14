@tool
extends TileMapLayer



var TILES = {
   "grass_tiles": [
	   Vector2i(1, 0),
	   Vector2i(2, 0),
	   Vector2i(3, 0),
	   Vector2i(4, 0)
	],
	"grass_edge_left": [
		Vector2i(0, 0)
	],
	"grass_edge_right": [
		Vector2i(5, 0)
	],
	"wall_left": [
		Vector2i(0, 1),
		Vector2i(0, 2),
		Vector2i(0, 3),
		Vector2i(0, 4)
	],
	"wall_right": [
		Vector2i(5, 1),
		Vector2i(5, 2),
		Vector2i(5, 3),
		Vector2i(5, 4)
	],
	"bottom_tiles": [
	   Vector2i(1, 5),
	   Vector2i(2, 5),
	   Vector2i(3, 5),
	   Vector2i(4, 5)
	],
	"bottom_edge_left": [
		Vector2i(0, 5)
	],
	"bottom_edge_right": [
		Vector2i(5, 5)
	],
	"ground_center": [
		Vector2i(2, 2),
		Vector2i(2, 3),
		Vector2i(3, 2),
		Vector2i(3, 3)
	],
	"ground_edge_top": [
		Vector2i(2, 1),
		Vector2i(3, 1)
	],
	"ground_edge_bottom": [
		Vector2i(2, 4),
		Vector2i(3, 4)
	],
	"ground_edge_left": [
		Vector2i(1, 2),
		Vector2i(1, 3)
	],
	"ground_edge_right": [
		Vector2i(4, 2),
		Vector2i(4, 3)
	],
	"ground_edge_lefttop": [
		Vector2i(1, 1)
	],
	"ground_edge_righttop": [
		Vector2i(4, 1)
	],
	"ground_edge_leftbottom": [
		Vector2i(1, 4)
	],
	"ground_edge_rightbottom": [
		Vector2i(4, 4)
	],
	"floating_land_grass": [
		Vector2i(1, 6),
		Vector2i(2, 6),
		Vector2i(3, 6),
		Vector2i(4, 6)
	],
	"floating_land_dirt": [
		Vector2i(1, 7),
		Vector2i(2, 7),
		Vector2i(3, 7),
		Vector2i(4, 7)
	],
	"floating_land_edge_left": [
		Vector2i(0, 6),
		Vector2i(0, 7)
	],
	"floating_land_edge_right": [
		Vector2i(5, 6),
		Vector2i(5, 7)
	]
}

@export var start : bool = false : set = set_start
func set_start(_val:bool)->void:
	if Engine.is_editor_hint():
		generate_terrain()

@export var map_width: int = 500
@export var base_height: int = 30
@export var amplitude: int = 20
@export var ground_depth: int = 5
@export var noise_frequency: float = 0.05
@export var floating_island_chance: float = 0.1

var height_map = []
var noise = FastNoiseLite.new()

#func _ready():
	#if Engine.is_editor_hint():
		#cleanup()
		#generate_terrain()

func cleanup():
	for cell in get_used_cells():
		erase_cell(cell)

func generate_terrain():
	cleanup()
	
	# Configure noise
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.frequency = noise_frequency
	noise.fractal_octaves = 4
	
	generate_main_terrain()
	generate_floating_islands()
	generate_side_walls()

func generate_main_terrain():
	height_map.clear()
	
	# First pass: generate all height values
	for x in map_width:
		var noise_value = noise.get_noise_1d(x)
		var height = base_height + int(noise_value * amplitude)
		height_map.append(height)
	
	# Second pass: place tiles and edges
	for x in map_width:
		var height = height_map[x]
		
		# Place grass top
		var top_pos = Vector2i(x, height)
		set_cell(top_pos, 0, TILES["grass_tiles"][randi() % TILES["grass_tiles"].size()])
		
		# Place ground under top
		for y in range(height + 1, height + ground_depth):
			var pos = Vector2i(x, y)
			set_cell(pos, 0, TILES["bottom_tiles"][randi() % TILES["bottom_tiles"].size()])
		
		# Place edges only after full height map is generated
		if x > 0:
			handle_left_edge(x, height)
		if x < map_width - 1:
			handle_right_edge(x, height)

func handle_left_edge(x, height):
	var left_height = height_map[x - 1]
	if left_height < height:
		place_left_edge(x, height)

func handle_right_edge(x, height):
	var right_height = height_map[x + 1]
	if right_height < height:
		place_right_edge(x, height)

func place_left_edge(x, height):
	for y_offset in range(height + 1, height + ground_depth):
		var pos = Vector2i(x, y_offset)
		set_cell(pos, 0, TILES["grass_edge_left"][0])

func place_right_edge(x, height):
	for y_offset in range(height + 1, height + ground_depth):
		var pos = Vector2i(x, y_offset)
		set_cell(pos, 0, TILES["grass_edge_right"][0])

func generate_side_walls():
	for y in range(base_height - amplitude, base_height + amplitude + ground_depth):
		# Left wall
		set_cell(Vector2i(0, y), 0, TILES["wall_left"][randi() % TILES["wall_left"].size()])
		# Right wall
		set_cell(Vector2i(map_width - 1, y), 0, TILES["wall_right"][randi() % TILES["wall_right"].size()])

func generate_floating_islands():
	var island_noise = FastNoiseLite.new()
	island_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	island_noise.seed = randi()
	island_noise.frequency = noise_frequency * 0.5
	
	for x in map_width:
		for y in range(base_height - amplitude * 2, base_height - amplitude):
			if island_noise.get_noise_2d(x, y) > 0.7:
				place_floating_tile(Vector2i(x, y), "floating_land_grass")
				place_floating_tile(Vector2i(x, y + 1), "floating_land_dirt")
				place_floating_tile(Vector2i(x, y + 2), "floating_land_dirt")
				
				# Place edges
				if get_cell_source_id(Vector2i(x - 1, y)) == -1:
					place_floating_tile(Vector2i(x - 1, y), "floating_land_edge_left")
				if get_cell_source_id(Vector2i(x + 1, y)) == -1:
					place_floating_tile(Vector2i(x + 1, y), "floating_land_edge_right")

func place_floating_tile(pos, tile_type):
	if get_cell_source_id(pos) == -1:  # Only place if empty
		var tiles = TILES[tile_type]
		set_cell(pos, 0, tiles[randi() % tiles.size()])

func _notification(what):
	if what == NOTIFICATION_ENTER_TREE && Engine.is_editor_hint():
		cleanup()
