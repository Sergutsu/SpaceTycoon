extends SubViewport
class_name ViewportController

func _ready():
	print("ViewportController: Initializing SubViewport")
	print("ViewportController: Size: ", size)
	print("ViewportController: Render target update mode: ", render_target_update_mode)
	
	# Force render update
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	# Ensure proper setup
	handle_input_locally = true
	snap_2d_transforms_to_pixel = false
	snap_2d_vertices_to_pixel = false
	
	print("ViewportController: SubViewport configured")

func _process(_delta):
	# Force render every frame for debugging
	render_target_update_mode = SubViewport.UPDATE_ALWAYS