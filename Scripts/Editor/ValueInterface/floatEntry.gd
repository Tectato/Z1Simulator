extends FoldableContainer

@onready var idBox = $VBox/Header/ID

var parent : Control

var sign : Pin
var exponent : ValueEntry
var mantissa : ValueEntry

var v_sign = false
var v_exponent = 0
var v_mantissa = 0.0

func serialize():
	var out = {
		"id": idBox.text,
		"folded": folded,
		"exponent": [exponent.parent.machine.uuid, exponent.idBox.text],
		"mantissa": [mantissa.parent.machine.uuid, mantissa.idBox.text]
	}
	if sign:
		out["sign"] = [sign.getMachine().uuid, sign.uuid]
	return out

func deserialize(src : Dictionary):
	idBox.text = src["id"]
	var exponentEntry = parent.parent.findValue(src["exponent"][0], src["exponent"][1])
	var mantissaEntry = parent.parent.findValue(src["mantissa"][0], src["mantissa"][1])
	if !exponentEntry or !mantissaEntry:
		print("Couldn't find values of compound value!")
		queue_free()
	var signPin
	if src.has("sign"):
		var machine = Global.workspace.uuidManager.getPart(int(src["sign"][0]))
		if machine:
			signPin = machine.uuidManager.getPart(int(src["sign"][1]))
	setup(exponentEntry, mantissaEntry, [signPin] if signPin else null)
	if src.has("folded") and bool(src["folded"]): fold()

func setup(valueA, valueB, selection : Array):
	#for child in $VBox/Header.get_children():
		#add_title_bar_control(child)
	add_title_bar_control($VBox/Header)
	
	if !selection.is_empty() and selection[0] is Pin:
		sign = selection[0]
	if valueA.isFloat:
		mantissa = valueA
		exponent = valueB
	else:
		mantissa = valueB
		exponent = valueA
	if sign:
		sign.stateChanged.connect(newSign)
		v_sign = sign.outputState
	
	title = "[" + ("+/-, " if sign else "") + exponent.idBox.text + ", " + mantissa.idBox.text + "]"
	
	exponent.valueChanged.connect(newExponent)
	v_exponent = exponent.currentValue
	mantissa.floatChanged.connect(newMantissa)
	mantissa.updateFloat()
	
func newSign(pin):
	v_sign = bool(sign.outputState)
	updateValue()

func newExponent(value):
	v_exponent = int(value)
	updateValue()

func newMantissa(value):
	v_mantissa = float(value)
	updateValue()

func updateValue():
	var value = (-1 if v_sign else 1) * pow(2, v_exponent) * v_mantissa
	if abs(value) > 1000000:
		var exp = str(value).split(".")[0].length() - 1
		var dec = value / pow(10,exp)
		$VBox/Value/Label.text = "{dec}e{exp}".format({"dec":("%1.2f" % dec), "exp":str(exp)})
	else:
		var text = ("%0.10f" % value).rstrip("0")
		if text.ends_with("."): text += "0"
		$VBox/Value/Label.text = text

func _on_delete_pressed() -> void:
	parent.removeValue(self)
