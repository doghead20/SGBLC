extends StaticBody3D

var to_outline = "chest"
var outline_color = 0.3


func _ready():
	pass
	
	
var original_colors = {}

func _store_original_colors(root: Node3D):
	for child in root.get_children():
		if child is MeshInstance3D:
			var mat = child.get_active_material(0)
			if mat and mat is StandardMaterial3D:
				# Store original color by mesh unique name
				original_colors[child.get_path()] = mat.albedo_color
		elif child is Node3D:
			_store_original_colors(child)

func _apply_highlight(root: Node3D, amount: float):
	for child in root.get_children():
		if child is MeshInstance3D:
			var mat = child.get_active_material(0)
			if mat and mat is StandardMaterial3D:
				# Duplicate material so we don't overwrite original resource
				var new_mat = mat.duplicate()
				var orig_color = original_colors.get(child.get_path(), Color(1,1,1))
				
				# Lighten color, clamp max 1.0
				var color = Color(
					orig_color.r + amount,
					orig_color.g + amount,
					orig_color.b + amount,
					orig_color.a
				)
				new_mat.albedo_color = color
				child.set_surface_override_material(0, new_mat)
		elif child is Node3D:
			_apply_highlight(child, amount)

func highlight(root: Node3D, amount: float = 0.7):
	print("high")
	if original_colors.size() == 0:
		_store_original_colors(root)
	_apply_highlight(root, amount)

func remove_highlight(root: Node3D):
	print("stop")
	for child in root.get_children():
		if child is MeshInstance3D:
			var orig_color = original_colors.get(child.get_path(), null)
			if orig_color:
				var mat = child.get_active_material(0)
				if mat and mat is StandardMaterial3D:
					var new_mat = mat.duplicate()
					new_mat.albedo_color = orig_color
					child.set_surface_override_material(0, new_mat)
		elif child is Node3D:
			remove_highlight(child)
	# Clear original colors if you want to allow new highlighting cycle
	# original_colors.clear()
