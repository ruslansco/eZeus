#ifndef ESAVEINFO_H
#define ESAVEINFO_H

#include <ctime>
#include <string>
#include <vector>

// A saved city (.ez) in a leader's save folder.
struct eSaveInfo {
    std::string fName; // file stem, as typed by the player
    std::string fPath;
    std::time_t fTime = 0; // last modification

    // .ez files in folder, newest first.
    static std::vector<eSaveInfo> sList(const std::string& folder);
    // "just now", "12 min ago", "3 h ago", "yesterday", "4 d ago" or a date
    // (localized through text/language*.txt).
    static std::string sAgo(const std::time_t t);
    // "2026-09-25 14:32"
    static std::string sStamp(const std::time_t t);
};

#endif // ESAVEINFO_H
