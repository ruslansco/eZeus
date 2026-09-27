#ifndef ETRADESUMMARYWIDGET_H
#define ETRADESUMMARYWIDGET_H

#include "eframedwidget.h"

#include "engine/eresourcetype.h"

#include <map>
#include <memory>
#include <string>
#include <vector>

class eGameBoard;
class eTexture;
enum class eCityId;

// The body of the trade summary: each partner's trade this year and last,
// then the goods in storage and who would buy them.
class eTradeSummaryList : public eWidget {
public:
    using eWidget::eWidget;
    ~eTradeSummaryList();

    void initialize(eGameBoard& board, const eCityId cid, const int width);
protected:
    void paintEvent(ePainter& p) override;
private:
    struct eLine {
        std::string fLeft;
        std::string fRight;
        SDL_Color fLeftColor{236, 230, 214, 255};
        SDL_Color fRightColor{236, 230, 214, 255};
        int fFont = 0;            // 0 tiny, 1 small
        int fIndent = 0;
        int fY = 0;
        int fH = 0;
        bool fHeader = false;     // gold rule under it
        bool fCard = false;       // starts a partner card
        int fCardH = 0;
        eResourceType fIcon = eResourceType::none;
    };
    struct eText {
        SDL_Texture* fTex = nullptr;
        int fW = 0;
        int fH = 0;
    };
    eLine& add(const std::string& left, const std::string& right = "",
               const int font = 0, const int indent = 0);
    const eText& text(SDL_Renderer* const r, const std::string& s, const int px);

    std::vector<eLine> mLines;
    std::map<std::pair<std::string, int>, eText> mTexts;
};

class eTradeSummaryWidget : public eFramedWidget {
public:
    using eFramedWidget::eFramedWidget;

    void initialize(eGameBoard& board, const eCityId cid, const eAction& close);
};

#endif // ETRADESUMMARYWIDGET_H
