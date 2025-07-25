extends Control

@onready var reset = $Reset
@onready var prev = $PrevStep
@onready var pausePlay = $PausePlay
@onready var next = $NextStep

func _on_reset_pressed() -> void:
	pausePlay.set_pressed_no_signal(false)
	Simulator.reset()

func _on_prev_step_pressed() -> void:
	pausePlay.set_pressed_no_signal(false)
	Simulator.prev()

func _on_pause_play_toggled(toggled_on: bool) -> void:
	if toggled_on:
		Simulator.start()
	else:
		Simulator.stop()

func _on_next_step_pressed() -> void:
	pausePlay.set_pressed_no_signal(false)
	Simulator.next()
