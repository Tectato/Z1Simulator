extends Control

const BIT_CHECKBOX = preload("res://Scenes/ProgramInterface/PinCheckbox.tscn")

@onready var dec = $Value/Dec
@onready var bin = $Value/Bin

var parent : Control
var bitToPin = {}
var pinToBit = {}
var bits = []

var currentValue = 0
var maxValue = 2
var updatingDec = false

func serialize():
	var out = {
		"id" : $Header/ID.text,
		"pins" : []
	}
	for bit in bits:
		out["pins"].append(bitToPin[bit].uuid)
	return out

func deserialize(machine : Machine, src):
	$Header/ID.text = src["id"]
	var pins = []
	var uuidManager = machine.uuidManager
	for entry in src["pins"]:
		pins.append(uuidManager.getPart(int(entry)))
	pins.reverse() # Setup expects least significant bit first
	setup(pins)

func setup(pins : Array):
	for pin in pins:
		var newBit = BIT_CHECKBOX.instantiate()
		bits.push_front(newBit)
		bin.add_child(newBit)
		bin.move_child(newBit, 0)
		pin.stateChanged.connect(pinChanged)
		newBit.toggled.connect(checkboxChanged)
		bitToPin[newBit] = pin
		pinToBit[pin] = newBit
	
	updateDec()
	maxValue = pow(2, bits.size())

func pinChanged(pin):
	pinToBit[pin].set_pressed_no_signal(pin.outputState)
	updateDec()

func checkboxChanged(_newState):
	for bit in bits:
		var pin = bitToPin[bit]
		if pin.outputState != bit.button_pressed:
			pin.nudge()
	updateDec()

func updateDec():
	var sum = 0
	for bit in bits:
		sum *= 2
		sum += 1 if bit.button_pressed else 0
	currentValue = sum
	dec.text = str(sum)

func updateBin():
	var checkBit = maxValue / 2
	for bit in bits:
		bit.set_pressed_no_signal(int(checkBit) & currentValue > 0)
		checkBit /= 2
	checkboxChanged(true)

func decTextChanged(new_text: String) -> void:
	if new_text.is_empty():
		dec.text = "0"
		currentValue = 0
	elif !new_text.is_valid_int() or new_text.to_int() >= maxValue:
		dec.text = str(currentValue)
		return
	currentValue = new_text.to_int()
	updateBin()

func _on_delete_pressed() -> void:
	parent.removeValue(self)

func _on_dec_editing_toggled(toggled_on: bool) -> void:
	if !toggled_on: decTextChanged(dec.text)
