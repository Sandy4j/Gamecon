extends Node2D

@onready var health_bar = $Player/ProgressBar
@onready var tilemap = $TileMap
@onready var stopwatch = $UI/Control
@onready var player = $Player

var difficulty_increase_interval := 45.0
var next_difficulty_time := 45.0
var score := 0
var next_score_threshold := 50
var is_game_over := false


func _ready() -> void:
	stopwatch.start_stopwatch()
	tilemap.connect("enemy_defeated", _on_enemy_defeated)
	player.connect("player_died", _on_player_died)
	player.connect("health_changed", _on_player_health_changed)
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	
func _process(delta: float) -> void:
	var current_time = stopwatch.time_elapsed
	if current_time >= next_difficulty_time:
		increase_difficulty()
		next_difficulty_time += difficulty_increase_interval

func _on_player_health_changed(new_health: int):
	health_bar.value = new_health 

func _on_enemy_defeated(points: int) -> void:
	score += points
	$UI/Control.update_score(score)
   
	if score >= next_score_threshold:
		increase_difficulty()
		next_score_threshold += 50

func increase_difficulty() -> void:
	if tilemap.max_enemies < 50:
		tilemap.max_enemies += 1
	tilemap.spawn_cooldown = max(0.5, tilemap.spawn_cooldown - 0.3)
	
	print("Difficulty Increased! Enemies: ", tilemap.max_enemies, " | Cooldown: ", tilemap.spawn_cooldown)

func _on_player_died():
	if is_game_over:
		return
	is_game_over = true
	
	stopwatch.stop_stopwatch()
	tilemap.set_process(false)

	$UI/Control/GameOverPanel.show()
	$UI/Control/GameOverPanel/Score.text = "Score: %d" % score

func _on_restart_pressed():
	get_tree().reload_current_scene()

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://menu.tscn")
