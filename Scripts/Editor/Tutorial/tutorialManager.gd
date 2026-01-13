extends Control

@export var nodes : Array[Control]
@export var fileMenu : PopupMenu
@export var helpMenu : PopupMenu
var currentIndex = 0
var inTutorial = true

func stepTo(id : int):
	if id != currentIndex+1: return
	if currentIndex < nodes.size():
		nodes[currentIndex].hide()
	currentIndex = id
	if id < nodes.size():
		nodes[currentIndex].init()
		nodes[currentIndex].show()
		if currentIndex == nodes.size()-1:
			nodes[currentIndex].next()
	else:
		skip()

func skip():
	inTutorial = false
	helpMenu.set_item_text(1, "Start Tutorial")
	#setFileMask(false)
	for node in nodes:
		node.hide()
	currentIndex = nodes.size()
	hide()
	Global.editor.tutorialDone = true
	Global.config.saveConfig()

func start():
	inTutorial = true
	helpMenu.set_item_text(1, "Skip Tutorial")
	#setFileMask(true)
	for node in nodes:
		node.hide()
	currentIndex = 0
	nodes[currentIndex].show()
	nodes[currentIndex].next()
	show()

func setFileMask(masked):
	for item in fileMenu.item_count:
		fileMenu.set_item_disabled(item, masked and item != 3)
