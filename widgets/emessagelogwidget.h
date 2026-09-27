#ifndef EMESSAGELOGWIDGET_H
#define EMESSAGELOGWIDGET_H

#include "eframedwidget.h"

class eGameWidget;

// The messages the player was sent this session, newest first; opened by
// the side panel's messages button. Choosing one shows it again.
class eMessageLogWidget : public eFramedWidget {
public:
    using eFramedWidget::eFramedWidget;

    // Entries from seenBefore on arrived since the list was last opened.
    void initialize(eGameWidget* const gw, const int seenBefore,
                    const eAction& close);
};

#endif // EMESSAGELOGWIDGET_H
