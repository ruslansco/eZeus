#include "e3dbridge.h"
#include "engine/egameboard.h"
#include "characters/echaracter.h"
#include "buildings/esmallhouse.h"
#include "widgets/egamewidget.h"
#include "widgets/egamemenu.h"
#include <algorithm>
#include <cerrno>
#include <cstdio>
#include <set>
#include <sstream>
#include <iomanip>
#ifndef _WIN32
#include <sys/socket.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <unistd.h>
#endif

namespace {
constexpr int districtSize = 32;
std::string asset(eBuilding* b) {
    switch(b->type()) {
    case eBuildingType::hospital: return "hospital";
    case eBuildingType::fountain: return "fountain";
    case eBuildingType::warehouse: return "warehouse";
    case eBuildingType::olivePress: return "olive_press";
    case eBuildingType::watchPost: return "watch_post";
    case eBuildingType::commonHouse: return "common_house_" + std::to_string(std::clamp(static_cast<eSmallHouse*>(b)->level(), 0, 6)) + "a";
    case eBuildingType::road: case eBuildingType::avenue: return "road";
    default: return "unconverted";
    }
}
}

e3DBridge::e3DBridge(int port) {
#ifndef _WIN32
    mListener = socket(AF_INET, SOCK_STREAM, 0);
    if(mListener < 0) return;
    int reuse = 1;
    setsockopt(mListener, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));
    sockaddr_in a{};
    a.sin_family = AF_INET; a.sin_addr.s_addr = htonl(INADDR_LOOPBACK); a.sin_port = htons(port);
    if(bind(mListener, reinterpret_cast<sockaddr*>(&a), sizeof(a)) || listen(mListener, 1)) {
        fprintf(stderr, "EZEUS_3D: cannot bind loopback port %d\n", port);
        close(mListener); mListener = -1; return;
    }
    fcntl(mListener, F_SETFL, O_NONBLOCK);
    printf("EZEUS_3D: 127.0.0.1:%d (protocol 1, no saves)\n", port); fflush(stdout);
#else
    (void)port;
    fprintf(stderr, "EZEUS_3D: macOS/Linux prototype only\n");
#endif
}
e3DBridge::~e3DBridge() {
#ifndef _WIN32
    if(mClient >= 0) close(mClient);
    if(mListener >= 0) close(mListener);
#endif
}

std::string e3DBridge::snapshot(eGameBoard& board, eGameWidget& widget) {
    board.waitUntilFinished();
    if(!mDistrictChosen) {
        eBuilding* choice = nullptr;
        board.iterateOverAllTiles([&](eTile* tile) {
            const auto b = tile->underBuilding();
            if(!b) return;
            if(!choice && b->type() == eBuildingType::commonHouse) choice = b;
            if(b->type() == eBuildingType::hospital) choice = b;
        });
        const auto t = choice ? choice->centerTile() : widget.viewedTile();
        if(t) { mX = t->x() - districtSize/2; mY = t->y() - districtSize/2; }
        mDistrictChosen = true;
    }
    const auto pid = board.personPlayer();
    std::ostringstream o;
    o << std::setprecision(7) << "{\"protocol\":1,\"sequence\":" << ++mSequence
      << ",\"time\":" << board.totalTime() << ",\"paused\":" << (widget.isPaused() ? "true" : "false")
      << ",\"running\":" << (widget.isSimulationRunning() ? "true" : "false")
      << ",\"speed\":" << widget.speedId() << ",\"money\":" << board.drachmas(pid)
      << ",\"population\":" << board.population(pid) << ",\"date\":[" << board.date().day()
      << ',' << static_cast<int>(board.date().month()) + 1 << ',' << board.date().year()
      << "],\"origin\":[" << mX << ',' << mY << "],\"size\":" << districtSize << ",\"tiles\":[";
    bool first = true;
    std::set<eBuilding*> buildings;
    for(int y = mY; y < mY + districtSize; ++y) for(int x = mX; x < mX + districtSize; ++x) {
        const auto t = board.tile(x, y);
        if(!t) continue;
        if(!first) o << ',';
        first = false;
        if(auto b = t->underBuilding()) buildings.insert(b);
        o << '[' << x << ',' << y << ',' << t->doubleAltitude() << ','
          << static_cast<int>(t->terrain()) << ',' << (t->hasRoad() ? 1 : 0) << ','
          << (board.canBuild(x, y, 1, 1, false, t->cityId(), pid) ? 1 : 0) << ']';
    }
    o << "],\"buildings\":["; first = true;
    std::set<const void*> alive;
    const auto id = [&](const void* p) {
        alive.insert(p);
        auto it = mIds.find(p);
        if(it == mIds.end()) it = mIds.emplace(p, mNextId++).first;
        return it->second;
    };
    for(auto b : buildings) {
        if(asset(b) == "road") continue;
        const auto r = b->tileRect(); const auto ct = b->centerTile();
        if(!ct) continue;
        if(!first) o << ',';
        first = false;
        o << "{\"id\":" << id(b) << ",\"asset\":\"" << asset(b) << "\",\"type\":" << static_cast<int>(b->type())
          << ",\"x\":" << r.x << ",\"y\":" << r.y << ",\"w\":" << r.w << ",\"h\":" << r.h
          << ",\"altitude\":" << ct->doubleAltitude() << ",\"active\":" << (b->enabled() ? "true" : "false") << '}';
    }
    o << "],\"walkers\":["; first = true;
    for(auto c : board.characters()) {
        const auto t = c->tile();
        if(!t || !c->visible() || t->x() < mX || t->x() >= mX + districtSize || t->y() < mY || t->y() >= mY + districtSize) continue;
        if(!first) o << ',';
        first = false;
        o << "{\"id\":" << id(c) << ",\"type\":" << static_cast<int>(c->type())
          << ",\"asset\":\"" << (c->type() == eCharacterType::healer ? "physician" : "unconverted")
          << "\",\"x\":" << c->absX() << ",\"y\":" << c->absY()
          << ",\"altitude\":" << t->characterDoubleAltitude() << '}';
    }
    for(auto it = mIds.begin(); it != mIds.end();) {
        if(!alive.count(it->first)) it = mIds.erase(it); else ++it;
    }
    o << "]}\n";
    return o.str();
}

std::string e3DBridge::command(const std::string& line, eGameBoard& board, eGameWidget& widget) {
    std::istringstream in(line); std::string action; in >> action; int v;
    if(action == "snapshot") return snapshot(board, widget);
    if(action == "pause" && in >> v && (v == 0 || v == 1)) {
        if(widget.isPaused() != bool(v)) widget.switchPause();
    } else if(action == "speed" && in >> v && v >= 0 && v <= widget.maxSpeedId()) {
        widget.setSpeedId(v);
    } else if(action == "build") {
        std::string name; int x, y, orientation;
        if(!(in >> name >> x >> y >> orientation) || x < mX || y < mY || x >= mX + districtSize || y >= mY + districtSize)
            return "{\"error\":\"outside_district\"}\n";
        const std::map<std::string, eBuildingMode> modes{{"road", eBuildingMode::road},
            {"house", eBuildingMode::commonHousing}, {"hospital", eBuildingMode::hospital}, {"fountain", eBuildingMode::fountain}};
        const auto mode = modes.find(name);
        if(mode == modes.end() || !board.tile(x, y)) return "{\"error\":\"unsupported_build\"}\n";
        const int span = name == "hospital" ? 4 : (name == "road" ? 1 : 2);
        if(x + span > mX + districtSize || y + span > mY + districtSize)
            return "{\"error\":\"outside_district\"}\n";
        if(!board.supportsBuilding(board.tile(x, y)->cityId(), mode->second))
            return "{\"error\":\"building_not_available\"}\n";
        board.waitUntilFinished();
        widget.buildFromPresentation(mode->second, x, y, orientation);
        return snapshot(board, widget);
    } else return "{\"error\":\"unsupported_command\"}\n";
    return snapshot(board, widget);
}

bool e3DBridge::poll(eGameBoard& board, eGameWidget& widget) {
#ifndef _WIN32
    if(mListener < 0) return false;
    if(mClient < 0) {
        mClient = accept(mListener, nullptr, nullptr);
        if(mClient < 0) return false;
        fcntl(mClient, F_SETFL, O_NONBLOCK);
#ifdef SO_NOSIGPIPE
        int yes = 1; setsockopt(mClient, SOL_SOCKET, SO_NOSIGPIPE, &yes, sizeof(yes));
#endif
        mInput.clear(); mOutput.clear(); mSent = 0;
    }
    char data[4096]; const auto n = recv(mClient, data, sizeof(data), 0);
    if(n == 0 || (n < 0 && errno != EAGAIN && errno != EWOULDBLOCK)) {
        close(mClient); mClient = -1; return false;
    }
    if(n > 0) mInput.append(data, n);
    if(mInput.size() > 8192 || mOutput.size() > 2*1024*1024) {
        close(mClient); mClient = -1; return false;
    }
    if(mOutput.empty()) {
        const auto end = mInput.find('\n');
        if(end != std::string::npos) {
            const auto line = mInput.substr(0, end); mInput.erase(0, end + 1);
            if(line == "quit") return true;
            mOutput = command(line, board, widget); mSent = 0;
        }
    }
    if(!mOutput.empty()) {
#ifdef MSG_NOSIGNAL
        const int flags = MSG_NOSIGNAL;
#else
        const int flags = 0;
#endif
        const auto n = send(mClient, mOutput.data() + mSent, mOutput.size() - mSent, flags);
        if(n > 0) mSent += n;
        else if(n < 0 && errno != EAGAIN && errno != EWOULDBLOCK) {
            close(mClient); mClient = -1; return false;
        }
        if(mSent == mOutput.size()) { mOutput.clear(); mSent = 0; }
    }
#else
    (void)board; (void)widget;
#endif
    return false;
}
