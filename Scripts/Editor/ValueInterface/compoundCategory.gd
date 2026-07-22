extends Control

const VALUE = preload("res://Scenes/ValueInterface/floatEntry.tscn")

var parent : Control
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
		newValue.parent = self
		newValue.deserialize(entry)

func setup(name : String):
	$Name.text = name

func addValue():
	var newValue = VALUE.instantiate()
	add_child(newValue)
	move_child(newValue, get_child_count()-2)
	values.append(newValue)
	newValue.parent = self
	return newValue

func createValue(valueA, valueB, selection : Array):
	addValue().setup(valueA, valueB, selection)

func removeValue(value):
	values.erase(value)
	if values.is_empty():
		parent.removeCompoundCategory()
	else:
		value.queue_free()
