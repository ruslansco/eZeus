#ifndef EMESSAGELOGWIDGET_H
#define EMESSAGELOGWIDGET_H

#include "eframedwidget.h"

#include <memory>

class eGameWidget;

// The messages the player was sent this session, newest first; opened by
// the side panel's messages button. Choosing one shows it again.
class eMessageLogWidget : public eFramedWidget {
public:
    using eFramedWidget::eFramedWidget;
    ~eMessageLogWidget();

    // Entries from seenBefore on arrived since the list was last opened.
    void initialize(eGameWidget* const gw, const int seenBefore,
                    const eAction& close);
private:
    // the list in the scroll area (not a child: deleted here)
    std::shared_ptr<eWidget*> mList;
};

#endif // EMESSAGELOGWIDGET_H
