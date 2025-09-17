extends Node

var offset = 0

func setStep(step : int):
	var modStep = step - offset
	$Highlight.visible = modStep >= 0 and modStep < 4
	$Highlight.position = Vector2(modStep * 28 + 8, 8)
