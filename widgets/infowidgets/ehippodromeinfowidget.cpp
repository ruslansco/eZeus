#include "ehippodromeinfowidget.h"

#include "buildings/ehippodrome.h"
#include "engine/ebuildinginfotext.h"
#include "elanguage.h"

void eHippodromeInfoWidget::initialize(eHippodrome * const h) {
    eInfoWidget::initialize(eLanguage::zeusText(167, 0));

    // Shared with the Godot inspector (engine/ebuildinginfotext).
    for(const auto& line : eBuildingInfoText::hippodrome(*h)) addText(line);
}
