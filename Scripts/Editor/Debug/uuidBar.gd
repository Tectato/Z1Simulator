extends Control

@onready var uuidLabel = $ObjectInfo
@onready var searchBar = $HBoxContainer/SearchBar

func _ready() -> void:
	call_deferred("lateReady")

func lateReady():
	Global.editor.selector.newSelection.connect(newSelection)

func newSelection(parts = []):
	if !parts.is_empty() and (parts.back() is Movable or parts.back() is Machine):
		var addendum = ""
		if parts.size() == 2:
			var distance = Space.toVec2(parts.front().global_position).distance_to(Space.toVec2(parts.back().global_position))
			distance = snappedf(distance, 0.01)
			addendum = "\nDistance: " + str(distance)
		uuidLabel.text = "UUID: " + str(parts.back().uuid) + addendum

func _on_search_uuid_pressed() -> void:
	var query = searchBar.value
	var part = Global.workspace.selectedMachine.uuidManager.getPart(query)
	if part:
		Global.editor.selector.selectSet([part])
