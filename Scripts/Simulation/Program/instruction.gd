extends Resource
class_name Instruction

enum code {
	NoOp		= 0b00000000,
	Input 		= 0b01000001,
	Output 		= 0b01000110,
	Add 		= 0b01000011,
	Subtract 	= 0b01000010,
	Multiply 	= 0b01000100,
	Divide 		= 0b01000101,
	Read 		= 0b11000000,
	Write 		= 0b10000000}

@export var type : code
@export var address : int

func _init(type : code, address : int) -> void:
	self.type = type
	self.address = address

func serialize():
	return type | address

func deserialize(char : int):
	if(char & 0b10000000):
		type = char & 0b11000000
		address = char & 0b00111111
	else:
		type = char

static func indexToCode(id : int):
	match(id):
		0: return code.NoOp
		1: return code.Input
		2: return code.Output
		3: return code.Add
		4: return code.Subtract
		5: return code.Multiply
		6: return code.Divide
		7: return code.Read
		8: return code.Write

static func codeToIndex(c : code):
	match(c):
		code.NoOp: return 0
		code.Input: return 1
		code.Output: return 2
		code.Add: return 3
		code.Subtract: return 4
		code.Multiply: return 5
		code.Divide: return 6
		code.Read: return 7
		code.Write: return 8

func _to_string() -> String:
	var out = ""
	match(type):
		code.NoOp: out = "No Op"
		code.Input: out = "Input"
		code.Output: out = "Output"
		code.Add: out = "Add"
		code.Subtract: out = "Subtract"
		code.Multiply: out = "Multiply"
		code.Divide: out = "Divide"
		code.Read: out = "Read from "
		code.Write: out = "Write to "
	if out.ends_with(" "): out += str(address)
	return out
