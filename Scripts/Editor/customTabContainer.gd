extends Control

@export var tabs : Array[Control]
@export var buttons : Array[Button]

func _ready() -> void:
	for i in range(buttons.size()):
		buttons[i].pressed.connect(buttonPressed.bind(i))

func buttonPressed(srcId):
	for i in range(tabs.size()):
		tabs[i].visible = i == srcId
	for i in range(buttons.size()):
		buttons[i].disabled = i == srcId
