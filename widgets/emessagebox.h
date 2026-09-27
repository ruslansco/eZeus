#ifndef EMESSAGEBOX_H
#define EMESSAGEBOX_H

#include "eframedwidget.h"

#include "emessage.h"
#include "engine/edate.h"

class eWorldCity;
struct eEventData;
enum class eResourceType;
enum class eCityId;
class eLabel;
class eGameWidget;

class eMessageBox : public eFramedWidget {
public:
    using eFramedWidget::eFramedWidget;

    void initialize(eGameBoard &board,
                    const eEventData& ed,
                    const eAction& viewTile,
                    const eAction& closeFunc,
                    eMessage msg);

    void close();
    bool closable() const { return mClosable; }

    // A message's title with its placeholders ([city_name], [god] ...) filled in.
    static std::string sFormatTitle(const eEventData& ed, std::string title);
    // A message's text with its placeholders filled in.
    static std::string sFormatText(const eEventData& ed, std::string text);

    eWidget* createTributeWidget(const eResourceType type,
                                 const int count, const int space,
                                 const int months = -1,
                                 eLabel** spaceLabelPtr = nullptr);
protected:
//    void paintEvent(ePainter& p);
    bool keyPressEvent(const eKeyPressEvent& e);
    bool mousePressEvent(const eMouseEvent& e);
private:
    bool mClosable = false;
    eAction mCloseFunc;
//    eAction mDone;
};

#endif // EMESSAGEBOX_H
