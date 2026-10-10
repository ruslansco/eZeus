#pragma once
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include "presentation/esimulationservice.h"
namespace godot {
class EZeusSimulation : public RefCounted {
    GDCLASS(EZeusSimulation,RefCounted)
    eSimulationService service;
    static bool owned;
    bool owner = false;
    // Godot-side cost of turning the native JSON text into a Dictionary (microseconds).
    double parse_last = 0, parse_max = 0, parse_sum = 0;
    uint64_t parse_count = 0;
    // The service omits the building list when nothing changed; every consumer still
    // sees a complete `buildings` Array (the same shared object while it is unchanged).
    Array last_buildings;
    Dictionary timed_parse(const std::string& value);
protected:
    static void _bind_methods();
public:
    ~EZeusSimulation();
    Dictionary open_city(const String& engine, const String& save, const String& lang);
    // New game: the listed adventures, and one of them opened paused (kind "pak" or "folder", and its reference).
    Dictionary adventures(const String& engine, const String& lang);
    Dictionary adventure_preview(const String& engine, const String& kind, const String& ref, const String& lang);
    Dictionary open_adventure(const String& engine, const String& kind, const String& ref, const String& lang);
    // The adventure editor: an adventure opened for editing, a new one made, and (validators) another adventures folder.
    Dictionary open_editor(const String& engine, const String& kind, const String& ref, const String& lang);
    Dictionary new_adventure(const String& engine, const String& name, const String& lang);
    void set_adventures_directory(const String& directory);
    void advance(double delta);
    Dictionary replay(int ticks, int64_t seed);
    void set_save_directory(const String& directory);
    Dictionary save_city(const String& name,const Dictionary& view);
    Dictionary check_save(const String& path);
    Dictionary save_info(const String& path);
    Dictionary snapshot(bool full);
    Dictionary command(const String& command);
    Dictionary diagnostics() const;
    // Validators only: allows the `test_win` command.
    void enable_test_commands();
    void close_city();
};
}
