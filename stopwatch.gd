extends Control

@onready var timer: Timer = $Timer
@onready var label: Label = $Label
@onready var score_label: Label = $ScoreLabel

var time_elapsed := 0.0
var running := false

func _ready():
	timer.wait_time = 0.1

func update_score(value: int) -> void:
	score_label.text = "Score: " + str(value)

func _on_timer_timeout():
	if running:
		time_elapsed += timer.wait_time
		update_label()

func start_stopwatch():
	running = true
	timer.start()

func stop_stopwatch():
	running = false
	timer.stop()

func reset_stopwatch():
	time_elapsed = 0.0
	update_label()

func update_label():
	label.text = "Time: %.1f s" % time_elapsed
