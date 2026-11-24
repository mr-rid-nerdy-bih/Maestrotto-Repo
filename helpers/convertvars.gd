@tool
extends EditorScript
## Editor tool (File > Run) that renames snake_case variables to camelCase
## across every script outside addons/.

# Set to true first to check the Output console without modifying files.
const DRY_RUN := false
const TARGET_DIR := "res://"

func _run() -> void:
	var gdFiles := get_all_gd_files(TARGET_DIR)
	var varNames := collect_custom_variables(gdFiles)
	
	# Sort longest to shortest to avoid partial-name replacements
	varNames.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	
	print("Found ", varNames.size(), " custom snake_case variables.")
	for i in varNames:
		print(i)
	
	if DRY_RUN:
		print("--- DRY RUN MODE (No files will be changed) ---")
	
	for filePath in gdFiles:
		process_file(filePath, varNames)
		
	if not DRY_RUN:
		EditorInterface.get_resource_filesystem().scan()
		print("Conversion complete! Reload open scripts if prompted.")

## Every .gd file under [param path], recursively, skipping addons and hidden folders.
func get_all_gd_files(path: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(path)
	if not dir:
		return files
		
	dir.list_dir_begin()
	var fileName := dir.get_next()
	while fileName != "":
		if not fileName.begins_with(".") and fileName != "addons":
			var fullPath := path.path_join(fileName)
			if dir.current_is_dir():
				files.append_array(get_all_gd_files(fullPath))
			elif fileName.ends_with(".gd"):
				files.append(fullPath)
		fileName = dir.get_next()
	return files

## Names of every snake_case `var` declared in [param files].
func collect_custom_variables(files: Array[String]) -> Array[String]:
	var foundVars: Dictionary = {}
	var varRegex := RegEx.new()
	# Matches class-level and local 'var' declarations containing underscores
	varRegex.compile("^\\s*(?:@[a-zA-Z0-9_]+(?:\\([^)]*\\))?\\s+)*var\\s+([a-z][a-z0-9]*(?:_[a-z0-9]+)+)\\b")
	
	for filePath in files:
		var file := FileAccess.open(filePath, FileAccess.READ)
		if not file:
			continue
		while not file.eof_reached():
			var line := file.get_line()
			var result := varRegex.search(line)
			if result:
				var varName := result.get_string(1)
				foundVars[varName] = true
				
	var list: Array[String] = []
	list.assign(foundVars.keys())
	return list

## Rewrites one file with every name in [param varNames] converted to camelCase.
func process_file(filePath: String, varNames: Array[String]) -> void:
	var file := FileAccess.open(filePath, FileAccess.READ)
	if not file:
		return
	var originalText := file.get_as_text()
	file.close()
	
	var updatedText := originalText
	for oldName in varNames:
		var newName := oldName.to_camel_case()
		var wordRegex := RegEx.new()
		# Uses word boundaries so partial matches aren't replaced
		wordRegex.compile("\\b" + oldName + "\\b")
		updatedText = wordRegex.sub(updatedText, newName, true)
		
	if updatedText != originalText:
		print("Modified: ", filePath)
		if not DRY_RUN:
			var writeFile := FileAccess.open(filePath, FileAccess.WRITE)
			writeFile.store_string(updatedText)
			writeFile.close()
