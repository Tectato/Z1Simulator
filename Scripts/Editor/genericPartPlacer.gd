extends TextureButton

@export var part : PackedScene

func _ready() -> void:
	call_deferred("lateReady")

func lateReady():
	pressed.connect(Global.editor.addPeripheral.bind(part))
