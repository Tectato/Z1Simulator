extends Node

var configPath = "user://Z1SimConfig.json"

var values = {
	"tutorial_completed" : false,
	"default_scene" : "/Machines/Adder/Adder.json"
}

func loadConfig():
	if !FileAccess.file_exists(configPath):
		Global.editor.interface.debugLabel.text = "Could not find config, using fallback"
		configPath = "/Z1SimConfig.json" # Fallback
	
	if !FileAccess.file_exists(configPath):
		Global.editor.interface.debugLabel.text = "Fallback failed"
	
	if FileAccess.file_exists(configPath):
		var config = JSON.parse_string(FileAccess.get_file_as_string(configPath))
		if config:
			for key in config.keys():
				values[key] = config[key]
	#else:
		#Global.editor.interface.debugLabel.text = "Could not find config"
	
	Global.editor.setTutorialCompleted(values["tutorial_completed"])
	var defaultScene = values["default_scene"]
	if len(defaultScene) > 0 and FileAccess.file_exists(defaultScene) and defaultScene.ends_with(".json"):
		await get_tree().process_frame
		Global.editor.loadProject(defaultScene)
	else:
		Global.editor.interface.debugLabel.text += ". Invalid default scene (" + defaultScene + ")"

func saveConfig():
	values["tutorial_completed"] = Global.editor.tutorialDone
	
	var file = FileAccess.open(configPath, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(values))
		file.close()
	else:
		print("Failed to write config file")
