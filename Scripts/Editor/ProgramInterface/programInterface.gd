extends Control
class_name Sequencer

const SEQUENCE = preload("res://Scenes/ProgramInterface/ProgramEntry.tscn")

var sequences = []

func serialize():
	var out = []
	for sequence in sequences:
		if !sequence.isEmpty():
			out.append(sequence.serialize())
	return out

func deserialize(arr = []):
	for sequence in arr:
		var newSequence = addSequence()
		newSequence.deserialize(sequence)

func addSequence():
	var newSequence = SEQUENCE.instantiate()
	if sequences.is_empty():
		$First.add_sibling(newSequence)
	else:
		sequences.back().add_sibling(newSequence)
	sequences.append(newSequence)
	return newSequence

func _on_add_pressed() -> void:
	addSequence()

func _input(event: InputEvent) -> void:
	if event.is_echo(): return
	if event.is_action_pressed("delete"):
		var selected = get_viewport().gui_get_focus_owner()
		if selected is Sequence:
			sequences.erase(selected)
			selected.queue_free()

func clear():
	while !sequences.is_empty():
		sequences.pop_back().queue_free()
