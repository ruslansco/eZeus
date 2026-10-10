#ifndef EREADSTREAM_H
#define EREADSTREAM_H

#define SDL_MAIN_HANDLED
#include <SDL2/SDL.h>
#include <string>
#include <functional>
#include <map>
#include <fstream>
#include <cstdint>
#include <cstring>
#include <cassert>
#include <stdexcept>
#include <limits>

#include "pointers/estdpointer.h"
#include "efileformat.h"

class eTile;
class eBuilding;
class eCharacter;
class eCharacterAction;
class eGameBoard;
class eWalkableObject;
class eHasResourceObject;
class eCharacterActionFunction;
class eGodAct;
class eObsticleHandler;
class eDirectionLastUseTime;
class eWorldCity;
class eBanner;
class eSoldierBanner;
class eGameEvent;
class eWorldBoard;
class eInvasionHandler;

using eDirectionTimes = std::map<eTile*, eDirectionLastUseTime>;

class eReadSource {
public:
    eReadSource(std::ifstream* const file, size_t limit = std::numeric_limits<size_t>::max()) : fFile(file) {
        const auto position=file->tellg();
        file->seekg(0,std::ios::end);const auto end=file->tellg();file->seekg(position);
        fFilePos=position>=0?size_t(position):0;fFileEnd=end>=0?size_t(end):0;
        if(limit<fFileEnd-fFilePos)fFileEnd=fFilePos+limit;
    }
    eReadSource(void* mem) :
        fMem(mem) {}

    inline size_t read(void* const data, const size_t len) {
        assert(fFile || fMem);
        if(fFile) {
            if(len>remaining())throw std::runtime_error("truncated native stream");
            fFile->read(static_cast<char*>(data), len);
            if(size_t(fFile->gcount())!=len)throw std::runtime_error("unreadable native stream");
            fFilePos+=len;
            return len;
        } else if(fMem) {
            std::memcpy(data, static_cast<char*>(fMem) + fMemPos, len);
            fMemPos += len;
            return len;
        }
        return 0;
    }
    size_t remaining() const {
        if(!fFile)return std::numeric_limits<size_t>::max();
        return fFileEnd>=fFilePos?fFileEnd-fFilePos:0;
    }
private:
    std::ifstream* fFile = nullptr;
    void* fMem = nullptr;
    size_t fMemPos = 0;
    size_t fFilePos=0,fFileEnd=0;
};

class eReadStream {
public:
    eReadStream(const eReadSource& src);

    void readFormat();

    inline size_t read(void* const data, const size_t len) {
        return mSrc.read(data, len);
    }

    inline eReadStream& operator>>(bool& val) {
        read(&val, sizeof(bool));
        return *this;
    }

    inline eReadStream& operator>>(unsigned char& val) {
        read(&val, sizeof(unsigned char));
        return *this;
    }

    inline eReadStream& operator>>(char& val) {
        read(&val, sizeof(char));
        return *this;
    }

    inline eReadStream& operator>>(float& val) {
        read(&val, sizeof(float));
        return *this;
    }

    inline eReadStream& operator>>(double& val) {
        read(&val, sizeof(double));
        return *this;
    }

    inline eReadStream& operator>>(int32_t& val) {
        read(&val, sizeof(int32_t));
        return *this;
    }

    template <typename T>
    inline eReadStream& operator>>(T& val) {
        int32_t val32_t;
        read(&val32_t, sizeof(int32_t));
        val = static_cast<T>(val32_t);
        return *this;
    }

    template <typename T>
    inline eReadStream& operator>>(std::vector<T>& val) {
        int size;
        *this >> size;
        if(size<0 || size_t(size)>mSrc.remaining())throw std::runtime_error("invalid native list length");
        for(int i = 0; i < size; i++) {
            T& t = val.emplace_back();
            *this >> t;
        }
        return *this;
    }

    inline eReadStream& operator>>(SDL_Rect& val) {
        *this >> val.x;
        *this >> val.y;
        *this >> val.w;
        *this >> val.h;
        return *this;
    }

    inline eReadStream& operator>>(std::string& val) {
        int32_t size;
        *this >> size;
        if(size<0 || size_t(size)>mSrc.remaining())throw std::runtime_error("invalid native string length");
        if(size == 0) {
            val = "";
        } else {
            val.resize(size);
            read(&val[0], size);
        }
        return *this;
    }

    eTile* readTile(eGameBoard& board);
    using eBuildingFunc = std::function<void(eBuilding*)>;
    void readBuilding(eGameBoard* board,
                      const eBuildingFunc& func);
    using eCharFunc = std::function<void(eCharacter*)>;
    void readCharacter(eGameBoard* board,
                       const eCharFunc& func);
    using eCharActFunc = std::function<void(eCharacterAction*)>;
    void readCharacterAction(eGameBoard* board,
                             const eCharActFunc& func);
    stdsptr<eWalkableObject> readWalkable();
    stdsptr<eHasResourceObject> readHasResource();
    stdsptr<eCharacterActionFunction> readCharActFunc(
            eGameBoard& board);
    stdsptr<eGodAct> readGodAct(eGameBoard& board);
    stdsptr<eObsticleHandler> readObsticleHandler(
            eGameBoard& board);
    stdsptr<eDirectionTimes> readDirectionTimes(
            eGameBoard& board);
    using eCityFunc = std::function<void(stdsptr<eWorldCity>)>;
    void readCity(eGameBoard* board, const eCityFunc& func);
    void readCity(eWorldBoard* board, const eCityFunc& func);
    using eBannerFunc = std::function<void(eBanner*)>;
    void readBanner(eGameBoard* board, const eBannerFunc& func);
    using eSoldierBannerFunc = std::function<void(stdsptr<eSoldierBanner>)>;
    void readSoldierBanner(eGameBoard* board, const eSoldierBannerFunc& func);
    using eEventFunc = std::function<void(eGameEvent*)>;
    void readGameEvent(eGameBoard* board, const eEventFunc& func);
    using eeInvasionHandlerFunc = std::function<void(eInvasionHandler*)>;
    void readInvasionHandler(eGameBoard* board, const eeInvasionHandlerFunc& func);

    using eFunc = std::function<void()>;
    void addPostFunc(const eFunc& func);
    void handlePostFuncs();

    const std::string& format() const { return mFormat; }
    int formatVersion() const { return mFormatVersion; }
private:
    std::vector<eFunc> mPostFuncs;

    eReadSource mSrc;

    std::string mFormat;
    int mFormatVersion = 0;
};

#endif // EREADSTREAM_H
