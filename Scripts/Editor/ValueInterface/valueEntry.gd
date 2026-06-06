extends Control

const BIT_CHECKBOX = preload("res://Scenes/ProgramInterface/PinCheckbox.tscn")

@onready var dec = $Value/Dec
@onready var bin = $Value/Bin
@onready var flt = $FloatValue/Numeric
@onready var radixSlider = $FloatValue/RadixSlider

var parent : Control
var bitToPin = {}
var pinToBit = {}
var bits = []

var currentValue = 0
var maxValue = 2
var minValue = 0
var updatingDec = false

var isSigned = false
var isFloat = false
var radixPoint = 0

var updateScheduled = false
var pinUpdateTimeout = false

func serialize():
	var out = {
		"id" : $Header/ID.text,
		"pins" : []
	}
	for bit in bits:
		out["pins"].append(bitToPin[bit].uuid)
	if isSigned: out["signed"] = true
	if isFloat:
		out["float"] = true
		out["radix"] = int(radixSlider.max_value - radixSlider.value)
	return out

func deserialize(machine : Machine, src):
	$Header/ID.text = src["id"]
	var pins = []
	var uuidManager = machine.uuidManager
	for entry in src["pins"]:
		pins.append(uuidManager.getPart(int(entry)))
	pins.reverse() # Setup expects least significant bit first
	if src.has("signed"): isSigned = bool(src["signed"])
	$Header/SignToggle.set_pressed_no_signal(isSigned)
	if src.has("float"):
		isFloat = bool(src["float"])
		if src.has("radix"):
			radixSlider.set_value_no_signal(pins.size() - int(src["radix"]))
			radixPoint = int(src["radix"])
	$Header/FloatToggle.set_pressed_no_signal(isFloat)
	$FloatValue.visible = isFloat
	
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
	radixSlider.custom_minimum_size = Vector2(pins.size() * 28, 0)
	radixSlider.max_value = pins.size()
	
	updateDec()
	maxValue = pow(2, bits.size() - (1 if isSigned else 0))
	minValue = -pow(2, bits.size() - 1) if isSigned else 0
	dec.min_value = minValue
	dec.max_value = maxValue - 1

func pinChanged(pin):
	pinToBit[pin].set_pressed_no_signal(pin.outputState)
	updateDec()

func checkboxChanged(_newState):
	for bit in bits:
		var pin = bitToPin[bit]
		if pin.outputState != bit.button_pressed:
			pin.nudge()
	if !updatingDec:
		updateDec()

func updateDec():
	if updateScheduled: return
	updateScheduled = true
	call_deferred("executeUpdateDec")

func executeUpdateDec():
	updateScheduled = false
	var topBit = true
	var sum = 0
	for bit in bits:
		sum *= 2
		sum += 1 if bit.button_pressed else 0
		if topBit and isSigned:
			sum = -sum
			topBit = false
	currentValue = sum
	#dec.text = str(sum)
	dec.set_value_no_signal(currentValue)
	if isFloat: updateFloat()

func updateBin():
	if pinUpdateTimeout: return
	pinUpdateTimeout = true
	await get_tree().create_timer(Workspace.pinTravel).timeout
	pinUpdateTimeout = false
	var checkBit = 1 << (bits.size() - 1)
	for bit in bits:
		bit.set_pressed_no_signal(int(checkBit) & currentValue > 0)
		checkBit /= 2
	checkboxChanged(true)

func updateFloat():
	var floatValue = 0
	#if isSigned and bits[0].button_pressed:
		#floatValue = float(currentValue - (1 << (bits.size()-2))) / (1 << radixPoint)
	#else:
		#floatValue = float(currentValue) / (1 << radixPoint)
	floatValue = float(currentValue) / (1 << radixPoint)
	#if isSigned and bits[0].button_pressed:
		#var temp = 1 << (bits.size()-1) - radixPoint
		#floatValue -= (1 << ((bits.size()-1) - radixPoint))
	flt.text = ("%0.4f" % floatValue)

#func decTextChanged(new_text: String) -> void:
	#if new_text.is_empty():
		#dec.text = "0"
		#currentValue = 0
	#elif !new_text.is_valid_int() or new_text.to_int() >= maxValue:
		#dec.text = str(currentValue)
		#return
	#currentValue = new_text.to_int()
	#updateBin()

func _on_delete_pressed() -> void:
	parent.removeValue(self)

#func _on_dec_editing_toggled(toggled_on: bool) -> void:
	#if !toggled_on: decTextChanged(dec.text)

func _on_sign_toggle_toggled(toggled_on: bool) -> void:
	isSigned = toggled_on
	maxValue = pow(2, bits.size() - (1 if isSigned else 0))
	minValue = -pow(2, bits.size() - 1) if isSigned else 0
	dec.min_value = minValue
	dec.max_value = maxValue - 1
	updateDec()

func _on_float_toggle_toggled(toggled_on: bool) -> void:
	isFloat = toggled_on
	$FloatValue.visible = isFloat
	updateFloat()

func _on_radix_slider_drag_ended(value_changed: bool) -> void:
	radixPoint = int(radixSlider.max_value - radixSlider.value)
	updateFloat()

func _on_dec_value_changed(value: float) -> void:
	if value >= maxValue or value < minValue:
		dec.set_value_no_signal(currentValue)
	else:
		updatingDec = true
		currentValue = int(value)
		updateBin()
		updatingDec = false
