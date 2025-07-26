@tool
extends EditorPlugin

func _enter_tree():
	# Register the editor globals as a singleton
	add_autoload_singleton("Gizmo3D", "./Classes/gizmo_3d.gd")
	print("Gizmo3D registered")


func _exit_tree():
	# Unregister the editor globals as a singleton
	remove_autoload_singleton("Gizmo3D")
	print("Gizmo3D unregistered")
