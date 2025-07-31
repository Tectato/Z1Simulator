extends Control

@onready var input = $FrequencyInput
var priorValue = "1"

func _ready() -> void:
	Simulator.gizmo = self

func setClockStep(value):
	$Clock.play(str(value))


func _on_frequency_input_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		input.text = input.text.trim_suffix(" Hz")
	else:
		var value = float(input.text)
		if input.text.is_valid_float() and value <= 4 and value > 0:
			priorValue = input.text.trim_suffix(" Hz")
			Simulator.setClockSpeed(value)
			input.text = input.text + " Hz"
		else:
			input.text = priorValue + " Hz"
