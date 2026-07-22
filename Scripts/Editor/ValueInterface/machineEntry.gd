extends Control

const VALUE = preload("res://Scenes/ValueInterface/valueEntry.tscn")

var parent : Control
var machine : Machine
var values = []

func serialize():
	var out = []
	for value in values:
		if !value.importedInstance:
			out.append(value.serialize())
	return out
	
func deserialize(src, imported = false):
	for entry in src:
		var newValue = addValue()
		newValue.importedInstance = imported
		newValue.deserialize(machine, entry)

func setup(m):
	machine = m
	$Name.text = machine.id

func addValue():
	var newValue = VALUE.instantiate()
	add_child(newValue)
	move_child(newValue, get_child_count()-2)
	values.append(newValue)
	newValue.parent = self
	return newValue

func createValue(selection : Array):
	var value = addValue()
	value.setup(selection)
	return value

func removeValue(value):
	values.erase(value)
	if values.is_empty():
		parent.removeMachineEntry(self)
	else:
		value.queue_free()
