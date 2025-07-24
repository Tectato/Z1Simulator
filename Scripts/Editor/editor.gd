extends Node3D
class_name Editor

var savePath = ""


func newProject():
	pass

func saveAs(path : String):
	savePath = path
	save()

func save():
	pass

func loadProject(path : String):
	pass

func importProjectInstace(path : String):
	pass

func importSheet(path : String):
	pass
