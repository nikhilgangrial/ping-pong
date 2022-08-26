extends Node


# Variables
var scene = load("res://main.tscn")
var game
var running = true
var accept = false
var senstivity = 25
var bar_speed = 2500
var start_speed = 1600
var music = true
var highscore = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$Node/Label.hide()
	$Node/Label2.hide()
	$Timer.start()

func _input(event):
	if not running:
		if event is InputEventScreenTouch:
			accept = true
		if event.is_action_pressed('ui_accept') or accept:
			$Timer.start()
			accept = false
			running = true

func load_saved():
	var save_game = File.new()
	if not save_game.file_exists("user://savegame_pong.save"):
		return
	save_game.open("user://savegame_pong.save", File.READ)
	senstivity = save_game.get_64()
	bar_speed = save_game.get_64()
	start_speed = save_game.get_64()
	highscore = save_game.get_64()
	# avoiding error if wrong format file already exists
	if not start_speed:
		start_speed = 1600
	if not bar_speed:
		bar_speed = 2500
	if not senstivity:
		senstivity = 25
	save_game.close()


func _start_delayed():
	#load old data
	load_saved()
	game = scene.instance()
	add_child(game)
	game.senstivity = senstivity
	game.bar_speed = bar_speed
	game.start_speed = start_speed
	game.music = music
	game.connect('game_over', self, '_game_over')
	game.connect('values_changed', self, '_values_changed')
	game.connect('restart', self, '_restart')
	$GameOver.stop()
	$Node/Label.hide()
	$Node/Label2.hide()

func _values_changed(_senstivity, _bar_speed, _start_speed, _music):
	senstivity = _senstivity
	bar_speed = _bar_speed
	start_speed = _start_speed
	music = _music
	save_data()
	
func save_data():
	var save_game = File.new()
	save_game.open("user://savegame_pong.save", File.WRITE)
	save_game.store_64(senstivity)
	save_game.store_64(bar_speed)
	save_game.store_64(start_speed)
	save_game.store_64(highscore)
	save_game.close()
	
func _game_over(score):
	if score > highscore:
		highscore = score
		save_data()
	$Node/Label2.text = "\n\nTap to continue \n High Score: "+String(highscore)+"\n Your Score: "+String(score) 
	$Node/Label.show()
	$Node/Label2.show()
	if music:
		$GameOver.play()
	_end()

func _end():
	game.queue_free()
	running = false
	accept = false

func _restart():
	_end()
	$Timer.start()
	running = true
