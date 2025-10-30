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
		input.select_all()
	else:
		var value = float(input.text.trim_suffix("Hz"))
		if input.text.is_valid_float() and value > 0:
			var clampedValue = clampf(value, 0.1, 4)
			Simulator.setClockSpeed(clampedValue)
			input.text = str(clampedValue) + " Hz"
			priorValue = input.text.trim_suffix(" Hz")
		else:
			input.text = priorValue + " Hz"
