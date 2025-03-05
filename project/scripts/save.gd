extends Node
var game_file_name: String = generate_timestamped_filename()
var data: Dictionary = {}

func generate_timestamped_filename() -> String:
	var datetime = Time.get_datetime_dict_from_system(false)
	var file_name = str(datetime.year) + "_"
	file_name += str(datetime.month).pad_zeros(2) + "_"
	file_name += str(datetime.day).pad_zeros(2) + "_"
	file_name += str(datetime.hour).pad_zeros(2) + "_"
	file_name += str(datetime.minute).pad_zeros(2) + "_"
	file_name += str(datetime.second).pad_zeros(2) + ".json"
	return file_name

func get_dictionary_from_file(file_name: String) -> Dictionary:
	
	var file = FileAccess.open("user://" + file_name, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			return json.get_data()
	return {}

func change_scene_to_main_scene_file_path() -> void:
	var main_scene_path = ProjectSettings.get_setting("application/run/main_scene")
	get_tree().change_scene_to_file(main_scene_path)
	
func delete_save(file_name: String) -> void:
	var dir = DirAccess.open("user://")
	dir.remove("user://" + file_name)
	
func save_game() -> void:
	var file = FileAccess.open("user://" + game_file_name, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(data, "\t"))
	file.close()

func load_game(file_name: String = generate_timestamped_filename()) -> void:
	game_file_name = file_name
	data = get_dictionary_from_file(file_name)
	call_deferred("change_scene_to_main_scene_file_path")

func get_save_files(exclude_active_file = true) -> Array:
	var dir = DirAccess.open("user://")
	var save_files = []	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json"):
			var file_data = get_dictionary_from_file(file_name)
			file_data["file_name"] = file_name
			file_data["modified_time"] = FileAccess.get_modified_time(file_name)
			save_files.append(file_data)
		file_name = dir.get_next()
	
	dir.list_dir_end()
		
	for i in range(save_files.size()): # Sort By Modifed Time
		for j in range(i + 1, save_files.size()):
			if save_files[i]["modified_time"] > save_files[j]["modified_time"]:
				var tmp = save_files[i]
				save_files[i] = save_files[j]
				save_files[j] = tmp
		
	if exclude_active_file: 
		for i in range(save_files.size()):	
			if save_files[i]["file_name"] == game_file_name:
				save_files.remove_at(i)
				break
		
	return save_files

func _ready() -> void:
	var save_files = get_save_files()
	if save_files.size() > 0:
		load_game(save_files[0]["file_name"])
		
