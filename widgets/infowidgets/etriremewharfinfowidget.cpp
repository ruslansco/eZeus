#include "etriremewharfinfowidget.h"

#include "buildings/etriremewharf.h"

#include "engine/egameboard.h"
#include "elanguage.h"
#include "engine/ebuildinginfotext.h"
#include "widgets/eswitchbutton.h"

void eTriremeWharfInfoWidget::initialize(eTriremeWharf* const b) {
    std::string title;
    std::string info;
    std::string employmentInfo;
    std::string additionalInfo;
    eBuilding::sInfoText(b, title, info, employmentInfo, additionalInfo);
    eInfoWidget::initialize(title);

    // Shared with the Godot inspector (engine/ebuildinginfotext).
    for(const auto& line : eBuildingInfoText::triremeWharf(*b)) addText(line);
    addText(info);

    addText(employmentInfo);

    addEmploymentWidget(b);

    addText(additionalInfo);

    const auto button = new eSwitchButton(window());
    button->setUnderline(false);
    button->addValue(eBuildingInfoText::triremeWharfSwitch(false));
    button->addValue(eBuildingInfoText::triremeWharfSwitch(true));
    button->fitValidContent();
    button->setValue(b->shutDown() ? 0 : 1);
    button->setSwitchAction([b](const int val) {
        b->setShutDown(val == 0);
    });
    const int bheight = button->height();
    const auto w = addRegularWidget(bheight);
    w->addWidget(button);
    button->align(eAlignment::hcenter);
}
