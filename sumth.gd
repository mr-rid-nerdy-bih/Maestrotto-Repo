@tool
extends EditorScript

# Set to true to preview changes in Output without modifying files
const DRY_RUN: bool = false
const SCAN_DIR: String = "res://"

func _run() -> void:
	var files: Array[String] = []
	_collect_gd_files(SCAN_DIR, files)
	
	var modified_count: int = 0
	for path: String in files:
		if path.begins_with("res://addons/"):
			continue
		if _process_file(path):
			modified_count += 1
			
	print("Done. %s %d file(s)." % ["Would modify" if DRY_RUN else "Modified", modified_count])
	if not DRY_RUN and modified_count > 0:
		EditorInterface.get_resource_filesystem().scan()

func _collect_gd_files(dir_path: String, out_files: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not file_name.begins_with("."):
			var full_path: String = dir_path.path_join(file_name)
			if dir.current_is_dir():
				_collect_gd_files(full_path, out_files)
			elif file_name.ends_with(".gd"):
				out_files.append(full_path)
		file_name = dir.get_next()

func _process_file(path: String) -> bool:
	var content: String = FileAccess.get_file_as_string(path)
	var lines: PackedStringArray = content.split("\n")
	var changed: bool = false
	
	# Regex for untyped variable initialized with a clear literal/constructor (excludes `null`, `[]`, `{}`)
	var var_regex: RegEx = RegEx.new()
	var_regex.compile("^(\\s*(?:@export\\s+|@onready\\s+|static\\s+)*var\\s+[a-zA-Z_][a-zA-Z0-9_]*)\\s*=\\s*(?!null\\b|\\[\\s*\\]|\\{\\s*\\})(.+)$")
	
	# Regex for functions missing a return type arrow
	var func_regex: RegEx = RegEx.new()
	func_regex.compile("^(\\s*(?:static\\s+)?func\\s+[a-zA-Z_][a-zA-Z0-9_]*\\s*\\([^)]*\\))\\s*:\\s*(#.*)?$")
	
	for i: int in range(lines.size()):
		var line: String = lines[i]
		
		# 1. Convert `var x = <value>` -> `var x := <value>`
		var var_match: RegExMatch = var_regex.search(line)
		if var_match:
			var new_line: String = "%s := %s" % [var_match.get_string(1), var_match.get_string(2)]
			print("[%s:%d] %s  -->  %s" % [path, i + 1, line.strip_edges(), new_line.strip_edges()])
			lines[i] = new_line
			changed = true
			continue
			
		# 2. Add `-> void` if function body has no `return <value>`
		var func_match: RegExMatch = func_regex.search(line)
		if func_match and not _function_returns_value(lines, i):
			var comment: String = (" " + func_match.get_string(2)) if func_match.get_string(2) != "" else ""
			var new_line: String = "%s -> void:%s" % [func_match.get_string(1), comment]
			print("[%s:%d] %s  -->  %s" % [path, i + 1, line.strip_edges(), new_line.strip_edges()])
			lines[i] = new_line
			changed = true
			
	if changed and not DRY_RUN:
		var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		f.store_string("\n".join(lines))
		
	return changed

func _function_returns_value(lines: PackedStringArray, func_line_idx: int) -> bool:
	var base_indent: int = lines[func_line_idx].length() - lines[func_line_idx].lstrip(" \t").length()
	for j: int in range(func_line_idx + 1, lines.size()):
		var raw: String = lines[j]
		var trimmed: String = raw.strip_edges()
		if trimmed == "" or trimmed.begins_with("#"):
			continue
		var indent: int = raw.length() - raw.lstrip(" \t").length()
		if indent <= base_indent:
			break
		if trimmed.begins_with("return ") and not trimmed.begins_with("return #"):
			return true
	return false
