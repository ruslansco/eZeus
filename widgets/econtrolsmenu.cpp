#include "econtrolsmenu.h"

#include <SDL2/SDL_keyboard.h>
#include "elabel.h"
#include "eframedbutton.h"
#include "eokbutton.h"
#include "ecancelbutton.h"
#include "elanguage.h"
#include "eresolution.h"

eControlsMenu::eControlsMenu(const eKeyBindings& bindings,
                             eMainWindow* const window,
                             const eApplyAction& applyAction) :
    eFramedWidget(window),
    mBindings(bindings),
    mApplyAction(applyAction) {
}

eControlsMenu::~eControlsMenu() {
    if(isKeyboardGrabber()) {
        releaseKeyboard();
    }
}

void eControlsMenu::initialize() {
    setType(eFrameType::message);

    const auto res = resolution();
    const int p = res.largePadding();
    const double mult = res.multiplier();

    const int totalW = int(640 * mult);
    const int totalH = int(440 * mult);
    resize(totalW, totalH);
    align(eAlignment::center);

    // Title
    const auto titleLabel = new eLabel(window());
    titleLabel->setHugeFontSize();
    titleLabel->setText(eLanguage::text("controls"));
    titleLabel->fitContent();
    titleLabel->setY(p);
    addWidget(titleLabel);
    titleLabel->align(eAlignment::hcenter);

    mRows = {
        {"pan_up", &mBindings.fMoveUp, nullptr},
        {"pan_down", &mBindings.fMoveDown, nullptr},
        {"pan_left", &mBindings.fMoveLeft, nullptr},
        {"pan_right", &mBindings.fMoveRight, nullptr},
        {"pause_game", &mBindings.fPause, nullptr},
        {"camera_rotate_left", &mBindings.fCameraRotateLeft, nullptr},
        {"camera_rotate_right", &mBindings.fCameraRotateRight, nullptr},
        {"rotate_building", &mBindings.fRotate, nullptr},
        {"clone_building", &mBindings.fClone, nullptr},
        {"quick_demolish", &mBindings.fDemolish, nullptr},
        {"speed_up", &mBindings.fSpeedUp, nullptr},
        {"speed_down", &mBindings.fSpeedDown, nullptr},
        {"quick_save", &mBindings.fQuickSave, nullptr},
        {"objectives_tracker", &mBindings.fObjectives, nullptr}
    };

    const int contentY = titleLabel->y() + titleLabel->height() + p;
    const int bottomH = int(45 * mult);
    const int availH = totalH - contentY - bottomH;

    const int colW = (totalW - 3 * p) / 2;
    const int numRowsPerCol = int((mRows.size() + 1) / 2);
    const int rowH = availH / numRowsPerCol;
    const int btnW = int(105 * mult);
    const int btnH = int(24 * mult);

    for(size_t i = 0; i < mRows.size(); ++i) {
        const int col = int(i) / numRowsPerCol;
        const int row = int(i) % numRowsPerCol;
        const int colX = p + col * (colW + p);
        const int rowY = contentY + row * rowH;

        const auto rowWid = new eWidget(window());
        rowWid->setNoPadding();
        rowWid->resize(colW, btnH);
        rowWid->move(colX, rowY + (rowH - btnH) / 2);

        const auto label = new eLabel(window());
        label->setSmallFontSize();
        label->setText(eLanguage::text(mRows[i].labelKey));
        label->fitContent();
        label->setX(0);
        label->setY((btnH - label->height()) / 2);
        rowWid->addWidget(label);

        const auto btn = new eFramedButton(window());
        btn->setSmallPadding();
        btn->setRenderBg(true);
        btn->setUnderline(false);
        btn->resize(btnW, btnH);
        btn->setX(colW - btnW);
        btn->setY(0);
        btn->setTextAlignment(eAlignment::center);

        const int rowIdx = static_cast<int>(i);
        btn->setPressAction([this, rowIdx]() {
            selectBinding(rowIdx);
        });

        rowWid->addWidget(btn);
        addWidget(rowWid);
        mRows[i].button = btn;
    }

    updateButtonLabels();

    // Bottom actions bar
    const int bottomY = totalH - bottomH;

    // Reset Defaults button on the left
    const auto defBtn = new eFramedButton(window());
    defBtn->setSmallPadding();
    defBtn->setRenderBg(true);
    defBtn->setUnderline(false);
    defBtn->setText(eLanguage::text("reset_defaults"));
    defBtn->fitContent();
    defBtn->setHeight(int(28 * mult));
    defBtn->move(p, bottomY + (bottomH - defBtn->height()) / 2);
    defBtn->setPressAction([this]() {
        mBindings = eKeyBindings{};
        mListeningIndex = -1;
        releaseKeyboard();
        updateButtonLabels();
    });
    addWidget(defBtn);

    // Cancel and OK buttons on the right
    const auto okBtn = new eOkButton(window());
    const auto cancelBtn = new eCancelButton(window());

    okBtn->setPressAction([this]() {
        if(mApplyAction) {
            mApplyAction(mBindings);
        }
        deleteLater();
    });
    cancelBtn->setPressAction([this]() {
        deleteLater();
    });

    cancelBtn->move(totalW - p - okBtn->width() - p/2 - cancelBtn->width(),
                    bottomY + (bottomH - cancelBtn->height()) / 2);
    okBtn->move(totalW - p - okBtn->width(),
                bottomY + (bottomH - okBtn->height()) / 2);

    addWidget(cancelBtn);
    addWidget(okBtn);
}

static std::string formatKeyName(SDL_Scancode code) {
    if(code == SDL_SCANCODE_SPACE) {
        const auto& t = eLanguage::text("key_space");
        if(!t.empty()) return t;
    } else if(code == SDL_SCANCODE_DELETE) {
        const auto& t = eLanguage::text("key_delete");
        if(!t.empty()) return t;
    } else if(code == SDL_SCANCODE_LEFTBRACKET) {
        return "[";
    } else if(code == SDL_SCANCODE_RIGHTBRACKET) {
        return "]";
    } else if(code == SDL_SCANCODE_UP) {
        const auto& t = eLanguage::text("key_up");
        if(!t.empty()) return t;
    } else if(code == SDL_SCANCODE_DOWN) {
        const auto& t = eLanguage::text("key_down");
        if(!t.empty()) return t;
    } else if(code == SDL_SCANCODE_LEFT) {
        const auto& t = eLanguage::text("key_left");
        if(!t.empty()) return t;
    } else if(code == SDL_SCANCODE_RIGHT) {
        const auto& t = eLanguage::text("key_right");
        if(!t.empty()) return t;
    }
    const char* name = SDL_GetScancodeName(code);
    return (name && name[0] != '\0') ? name : "---";
}

void eControlsMenu::updateButtonLabels() {
    for(size_t i = 0; i < mRows.size(); ++i) {
        auto& r = mRows[i];
        if(!r.button) continue;
        if(static_cast<int>(i) == mListeningIndex) {
            r.button->setText(eLanguage::text("press_any_key"));
            r.button->setYellowFontColor();
        } else {
            std::string keyStr = formatKeyName(*r.targetKey);
            r.button->setText(keyStr);
            r.button->setLightFontColor();
        }
    }
}

void eControlsMenu::selectBinding(int index) {
    if(mListeningIndex == index) {
        mListeningIndex = -1;
        releaseKeyboard();
    } else {
        mListeningIndex = index;
        grabKeyboard();
    }
    updateButtonLabels();
}

bool eControlsMenu::keyPressEvent(const eKeyPressEvent& e) {
    if(mListeningIndex >= 0 && mListeningIndex < static_cast<int>(mRows.size())) {
        const auto scancode = e.key();
        if(scancode != SDL_SCANCODE_ESCAPE) {
            *mRows[mListeningIndex].targetKey = scancode;
        }
        mListeningIndex = -1;
        releaseKeyboard();
        updateButtonLabels();
        return true;
    }
    if(e.key() == SDL_SCANCODE_ESCAPE) {
        deleteLater();
        return true;
    }
    return true;
}

bool eControlsMenu::mousePressEvent(const eMouseEvent& e) {
    if(mListeningIndex >= 0) {
        mListeningIndex = -1;
        releaseKeyboard();
        updateButtonLabels();
        return true;
    }
    if(e.button() == eMouseButton::right) {
        deleteLater();
        return true;
    }
    return eFramedWidget::mousePressEvent(e);
}
