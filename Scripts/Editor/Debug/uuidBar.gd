extends Control

@onready var uuidLabel = $ObjectInfo
@onready var searchBar = $HBoxContainer/SearchBar

func _ready() -> void:
	call_deferred("lateReady")

func lateReady():
	Global.editor.selector.newSelection.connect(newSelection)

func newSelection(parts = []):
	if !parts.is_empty() and (parts.back() is Movable or parts.back() is Machine):
		uuidLabel.text = "UUID: " + str(parts.back().uuid)

func _on_search_uuid_pressed() -> void:
	var query = searchBar.value
	var part = Global.workspace.selectedMachine.uuidManager.getPart(query)
	if part:
		Global.editor.selector.selectSet([part])
