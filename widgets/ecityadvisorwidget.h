#ifndef ECITYADVISORWIDGET_H
#define ECITYADVISORWIDGET_H

#include "eframedwidget.h"

#include <string>
#include <utility>
#include <vector>

#include "engine/ecityadvisor.h"

class eGameBoard;
class eGameWidget;
enum class eCityId;

// The advisor window: a card per problem, each with a "Go there" button.
class eCityAdvisorWidget : public eFramedWidget {
public:
    using eFramedWidget::eFramedWidget;

    void initialize(eGameWidget* const gw, eGameBoard& board,
                    const eCityId cid, const eAction& close);
};

#endif // ECITYADVISORWIDGET_H
