extends Resource
class_name Program

@export var instructions : Array[Instruction]

func _init(instructionList):
	#if instructionList is Array[Instruction]:
	instructions.clear()
	for instruction in instructionList:
		instructions.append(instruction)

func getCode(index : int):
	if !instructions or index < 0 or index >= instructions.size(): return 0
	return instructions[index].type | instructions[index].address
