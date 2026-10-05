#include "ezeussimulation.h"
#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <chrono>
#include <exception>
using namespace godot;
bool EZeusSimulation::owned = false;
namespace {
Dictionary parse(const std::string& value) {
    const Variant result = JSON::parse_string(String::utf8(value.c_str()));
    return result.get_type() == Variant::DICTIONARY ? Dictionary(result) : Dictionary();
}
}
void EZeusSimulation::_bind_methods() {
    ClassDB::bind_method(D_METHOD("open_city","engine_dir","save_path","language"),&EZeusSimulation::open_city);
    ClassDB::bind_method(D_METHOD("adventures","engine_dir","language"),&EZeusSimulation::adventures);
    ClassDB::bind_method(D_METHOD("open_adventure","engine_dir","kind","ref","language"),&EZeusSimulation::open_adventure);
    ClassDB::bind_method(D_METHOD("adventure_preview","engine_dir","kind","ref","language"),&EZeusSimulation::adventure_preview);
    ClassDB::bind_method(D_METHOD("open_editor","engine_dir","kind","ref","language"),&EZeusSimulation::open_editor);
    ClassDB::bind_method(D_METHOD("new_adventure","engine_dir","name","language"),&EZeusSimulation::new_adventure);
    ClassDB::bind_method(D_METHOD("set_adventures_directory","directory"),&EZeusSimulation::set_adventures_directory);
    ClassDB::bind_method(D_METHOD("advance","delta"),&EZeusSimulation::advance);
    ClassDB::bind_method(D_METHOD("replay","ticks","seed"),&EZeusSimulation::replay,DEFVAL(-1));
    ClassDB::bind_method(D_METHOD("set_save_directory","directory"),&EZeusSimulation::set_save_directory);
    ClassDB::bind_method(D_METHOD("save_city","name"),&EZeusSimulation::save_city);
    ClassDB::bind_method(D_METHOD("snapshot","full"),&EZeusSimulation::snapshot,DEFVAL(false));
    ClassDB::bind_method(D_METHOD("command","command"),&EZeusSimulation::command);
    ClassDB::bind_method(D_METHOD("diagnostics"),&EZeusSimulation::diagnostics);
    ClassDB::bind_method(D_METHOD("enable_test_commands"),&EZeusSimulation::enable_test_commands);
    ClassDB::bind_method(D_METHOD("close_city"),&EZeusSimulation::close_city);
}
EZeusSimulation::~EZeusSimulation() { close_city(); }
Dictionary EZeusSimulation::open_city(const String& engine,const String& save,const String& lang) {
    if(owned && !owner) return parse("{\"error\":\"simulation_already_owned\"}");
    owner=owned=true; last_buildings = Array();
    try {
        return timed_parse(service.open(engine.utf8().get_data(),save.utf8().get_data(),lang.utf8().get_data()));
    } catch(const std::exception&) {
        close_city(); return parse("{\"error\":\"city_load_failed\"}");
    }
}
Dictionary EZeusSimulation::adventures(const String& engine,const String& lang) {
    // Listing reads the shared native language tables, so it waits while another session owns them.
    if(owned) return parse("{\"error\":\"simulation_already_owned\"}");
    try {
        return parse(service.adventures(engine.utf8().get_data(),lang.utf8().get_data()));
    } catch(const std::exception&) {
        return parse("{\"error\":\"adventure_list_failed\"}");
    }
}
Dictionary EZeusSimulation::adventure_preview(const String& engine,const String& kind,const String& ref,const String& lang) {
    if(owned) return parse("{\"error\":\"simulation_already_owned\"}");
    owner=owned=true;
    Dictionary result;
    try { result = parse(service.adventurePreview(engine.utf8().get_data(),kind.utf8().get_data(),ref.utf8().get_data(),lang.utf8().get_data())); }
    catch(const std::exception&) { result = parse("{\"error\":\"adventure_preview_failed\"}"); }
    close_city();
    return result;
}
Dictionary EZeusSimulation::open_adventure(const String& engine,const String& kind,const String& ref,const String& lang) {
    if(owned && !owner) return parse("{\"error\":\"simulation_already_owned\"}");
    owner=owned=true; last_buildings = Array();
    try {
        return timed_parse(service.openAdventure(engine.utf8().get_data(),kind.utf8().get_data(),ref.utf8().get_data(),lang.utf8().get_data()));
    } catch(const std::exception&) {
        close_city(); return parse("{\"error\":\"adventure_load_failed\"}");
    }
}
Dictionary EZeusSimulation::open_editor(const String& engine,const String& kind,const String& ref,const String& lang) {
    if(owned && !owner) return parse("{\"error\":\"simulation_already_owned\"}");
    owner=owned=true; last_buildings = Array();
    try {
        return timed_parse(service.openEditor(engine.utf8().get_data(),kind.utf8().get_data(),ref.utf8().get_data(),lang.utf8().get_data()));
    } catch(const std::exception&) {
        close_city(); return parse("{\"error\":\"adventure_load_failed\"}");
    }
}
Dictionary EZeusSimulation::new_adventure(const String& engine,const String& name,const String& lang) {
    if(owned && !owner) return parse("{\"error\":\"simulation_already_owned\"}");
    owner=owned=true;
    Dictionary result;
    try { result = parse(service.newAdventure(engine.utf8().get_data(),name.utf8().get_data(),lang.utf8().get_data())); }
    catch(const std::exception&) { result = parse("{\"error\":\"save_failed\"}"); }
    close_city();
    return result;
}
void EZeusSimulation::set_adventures_directory(const String& directory) { service.setAdventuresDirectory(directory.utf8().get_data()); }
void EZeusSimulation::advance(double delta) { if(owner) service.advance(delta); }
void EZeusSimulation::set_save_directory(const String& directory) { service.setSaveDirectory(directory.utf8().get_data()); }
Dictionary EZeusSimulation::save_city(const String& name) { return owner ? parse(service.save(name.utf8().get_data())) : parse("{\"error\":\"city_not_loaded\"}"); }
Dictionary EZeusSimulation::replay(int ticks,int64_t seed) { return owner ? parse(service.replay(ticks,seed)) : parse("{\"error\":\"city_not_loaded\"}"); }
Dictionary EZeusSimulation::timed_parse(const std::string& value) {
    const auto began = std::chrono::steady_clock::now();
    Dictionary result = parse(value);
    if(result.has("buildings_unchanged")) {
        result["buildings"] = last_buildings; result["buildings_changed"] = false; result.erase("buildings_unchanged");
    } else if(result.has("buildings") && !result.has("kind")) {
        // Only snapshots carry the city's building list; other answers (the build menu's `buildable`) use the same key.
        last_buildings = result["buildings"]; result["buildings_changed"] = true;
    }
    parse_last = std::chrono::duration<double,std::micro>(std::chrono::steady_clock::now()-began).count();
    parse_max = std::max(parse_max,parse_last); parse_sum += parse_last; ++parse_count;
    return result;
}
Dictionary EZeusSimulation::snapshot(bool full) { return timed_parse(service.snapshot(full)); }
Dictionary EZeusSimulation::command(const String& command) { return timed_parse(service.command(command.utf8().get_data())); }
Dictionary EZeusSimulation::diagnostics() const {
    Dictionary result = parse(service.diagnostics());
    Dictionary wrapper;
    wrapper["parse_last"] = parse_last; wrapper["parse_max"] = parse_max;
    wrapper["parse_mean"] = parse_count ? parse_sum/double(parse_count) : 0.0; wrapper["parses"] = int64_t(parse_count);
    result["wrapper_us"] = wrapper;
    return result;
}
void EZeusSimulation::enable_test_commands() { service.enableTestCommands(); }
void EZeusSimulation::close_city() { last_buildings = Array(); service.close(); if(owner) { owner=false; owned=false; } }
void initialize_ezeus(ModuleInitializationLevel level) { if(level==MODULE_INITIALIZATION_LEVEL_SCENE) GDREGISTER_CLASS(EZeusSimulation); }
extern "C" GDExtensionBool GDE_EXPORT ezeus_library_init(GDExtensionInterfaceGetProcAddress proc,GDExtensionClassLibraryPtr library,GDExtensionInitialization* initialization) {
    GDExtensionBinding::InitObject init(proc,library,initialization);
    init.register_initializer(initialize_ezeus);
    init.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
    return init.init();
}
