extends Node

const configPath = "user://Z1SimConfig.json"

func _ready() -> void:
	await get_tree().process_frame
	Global.config.loadConfig()
	#if FileAccess.file_exists(configPath):
		#var config = JSON.parse_string(FileAccess.get_file_as_string(configPath))
		#if config.has("tutorial_completed"):
			#Global.editor.setTutorialCompleted(config["tutorial_completed"])
			##Global.editor.interface.tutorial.inTutorial = config["tutorial_completed"]
		#else:
			#Global.editor.setTutorialCompleted(false)
			#writeConfig()
	#else:
		#Global.editor.setTutorialCompleted(false)
		#writeConfig()

func extractMachines(path : String):
	var source = JSON.parse_string(FileAccess.get_file_as_string(path))
	if !source:
		print("Unable to open JSON File: " + str(FileAccess.get_open_error()))
	if source.has("machines"):
		var out = []
		if source["machines"] is Array:
			for machine in source["machines"]:
				var newMachine = {}
				if machine.has("path"):
					newMachine["machine"] = loadMachineFile(PathHandler.toAbsolutePath(machine["path"]))
					newMachine["pos_x"] = machine["pos_x"]
					if machine.has("pos_y"):
						newMachine["pos_y"] = machine["pos_y"]
					newMachine["pos_z"] = machine["pos_z"]
					newMachine["instance"] = true
					newMachine["path"] = machine["path"]
					if machine.has("uuid"):
						newMachine["uuid"] = machine["uuid"]
					if machine.has("rotation"):
						newMachine["rotation"] = machine["rotation"]
					if machine.has("currentStepOverride"):
						newMachine["currentStepOverride"] = machine["currentStepOverride"]
					if machine.has("diff"):
						newMachine["diff"] = machine["diff"]
					out.append(newMachine)
				else:
					machine["instance"] = false
					machine["path"] = path
					out.append(machine)
		else:
			out.append({"machine":source["machines"],"pos_x":0.0,"pos_y":0.0,"pos_z":0.0, "instance" : false})
		
		if source.has("relations"):
			out.append({"relations":source["relations"]})
		if source.has("sequences"):
			out.append({"sequences":source["sequences"]})
		return out
	else:
		return [{"machine":source,"pos_x":0.0,"pos_y":0.0,"pos_z":0.0, "instance" : false}]

func loadMachineFile(path : String):
	var source = JSON.parse_string(FileAccess.get_file_as_string(path))
	if FileAccess.get_open_error():
		print("Error loading file " + path)
		return
	if !source.has("id"):
		if source.has("machines"):
			return source["machines"][0]["machine"] #TODO: Recursive project loading
		print("Invalid machine file")
		return
	return source

func compile(machines : Array):
	var out = []
	for entry in machines:
		var rotation = entry.rotation.y
		rotation = rotation/(PI/2)
		rotation += 4
		rotation = int(rotation)%4
		if entry.importedInstance:
			out.append({
				"path":PathHandler.toRelativePath(entry.fullPath),
				"pos_x":entry.global_position.x,
				"pos_y":entry.global_position.y,
				"pos_z":entry.global_position.z,
				"rotation":rotation,
				"currentStepOverride":entry.clock.getCurrentStep(),
				"uuid":entry.uuid
			})
			if Global.workspace.saveDiff:
				var diff = entry.serializeDiff()
				if diff:
					out.back()["diff"] = diff
		else:
			out.append({
				"machine":entry.serialize(),
				"pos_x":entry.global_position.x,
				"pos_y":entry.global_position.y,
				"pos_z":entry.global_position.z,
				"rotation":rotation,
				"currentStepOverride":entry.clock.getCurrentStep(),
				"uuid":entry.uuid
			})
	return out

#func writeConfig():
	#var dict = {
		#"tutorial_completed": Global.editor.tutorialDone
	#}
	#var file = FileAccess.open(configPath, FileAccess.WRITE)
	#if file:
		#file.store_string(JSON.stringify(dict))
		#file.close()
	#else:
		#print("Failed to write config file")
