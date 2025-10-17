extends Window

func _ready() -> void:
	close_requested.connect(hide)
	size_changed.connect(adjustChildren)
	adjustChildren()

func adjustChildren():
	for child in get_children():
		if child is Control:
			child.size = size
