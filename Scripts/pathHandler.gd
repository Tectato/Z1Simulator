extends Node

var projectDir = ""
var projectArray = []

func setProjectDir(path : String):
	projectDir = ProjectSettings.globalize_path(path).get_base_dir().replace("\\","/") + "/"
	projectArray = toDirArray(projectDir)

func toRelativePath(path : String):
	if path.is_relative_path():
		return path
	var absolute = ProjectSettings.globalize_path(path.replace("\\","/"))
	var absoluteArray = toDirArray(absolute)
	if absolute.begins_with(projectDir):
		return absolute.trim_prefix(projectDir)
	else:
		var outputArr = []
		var matching = true
		for i in range(absoluteArray.size()):
			if matching and absoluteArray[i] != projectArray[i]:
				matching = false
				for j in range(i,projectArray.size()):
					outputArr.append("..")
			if !matching:
				outputArr.append(absoluteArray[i])
		return arrayToPath(outputArr)

func toAbsolutePath(path : String):
	if path.is_absolute_path():
		return path
	var file = path.get_file()
	var pathArr = toDirArray(path.get_base_dir())
	var outPath = []
	outPath.append_array(projectArray.duplicate())
	for part in pathArr:
		if part == "..":
			outPath.pop_back()
		else:
			outPath.append(part)
	return arrayToPath(outPath) + "/" + file

func toDirArray(path : String):
	var out = []
	out.append_array(path.replace("\\","/").trim_suffix("/").split("/"))
	while !out.is_empty() and out.back().length() == 0:
		out.pop_back()
	return out

func arrayToPath(arr : Array):
	var out = ""
	for part in arr:
		out += part + "/"
	return out.trim_suffix("/")
