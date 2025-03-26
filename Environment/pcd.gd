extends TileMap


var width = 100
var moisture = FastNoiseLite.new()
var temporature = FastNoiseLite.new()
var altitude = FastNoiseLite.new()
var player

func _ready() -> void:
	altitude.seed = randi()
	temporature.seed = randi()
	moisture.seed = randi()
	player.get_tree().get_first_node_in_group("player")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	generate(player.position)
	
func generate(posn):
	var pos = local_to_map(posn)
	for x in range(width):
		var moist = moisture.get_noise_2d(pos.x-width/2 + x, 0) + 10
		var temp = temporature.get_noise_2d(pos.x-width/2 + x, 0) + 10
		var alt = altitude.get_noise_2d(pos.x-width/2 + x, 0) + 10
		
		alt = int(alt)
		if alt < 0:
			alt = -alt
		alt = alt + 1
		var ly = 0
		var ly2 = 0
		for y in range(10):
			set_cell(0, Vector2i(pos.x -width/2 + x, y), 0, Vector2i(3, 7))
			ly += 1
		ly2 = ly
		for y in range(alt):
			set_cell(0, Vector2i(pos.x-width/2 + x, -(y + ly2)), 0, Vector2i(1, 0))
			ly += 1
		ly2 = ly
		for y in range(5):
			set_cell(0, Vector2i(pos.x-width/2 + x, -(y + ly2)), 0, Vector2i(1, 0))
			ly += 1
		ly2 = ly
		set_cell(0, Vector2i(pos.x-width/2 + x, -(5 + ly2)), 0, Vector2i(round((moist+5)/4), round((temp+5)/3)))
		ly2 += 1
