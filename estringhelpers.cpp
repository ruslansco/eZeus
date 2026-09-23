#include "estringhelpers.h"

#include <regex>

bool eStringHelpers::replace(std::string& str, const std::string& from,
                             const std::string& to) {
    size_t start_pos = str.find(from);
    if(start_pos == std::string::npos)
        return false;
    str.replace(start_pos, from.length(), to);
    return true;
}

void eStringHelpers::replaceAll(std::string& source,
                                const std::string& from,
                                const std::string& to) {
    std::string newString;
    newString.reserve(source.length());  // avoids a few memory allocations

    std::string::size_type lastPos = 0;
    std::string::size_type findPos;

    while(std::string::npos != (findPos = source.find(from, lastPos)))
    {
        newString.append(source, lastPos, findPos - lastPos);
        newString += to;
        lastPos = findPos + from.length();
    }

    // Care for the rest after last occurrence
    newString += source.substr(lastPos);

    source.swap(newString);
}

std::string eStringHelpers::pathToName(const std::string& path) {
    std::string name;
    for(int i = path.size() - 1; i >= 0; i--) {
        const auto c = path[i];
        if(c == '/') break;
        name = c + name;
    }
    return name;
}

void eStringHelpers::replaceSpecial(std::string& value) {
    value = std::regex_replace(value, std::regex("^@L"), "");
    value = std::regex_replace(value, std::regex("@L"), "\n");
    value = std::regex_replace(value, std::regex("^@P"), "   ");
    value = std::regex_replace(value, std::regex("@P"), "\n\n   ");
}

static const uint16_t sCp1251ToUnicode[128] = {
    0x0402, 0x0403, 0x201A, 0x0453, 0x201E, 0x2026, 0x2020, 0x2021,
    0x20AC, 0x2030, 0x0409, 0x2039, 0x040A, 0x040C, 0x040B, 0x040F,
    0x0452, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
    0xFFFD, 0x2122, 0x0459, 0x203A, 0x045A, 0x045C, 0x045B, 0x045F,
    0x00A0, 0x040E, 0x045E, 0x0408, 0x00A4, 0x0490, 0x00A6, 0x00A7,
    0x0401, 0x00A9, 0x0404, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x0407,
    0x00B0, 0x00B1, 0x0406, 0x0456, 0x0491, 0x00B5, 0x00B6, 0x00B7,
    0x0451, 0x2116, 0x0454, 0x00BB, 0x0458, 0x0405, 0x0455, 0x0457,
    0x0410, 0x0411, 0x0412, 0x0413, 0x0414, 0x0415, 0x0416, 0x0417,
    0x0418, 0x0419, 0x041A, 0x041B, 0x041C, 0x041D, 0x041E, 0x041F,
    0x0420, 0x0421, 0x0422, 0x0423, 0x0424, 0x0425, 0x0426, 0x0427,
    0x0428, 0x0429, 0x042A, 0x042B, 0x042C, 0x042D, 0x042E, 0x042F,
    0x0430, 0x0431, 0x0432, 0x0433, 0x0434, 0x0435, 0x0436, 0x0437,
    0x0438, 0x0439, 0x043A, 0x043B, 0x043C, 0x043D, 0x043E, 0x043F,
    0x0440, 0x0441, 0x0442, 0x0443, 0x0444, 0x0445, 0x0446, 0x0447,
    0x0448, 0x0449, 0x044A, 0x044B, 0x044C, 0x044D, 0x044E, 0x044F,
};

bool eStringHelpers::isValidUtf8(const std::string& str) {
    int remaining = 0;
    for(size_t i = 0; i < str.size(); i++) {
        const unsigned char c = static_cast<unsigned char>(str[i]);
        if(remaining == 0) {
            if((c & 0x80) == 0x00) continue;
            else if((c & 0xE0) == 0xC0) {
                if(c < 0xC2) return false;
                remaining = 1;
            } else if((c & 0xF0) == 0xE0) {
                remaining = 2;
            } else if((c & 0xF8) == 0xF0) {
                remaining = 3;
            } else {
                return false;
            }
        } else {
            if((c & 0xC0) != 0x80) return false;
            remaining--;
        }
    }
    return remaining == 0;
}

std::string eStringHelpers::toUtf8(const std::string& str) {
    if(isValidUtf8(str)) return str;
    std::string result;
    result.reserve(str.size() * 2);
    for(size_t i = 0; i < str.size(); i++) {
        const unsigned char b = static_cast<unsigned char>(str[i]);
        if(b < 0x80) {
            result.push_back(static_cast<char>(b));
        } else {
            const uint16_t cp = sCp1251ToUnicode[b - 0x80];
            if(cp <= 0x7F) {
                result.push_back(static_cast<char>(cp));
            } else if(cp <= 0x7FF) {
                result.push_back(static_cast<char>(0xC0 | (cp >> 6)));
                result.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
            } else {
                result.push_back(static_cast<char>(0xE0 | (cp >> 12)));
                result.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
                result.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
            }
        }
    }
    return result;
}
