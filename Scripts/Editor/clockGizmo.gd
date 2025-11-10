extends Control

@onready var input = $FrequencyInput
var priorValue = "0.25"

func _ready() -> void:
	Simulator.gizmo = self

func setClockStep(value):
	$Clock.play(str(value))


func _on_frequency_input_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		input.text = input.text.trim_suffix(" Hz")
		await get_tree().process_frame
		input.select_all()
	else:
		var value = float(input.text.trim_suffix("Hz"))
		if input.text.is_valid_float() and value > 0:
			var clampedValue = clampf(value, 0.1, Simulator.maxFrequency)
			Simulator.setClockSpeed(clampedValue * 4)
			input.text = str(clampedValue) + " Hz"
			priorValue = input.text.trim_suffix(" Hz")
		else:
			input.text = priorValue + " Hz"
