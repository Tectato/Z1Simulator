extends Control

const PLAN = preload("res://Scenes/PlanInterface/Plan.tscn")

@onready var viewport = $"SubViewportContainer/2DView"
var currentPlan : Plan

func setPlan(plan : Plan):
	if plan == currentPlan: return
	if currentPlan:
		currentPlan.visible = false
	if plan:
		plan.visible = true
	currentPlan = plan

func createPlan(image):
	if currentPlan:
		return #TODO: prompt to replace
	var newPlan = PLAN.instantiate()
	viewport.add_child(newPlan)
	newPlan.layer = Global.workspace.selectedLayer
	newPlan.layer.plan = newPlan
	newPlan.setImage(image)
	currentPlan = newPlan

func _on_selector_toggled(toggled_on: bool) -> void:
	$Elements.visible = !toggled_on
