extends Control

const PLAN = preload("res://Scenes/PlanInterface/Plan.tscn")

@onready var viewport = $"SubViewportContainer/2DView"
@onready var selector = $Tools/Selector
@onready var editor = $Tools/Editor
@onready var selectedTool = selector
@onready var camera = $"SubViewportContainer/2DView/Camera2D"
var currentPlan : Plan

func setPlan(plan : Plan):
	if plan == currentPlan: return
	if currentPlan:
		currentPlan.visible = false
	if plan:
		plan.visible = true
	currentPlan = plan

func createPlan(image, path):
	if currentPlan:
		return #TODO: prompt to replace
	var newPlan = PLAN.instantiate()
	viewport.add_child(newPlan)
	newPlan.layer = Global.workspace.selectedLayer
	newPlan.layer.plan = newPlan
	newPlan.setImage(image, path)
	currentPlan = newPlan

func addPlan(plan : Plan):
	viewport.add_child(plan)
	plan.visible = false

func handleInput(event: InputEvent) -> void:
	#if event.is_action_pressed("toggle_transform_gizmo"):
		#var selectorSelected = selectedTool == selector
		#$ToolButtons/Selector.button_pressed = !selectorSelected
		#$ToolButtons/Editor.button_pressed = selectorSelected
		#_on_selector_toggled(!selectorSelected)
	if event.is_echo(): return
	if currentPlan and currentPlan.hasImage:
		selectedTool.handleInput(event)
	if !get_window().has_focus(): return
	if !get_rect().has_point(get_parent().get_local_mouse_position()): return

func _on_selector_toggled(toggled_on: bool) -> void:
	$Elements.visible = !toggled_on
	selectedTool = selector if toggled_on else editor
	if toggled_on:
		if editor.selectedMarker:
			selector.selectedMarkers = [editor.selectedMarker]
		else:
			selector.selectedMarkers = []
		selector.updateButtons()

func _on_link_button_down() -> void:
	if Global.editor.selector.selected.size() == 1 and Global.editor.selector.selected[0] is Sheet and selector.selectedMarkers.size() == 1:
		selector.selectedMarkers[0].linkToSheet(Global.editor.selector.selected[0])

func _on_unlink_button_down() -> void:
	for marker in selector.selectedMarkers:
		marker.unlink()
