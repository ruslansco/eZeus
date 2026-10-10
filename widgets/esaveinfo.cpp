#include "esaveinfo.h"

#include "elanguage.h"

#include <algorithm>
#include <chrono>
#include <filesystem>

namespace fs = std::filesystem;

namespace {
std::time_t toTimeT(const fs::file_time_type tp) {
    using namespace std::chrono;
    const auto sctp = time_point_cast<system_clock::duration>(
                          tp - fs::file_time_type::clock::now() + system_clock::now());
    return system_clock::to_time_t(sctp);
}

std::string tr(const std::string& key, const std::string& fallback) {
    const auto& s = eLanguage::text(key);
    return s.empty() ? fallback : s;
}

std::string withNumber(std::string s, const long n) {
    const auto pos = s.find("%1");
    if(pos != std::string::npos) s.replace(pos, 2, std::to_string(n));
    return s;
}
}

std::vector<eSaveInfo> eSaveInfo::sList(const std::string& folder) {
    std::vector<eSaveInfo> result;
    std::error_code ec;
    if(!fs::exists(folder, ec)) return result;
    for(const auto& entry : fs::directory_iterator(folder, ec)) {
        const auto path = entry.path();
        if(path.extension() != ".ez") continue;
        std::error_code tec;
        const auto lwt = fs::last_write_time(path, tec);
        if(tec) continue;
        eSaveInfo i;
        i.fName = path.stem().u8string();
        i.fPath = path.u8string();
        i.fTime = toTimeT(lwt);
        result.push_back(i);
    }
    std::sort(result.begin(), result.end(), [](const eSaveInfo& a, const eSaveInfo& b) {
        return a.fTime > b.fTime;
    });
    return result;
}

std::string eSaveInfo::sAgo(const std::time_t t) {
    const std::time_t now = std::time(nullptr);
    const long s = static_cast<long>(std::max<std::time_t>(0, now - t));
    if(s < 60) return tr("menu_just_now", "just now");
    if(s < 3600) return withNumber(tr("menu_minutes_ago", "%1 min ago"), s/60);
    if(s < 86400) return withNumber(tr("menu_hours_ago", "%1 h ago"), s/3600);
    if(s < 2*86400) return tr("menu_yesterday", "yesterday");
    if(s < 30*86400) return withNumber(tr("menu_days_ago", "%1 d ago"), s/86400);
    return sStamp(t).substr(0, 10);
}

std::string eSaveInfo::sStamp(const std::time_t t) {
    char buf[32];
    std::tm tm{};
#ifdef _WIN32
    if(localtime_s(&tm, &t) != 0) return "";
#else
    if(!localtime_r(&t, &tm)) return "";
#endif
    std::strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M", &tm);
    return buf;
}
