extends Node
var game_file_path: String = "user://save_data"
var data: Dictionary = {}

# unfinished

func save_game() -> void:
	var file = FileAccess.open(game_file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func new_game() -> void:
	var datetime = Time.get_datetime_dict_from_system(false)
	game_file_path = "user://"
	game_file_path += str(datetime.year) + "_"
	game_file_path += str(datetime.month).pad_zeros(2) + "_"
	game_file_path += str(datetime.day).pad_zeros(2) + "_"
	game_file_path += str(datetime.hour).pad_zeros(2) + "_"
	game_file_path += str(datetime.minute).pad_zeros(2) + "_"
	game_file_path += str(datetime.second).pad_zeros(2) + ".json"
	save_game()

func load_game() -> void:
	var file = FileAccess.open(game_file_path, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			data = json.get_data()
		else:
			data = {}
		file.close()
	else:
		data = {}
	
	if data.has("tree") and data["tree"] and get_tree():
		get_tree().call_deferred("reload_current_scene")

func delete_game(file_name: String) -> void:
	var dir = DirAccess.open("user://")
	if dir:
		var file_path = "user://" + file_name
		if dir.file_exists(file_path):
			dir.remove(file_path)

func get_save_files() -> Array:
	var dir = DirAccess.open("user://")
	var save_files = []
	if dir != null:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var file_path = "user://" + file_name
				var modified_time = FileAccess.get_modified_time(file_path)
				var insertion_index = 0
				for i in range(save_files.size()):
					if modified_time < FileAccess.get_modified_time("user://" + save_files[i]):
						break
					insertion_index += 1
				save_files.insert(insertion_index, file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	save_files.reverse()
	return save_files

func _init() -> void:
	
	#var save_files = get_save_files(); 
	##print(save_files)
	#if (save_files.size() == 0):
		#new_game()
	#else:
		#game_file_path = save_files[0]
	load_game()
