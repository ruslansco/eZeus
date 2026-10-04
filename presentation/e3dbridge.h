#ifndef E3DBRIDGE_H
#define E3DBRIDGE_H
#include <map>
#include <string>
#include <cstdint>
class eGameBoard;
class eGameWidget;
// Development loopback adapter; native C++ owns simulation and commands.
class e3DBridge {
public:
    explicit e3DBridge(int port);
    ~e3DBridge();
    bool valid() const { return mListener >= 0; }
    bool poll(eGameBoard& board, eGameWidget& widget);
private:
    std::string snapshot(eGameBoard& board, eGameWidget& widget);
    std::string command(const std::string& line, eGameBoard& board, eGameWidget& widget);
    int mListener = -1, mClient = -1, mX = 0, mY = 0;
    bool mDistrictChosen = false;
    std::string mInput, mOutput;
    size_t mSent = 0;
    uint64_t mSequence = 0, mNextId = 1;
    std::map<const void*, uint64_t> mIds;
};
#endif
