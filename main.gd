extends Node

# Variables
var score = -10
var time = 0
var vel_ball = Vector2()
var pos_req = 0
var temp
var last = "comp"
var started_=false
var pos_req_p = 450
var delta_ = 1/120
var paused = false
var expected = start_speed
var touch = false

export(int) var senstivity
export(int) var bar_speed
export(int) var start_speed
export(int) var music

# Signals
signal hit_player
signal hit_comp
signal hit_side
signal game_over
signal values_changed
signal restart


func fake_accept():
	if not started_:
		vel_ball = Vector2(-start_speed, 200-randi()%400)
		started_ = true
		$Ball/Line2D.remove_point(0)
		$Label.hide()


func fake_down():
	var vel_player = Vector2()
	vel_player.y += 1  
	vel_player = vel_player.normalized() * bar_speed
	$Player.position += vel_player*delta_
	$Player.position.y = clamp($Player.position.y, 125, 955)
	if not started_ and $Ball.position.y<1045:
			$Ball.move_and_collide(vel_player * delta_)


func fake_up():
	var vel_player = Vector2()
	vel_player.y -= 1  
	vel_player = vel_player.normalized() * bar_speed
	$Player.position += vel_player*delta_
	$Player.position.y = clamp($Player.position.y, 125, 955)
	if not started_ and $Ball.position.y>35:
			$Ball.move_and_collide(vel_player * delta_)


#functions for getting input
func _unhandled_input(event):
	if event is InputEventScreenDrag or event is InputEventScreenTouch:
		touch = true
		if started_:
			pos_req_p = event.position.y 
		else:
			fake_accept()


# Called when the node enters the scene tree for the first time.
func _ready():
	$PausePanel.hide()
	set_process_unhandled_input(true)
	randomize()

# handles player hitting ball
func _on_player_hit(collision):
	if music:
		$Barhit.play()
	vel_ball = vel_ball.bounce(collision.normal)
	last = "player" 
	if expected != vel_ball.x:
		expected = start_speed
		vel_ball.x = start_speed
	elif vel_ball.x < start_speed+200:
		vel_ball.x += 20
		expected += 20
	temp = (1920-$Ball.position.x)/vel_ball.x
	pos_req = $Ball.position.y + temp*vel_ball.y
	if pos_req>1100:
		pos_req = 1080 - (temp-(1080-$Ball.position.y)/vel_ball.y)*vel_ball.y
	elif pos_req<-20:
		pos_req = (temp + $Ball.position.y/vel_ball.y)*vel_ball.y*-1
	score += 10
	$Score.text = "Score:  "+String(score)


# handles comp hitting ball
func _on_comp_hit():
	if music:
		$Barhit.play()
	last = "comp"
	vel_ball.x *= -1
	randomize()
	vel_ball.y = (-vel_ball.x/3.2)-randi()%(int(-vel_ball.x/1.6))

# handles ball hittin sides
func _on_side_hit():
	if music:
		$SideHit.play()
	vel_ball.y *= -1
	if vel_ball.y == 0:
		vel_ball.y = 20

# called after every frame
func _physics_process(delta):
	if started_:
		if vel_ball.x >0:
			_comp_move(delta)
		_move_ball(delta)
		if touch and abs($Player.position.y-pos_req_p)>15:
			_player_touch_move(delta)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	delta_ = delta
	_input_player()
	
#controls comp movement
func _comp_move(delta):
	var vel_comp = Vector2()
	if pos_req > $Comp.position.y:
		vel_comp.y += 1
	elif pos_req < $Comp.position.y:
		vel_comp.y += -1
	if vel_comp.length() > 0:  
		vel_comp = vel_comp.normalized() * 1800
	$Comp.position += vel_comp*delta
	if abs(pos_req-$Comp.position.y) <= 33:
		$Comp.position.y = pos_req
	$Comp.position.y = clamp($Comp.position.y, 125, 955)


func _player_touch_move(delta):
	touch = false
	var vel_player = Vector2()
	if pos_req_p > $Player.position.y:
		vel_player.y += 1
	elif pos_req_p < $Player.position.y:
		vel_player.y += -1
	if vel_player.length() > 0:  
		vel_player = vel_player.normalized() * bar_speed
	$Player.position += vel_player*delta
	if abs(pos_req_p-$Player.position.y) <= 53-senstivity:
		$Player.position.y = pos_req_p
	$Player.position.y = clamp($Player.position.y, 125, 955)

# controls ball motion
func _move_ball(delta):
	$Ball/Line2D.global_position = Vector2(0, 0)
	$Ball/Line2D.add_point($Ball.global_position)
	while $Ball/Line2D.get_point_count() > 13:
		$Ball/Line2D.remove_point(0)

	var collision = $Ball.move_and_collide(vel_ball * delta)
	if collision:
		if collision.collider.name == "Player" and last=="comp":
			emit_signal("hit_player", collision)
		elif collision.collider.name == "Comp" and last=="player":
			emit_signal("hit_comp")
			
	if $Ball.position.y <= 30 or $Ball.position.y >= 1050:
		emit_signal("hit_side")
	if $Ball.position.x <= 80:
		if last=="player":
			score -= 10
		emit_signal("game_over", score)

# controls player movement
func _input_player():
	if Input.is_action_pressed("ui_up"):
		fake_up()
	if Input.is_action_pressed("ui_down"):
		fake_down()
	if Input.is_action_pressed("ui_accept"):
		fake_accept()
	if Input.is_action_pressed("ui_cancel"):
		_on_Pause_pressed()


func _on_Pause_pressed():
	$PausePanel/s_text.text = String(senstivity)
	$PausePanel/s_text.text = String(senstivity)
	$PausePanel/Senstivity.value = senstivity
	$PausePanel/Bar_speed.value = bar_speed
	$PausePanel/ball_speed.value = start_speed
	$PausePanel.show()
	paused = true
	get_tree().paused = true


func _on_pop_close():
	$PausePanel/Timer.start()

func resume_():
	emit_signal("values_changed", senstivity, bar_speed, start_speed, music)
	$PausePanel.hide()
	paused = false
	get_tree().paused = false


func _on_Senstivity_value_changed(value):
	senstivity = value
	$PausePanel/s_text.text = String(int(value))

func _on_Bar_speed_value_changed(value):
	bar_speed = value
	$PausePanel/b_text.text = String(int(value))

func _on_ball_speed_value_changed(value):
	if started_:
		expected = value
	start_speed = value
	$PausePanel/ball_text.text = String(int(value))


func _on_Button_button_down():
	$PausePanel/ConfirmationDialog.show()

func _on_ConfirmationDialog_confirmed():
	get_tree().quit()


func _on_CheckButton_toggled(value):
	music = value

func _on_Reset_button_down():
	$PausePanel/Senstivity.value = 25
	$PausePanel/Bar_speed.value = 2500
	$PausePanel/ball_speed.value = 1600

func restart():
	$PausePanel/ConfirmationDialog2.show()

func _on_ConfirmationDialog2_confirmed():
	emit_signal("values_changed", senstivity, bar_speed, start_speed, music)
	get_tree().paused = false
	emit_signal("restart")
