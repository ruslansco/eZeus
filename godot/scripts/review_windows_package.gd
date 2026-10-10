extends SceneTree
# Private package orchestrator. Children own separate scratch saves/preferences.
# No Python/compiler is required on the test PC. Only owned PIDs may be stopped.
const Settings = preload("res://scripts/user_settings.gd")
var results := ""
var scratch := ""
var protected := {}
var phases := []
var okay := true

func _initialize() -> void:
	scratch = OS.get_environment("EZEUS_PACKAGE_SCRATCH")
	results = OS.get_environment("EZEUS_PACKAGE_RESULTS")
	if scratch.is_empty() or results.is_empty():
		printerr("Package runner requires its private scratch/results paths."); quit(1); return
	Engine.set_meta("ezeus_settings_path",scratch.path_join("parent-settings.cfg"))
	Engine.set_meta("ezeus_save_directory",scratch.path_join("parent-saves"))
	call_deferred("run")

func hash_file(path: String) -> String:
	return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "missing"

func resident_mib(pid: int) -> float:
	var output := []
	if OS.get_name() == "Windows":
		if OS.execute("tasklist",["/fi","PID eq %d"%pid,"/fo","csv","/nh"],output,true)!=0: return -1
		for line in str(output[0]).split("\n"):
			var fields := line.split('"')
			if fields.size()<10 or int(fields[3])!=pid: continue
			var digits := ""
			for character in fields[-2]:
				if character in "0123456789": digits+=character
			if not digits.is_empty(): return float(digits)/1024.0
	else:
		if OS.execute("ps",["-o","rss=","-p",str(pid)],output,true)==0: return float(str(output[0]).strip_edges())/1024.0
	return -1

func run_child(label: String, script: String, headless: bool, timeout: float) -> bool:
	var directory := scratch.path_join(label)
	DirAccess.make_dir_recursive_absolute(directory)
	OS.set_environment("EZEUS_REVIEW_SETTINGS_PATH",directory.path_join("settings.cfg"))
	OS.set_environment("EZEUS_REVIEW_SAVE_DIRECTORY",directory.path_join("saves"))
	OS.set_environment("EZEUS_PERFORMANCE_REPORT",results.path_join("performance.json"))
	OS.set_environment("EZEUS_SEED","12345")
	var log := results.path_join(label+".log")
	var args := PackedStringArray(["--path",ProjectSettings.globalize_path("res://"),"--script",script,"--log-file",log])
	if headless: args.append("--headless")
	else: args.append_array(["--rendering-method","mobile"])
	args.append_array(["--","--silent","--lang=en"])
	print("TEST_PACKAGE_STAGE ",label)
	var pid := OS.create_process(OS.get_executable_path(),args)
	if pid <= 0: return false
	var began := Time.get_ticks_msec()
	var next_memory := began
	var memory := []
	var failed := false
	var finished := false
	var marker := "SAVE_RELIABILITY_VALIDATION PASS" if label == "save-recovery" else "RELEASE_PERFORMANCE_VALIDATION PASS"
	while OS.is_process_running(pid):
		await create_timer(.2).timeout
		var text := FileAccess.get_file_as_string(log) if FileAccess.file_exists(log) else ""
		if text.contains("SCRIPT ERROR:") or text.contains("ERROR:"):
			failed=true; OS.kill(pid); break
		if text.contains(marker): finished=true
		var now := Time.get_ticks_msec()
		if not finished and now >= next_memory:
			var used := resident_mib(pid)
			if used >= 0: memory.append(used)
			next_memory = now+2000
		if now-began>timeout*1000:
			failed=true; OS.kill(pid); break
	var text := FileAccess.get_file_as_string(log) if FileAccess.file_exists(log) else ""
	var verified := not failed and text.contains(marker) and not text.contains("ERROR:")
	phases.append({"label":label,"passed":verified,"seconds":(Time.get_ticks_msec()-began)/1000.0,"resident_memory_mib":{"available":not memory.is_empty(),"peak":memory.max() if not memory.is_empty() else null,"samples":memory.size(),"scope":"owned child working set; excludes load-probe child and other applications"}})
	print("TEST_PACKAGE_STAGE_RESULT ",label," ","PASS" if verified else "FAIL")
	return verified

func run() -> void:
	DirAccess.make_dir_recursive_absolute(results)
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	for path in [engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"),engine.path_join("settings.txt"),engine.get_base_dir().path_join("settings.txt"),ProjectSettings.globalize_path("user://settings.cfg")]: protected[path]=hash_file(path)
	okay=await run_child("save-recovery","res://scripts/validate_save_reliability.gd",true,240)
	if okay: okay=await run_child("performance","res://scripts/review_release_performance.gd",false,360)
	var unchanged := true
	for path in protected:
		if hash_file(path)!=protected[path]: unchanged=false
	okay=okay and unchanged
	var performance_path:=results.path_join("performance.json")
	if FileAccess.file_exists(performance_path):
		var performance = JSON.parse_string(FileAccess.get_file_as_string(performance_path))
		if performance is Dictionary:
			performance["harness_verified"]=okay
			performance["passed"]=bool(performance.get("passed",false)) and okay
			if phases.size()>1:performance["process_resident_memory_mib"]=phases[-1].resident_memory_mib
			var output:=FileAccess.open(performance_path,FileAccess.WRITE);output.store_string(JSON.stringify(performance,"\t"));output.close()
	var report:={"schema":1,"passed":okay,"protected_files_unchanged":unchanged,"phases":phases,"windows_execution":OS.get_name()=="Windows","os":OS.get_name(),"godot":Engine.get_version_info()}
	var output:=FileAccess.open(results.path_join("test-summary.json"),FileAccess.WRITE);output.store_string(JSON.stringify(report,"\t"));output.close()
	print("TEST_PACKAGE_VALIDATION ","PASS" if okay else "FAIL")
	quit(0 if okay else 1)
