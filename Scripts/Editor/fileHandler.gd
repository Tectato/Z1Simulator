extends Node

func extractMachines(path : String):
	var source = JSON.parse_string(FileAccess.get_file_as_string(path))
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
					out.append(newMachine)
				else:
					machine["instance"] = false
					out.append(machine)
		else:
			out.append({"machine":source["machines"],"pos_x":0.0,"pos_z":0.0, "instance" : false})
		
		if source.has("relations"):
			out.append(source["relations"])
		return out
	else:
		return [{"machine":source,"pos_x":0.0,"pos_z":0.0, "instance" : false}]

func loadMachineFile(path : String):
	var source = JSON.parse_string(FileAccess.get_file_as_string(path))
	if FileAccess.get_open_error():
		print("Error loading file " + path)
		return
	if !source.has("id"):
		print("Invalid machine file")
		return
	return source

func compile(machines : Array):
	var out = []
	for entry in machines:
		if entry.importedInstance:
			out.append({
				"path":PathHandler.toRelativePath(entry.fullPath),
				"pos_x":entry.global_position.x,
				"pos_z":entry.global_position.z
			})
		else:
			out.append({
				"machine":entry.serialize(),
				"pos_x":entry.global_position.x,
				"pos_z":entry.global_position.z
			})
	return out
