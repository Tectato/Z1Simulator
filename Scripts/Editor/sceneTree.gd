extends Control

@export var selector : Selector
@onready var restPos = global_position
@onready var tree = $Tree
var priorSelected : TreeItem

func _ready() -> void:
	get_tree().get_root().size_changed.connect(updateRestPos)
	tree.cell_selected.connect(cellSelected)
	#tree.item_activated.connect(cellActivated)

func updateRestPos():
	restPos = global_position - Vector2(180,0) if $Hide.button_pressed else global_position

func _on_hide_toggled(toggled_on: bool) -> void:
	global_position = restPos + Vector2(180,0) if toggled_on else restPos

func updateSceneTree():
	tree.clear()
	var root = tree.create_item()
	#root.set_text(0, savePath.get_file() if savePath.length() > 0 else "Project")
	for machine in Global.workspace.machines:
		var newItem = tree.create_item(root)
		newItem.set_text(0, machine.id if machine.id.length() > 0 else "UnnamedMachine")

func cellSelected():
	var cell = tree.get_selected()
	Global.workspace.setMode(Workspace.Mode.Select)
	Global.workspace.setResolution(Workspace.Resolution.Machine)
	selector.select(Global.workspace.machines[cell.get_index()].collider.get_parent())

func cellActivated():
	var selected = tree.get_selected()
	print(str(selected.get_text(0)))
	selected.set_editable(0, true)
	if priorSelected:
		priorSelected.set_editable(0, false)
	priorSelected = selected
