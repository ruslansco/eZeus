#include "eadventurelist.h"

#include <filesystem>
#include <fstream>
#include <functional>
#include <algorithm>

#include "estringhelpers.h"
#include "elanguage.h"
#include "egamedir.h"
#include "pak/zeusfile.h"
#include "pak/epakhelpers.h"

namespace fs = std::filesystem;

namespace eAdventureList {
bool readPakGlossary(const std::string& filename,
                     eCampaignGlossary& glossary) {
    glossary.fIsPak = true;
    const auto name = eStringHelpers::pathToName(filename);
//    const bool test = name.find("Test") != name.npos;
//    if(test && name != "Test6.pak") return false;
    const auto ext = name.substr(name.size() - 3);
    if(ext != "pak") return false;
    std::string txtFile = filename.substr(0, filename.size() - 3) + "txt";
    if(eLanguage::language() == "ru") {
        const auto ruTxtFile = filename.substr(0, filename.size() - 3) + "_ru.txt";
        std::ifstream ruFile(ruTxtFile);
        if(ruFile.good()) {
            txtFile = ruTxtFile;
        }
    }
    glossary.fPakPath = filename;
    std::ifstream file(txtFile);
    ZeusFile in(filename);
    in.readVersion();
    const auto version = in.version();
    const bool poseidon = version == eZeusFileVersion::poseidon_2_0;
    uint8_t bitmapId;
    if(poseidon) {
        in.seek(836249);
    } else {
        in.seek(835185);
    }
    bitmapId = in.readUByte();
    glossary.fBitmap = ePakHelpers::pakBitmapIdConvert(bitmapId);
    if(file.good()) {
        std::map<std::string, std::string> map;
        const bool r = eCampaign::sLoadStrings(txtFile, map);
        if(!r) return false;
        glossary.fTitle = map["Adventure_Title"];
        glossary.fIntroduction = map["Adventure_Introduction"];
        glossary.fComplete = map["Adventure_Complete"];
    } else {
        const std::vector<char> special = {'@', '[', '&', ']',
                                           '{', '}', '^', '#'};
        bool found = false;
        for(const auto c : special) {
            const auto pos = std::find(name.begin(), name.end(), c);
            if(pos != name.end()) {
                found = true;
                break;
            }
        }
        if(!found) return false;
        in.seek(35648);
        const auto briefId = in.readUShort();

        const auto brief = eLanguage::zeusMM(briefId);
        glossary.fTitle = brief.fTitle;
        glossary.fIntroduction = brief.fContent;
    }
    return true;
}

std::vector<eCampaignGlossary> scan() {
    std::vector<eCampaignGlossary> glossaries;
    {
        const auto folder = eGameDir::adventuresDir();
        std::error_code ec;
        fs::create_directories(folder, ec);
        for(const auto& entry : fs::directory_iterator(folder, ec)) {
            const bool dir = entry.is_directory();
            if(!dir) continue;
            const auto path = entry.path();
            const std::string pathStr = path.u8string();
            const auto name = eStringHelpers::pathToName(pathStr);
            eCampaignGlossary glossary;
            const bool r = eCampaign::sReadGlossary(name, glossary);
            if(r) glossaries.push_back(glossary);
        }
    }
    {
        std::function<void(std::string)> procesFolder;
        procesFolder = [&](const std::string& folder) {
            std::error_code ec;
            for(const auto& entry : fs::directory_iterator(folder, ec)) {
                const bool dir = entry.is_directory();
                const auto path = entry.path();
                const std::string pathStr = path.u8string();
                if(dir) {
                    procesFolder(pathStr);
                    continue;
                }
                if(pathStr.size() < 3) continue;
                const auto ext = pathStr.substr(pathStr.size() - 3);
                if(ext != "pak") continue;
                eCampaignGlossary glossary;
                const bool r = readPakGlossary(pathStr, glossary);
                if(r) glossaries.push_back(glossary);
            }
        };
        const auto folder = eGameDir::pakAdventuresDir();
        procesFolder(folder);
    }
    return glossaries;
}
}
