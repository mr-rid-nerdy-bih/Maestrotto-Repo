@tool
extends Node

# Drop affected scripts into array
@export var scripts_to_refresh: Array[Script] = []
@warning_ignore("untyped_declaration")
@export_tool_button("Update Enums", "Reload") var run_action = func(): _run()


@warning_ignore("untyped_declaration")
func _run():
	if scripts_to_refresh.is_empty():
		print("Scripts array is empty")
		return
	for script in scripts_to_refresh:
		if script:
			ResourceSaver.save(script)
	print("Re-saved scripts")
