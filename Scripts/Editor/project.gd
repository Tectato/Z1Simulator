extends Node3D
class_name Project

var topLevelInstance = false
var parent : Project
var machines = []
var subprojects = []
var path = ""
var srcUUID = -1
var uuid = -1
var totalOffset = Vector3.ZERO

func setup(parentProj):
	parent = parentProj if parentProj is Project else null
	topLevelInstance = parent == null

func serialize():
	var out = {}
	if uuid != srcUUID:
		out["uuid_override"] = uuid
	var subprojectArr = []
	for project in subprojects:
		subprojectArr.append(project.serialize())
	if !subprojectArr.is_empty():
		out["projects"] = subprojectArr
	var machineDict = {}
	for machine in machines:
		if machine.srcUUID != machine.uuid:
			machineDict[machine.srcUUID] = {"uuid_override" : machine.uuid}
	if !machineDict.is_empty():
		out["machines"] = machineDict
	return out

func deserialize(src = {}):
	if src.has("uuid_override"):
		srcUUID = -1
		uuid = int(src["uuid_override"]) # Notify UUIDManager?
	if src.has("projects"):
		for i in range(subprojects.size()):
			subprojects[i].deserialize(src["projects"][i])
	if src.has("machines"):
		for key in src["machines"].keys():
			var target
			for machine in machines:
				if machine.srcUUID == int(key):
					target = machine
					break
			if target:
				target.uuid = int(src["machines"][key]["uuid_override"])
				Global.workspace.uuidManager.registerID(target, target.uuid, false)

func serializeDiff():
	var out = {}
	var immediateDiff = {}
	for machine in machines:
		var machineDiff = machine.serializeDiff()
		if !machineDiff.is_empty():
			immediateDiff[machine.uuid] = machineDiff
	if !immediateDiff.is_empty():
		out["machines"] = immediateDiff
	
	var recursiveDiff = {}
	for project in subprojects:
		var projectDiff = project.serializeDiff()
		if !projectDiff.is_empty():
			recursiveDiff[project.uuid] = projectDiff
	if !recursiveDiff.is_empty():
		out["projects"] = recursiveDiff
	
	return out

func deserializeDiff(src = {}):
	var hasMachines = false
	var hasProjects = false
	if src.has("machines"):
		hasMachines = true
		for machineID in src["machines"]:
			var machine = Global.workspace.uuidManager.getPart(int(machineID))
			if machine:
				machine.deserializeDiff(src["machines"][machineID])
	if src.has("projects"):
		hasProjects = true
		for projectID in src["projects"]:
			var project
			for candidate in subprojects:
				if candidate.uuid == int(projectID):
					project = candidate
					break
			if project:
				project.deserializeDiff(src["projects"][projectID])
	if !hasMachines and !hasProjects: # Legacy format
		if machines.size() == 1:
			machines[0].deserializeDiff(src)

func addMachine(machine : Machine):
	add_child(machine)
	machines.append(machine)
	machine.parent = self

func addProject(project : Project):
	add_child(project)
	subprojects.append(project)

func setPath(newPath : String):
	path = newPath
	name = newPath.get_file().trim_suffix(".json")

func machineMoved(machine : Machine, offset : Vector3):
	if topLevelInstance:
		applyOffset(machine, offset)
		totalOffset += offset
	else:
		parent.machineMoved(machine, offset)

func applyOffset(exclude : Machine, offset : Vector3):
	for project in subprojects:
		project.applyOffset(exclude, offset)
	for machine in machines:
		if machine == exclude: continue
		machine.position += offset
		machine.previousPos = machine.position

func removeMachine(machine : Machine):
	machines.erase(machine)
	if machines.is_empty() and subprojects.is_empty(): delete()

func removeProject(project : Project):
	subprojects.erase(project)
	if machines.is_empty() and subprojects.is_empty(): delete()

func delete():
	while !subprojects.is_empty():
		var toRemove = subprojects.pop_back()
		if toRemove: toRemove.delete()
	while !machines.is_empty():
		var toRemove = machines.pop_back()
		if toRemove: toRemove.delete()
	if parent:
		parent.removeProject(self)
	call_deferred("queue_free")
