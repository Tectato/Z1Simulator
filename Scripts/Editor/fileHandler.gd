extends Node

func extractMachines(path : String):
	var source = JSON.parse_string(FileAccess.get_file_as_string(path))
	if source.has("machines"):
		var out = []
		if source["machines"] is Array:
			for machine in source["machines"]:
				var newMachine = {}
				if machine.has("pos_x"):
					newMachine["machine"] = loadMachineFile(machine["path"])
					newMachine["pos_x"] = machine["pos_x"]
					newMachine["pos_z"] = machine["pos_z"]
					newMachine["instance"] = true
					out.append(newMachine)
		else:
			out.append({"machine":source["machines"],"pos_x":0.0,"pos_z":0.0, "instance" : false})
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
