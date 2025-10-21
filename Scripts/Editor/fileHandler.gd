extends Node

func _ready() -> void:
	#if OS.get_name() == "Web":
		#var path = OS.get_executable_path()
		#print("Path: " + path)
		var arr = DirAccess.get_files_at(".")
		print("Files:")
		for file in arr:
			print(file)
			if file.ends_with(".png"):
				var image = Image.load_from_file(file)
				if image:
					print("Was able to read image")
				else:
					print("Failed to read image")
		pass
		# Copy example machines to web user folder
		#print("Trying to copy machine files")
		#copy_dir_recursively("res://Test/", "Test/")

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
			out.append({"machine":source["machines"],"pos_x":0.0,"pos_z":0.0, "instance" : false})
		
		if source.has("relations"):
			out.append({"relations":source["relations"]})
		if source.has("sequences"):
			out.append({"sequences":source["sequences"]})
		return out
	else:
		return [{"machine":source,"pos_x":0.0,"pos_z":0.0, "instance" : false}]

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
				"pos_z":entry.global_position.z,
				"rotation":rotation,
				"currentStepOverride":entry.clock.getCurrentStep(),
				"uuid":entry.uuid
			})
	return out

# Taken from https://www.reddit.com/r/godot/comments/19f0mf2
func copy_dir_recursively(source: String, destination: String):
	DirAccess.make_dir_recursive_absolute(destination)
	
	var source_dir = DirAccess.open(source);
	
	for filename in source_dir.get_files():
		#if ResourceLoader.exists(filename.rstrip(".import")):
			#print(filename.get_file())
		#else:
			#print("No resource found for " + filename.get_file().rstrip(".import"))
		var file = filename.rstrip(".import")
		if file.ends_with("json") or file.ends_with("svg") or file.ends_with("png") or file.ends_with("jpg") or file.ends_with("jpeg"):
			#print(file.get_file())
			#OS.alert(source + filename, 'Datei erkannt')
			source_dir.copy(source + filename, destination + filename)
		
	for dir in source_dir.get_directories():
		self.copy_dir_recursively(source + dir + "/", destination + dir + "/")
