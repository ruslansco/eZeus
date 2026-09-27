#ifndef ECONTROLSMENU_H
#define ECONTROLSMENU_H

#include "eframedwidget.h"
#include "esettings.h"
#include <functional>
#include <vector>

class eFramedButton;
class eLabel;

class eControlsMenu : public eFramedWidget {
public:
    using eApplyAction = std::function<void(const eKeyBindings&)>;

    eControlsMenu(const eKeyBindings& bindings,
                  eMainWindow* const window,
                  const eApplyAction& applyAction);
    ~eControlsMenu();

    void initialize();

protected:
    bool keyPressEvent(const eKeyPressEvent& e) override;
    bool mousePressEvent(const eMouseEvent& e) override;

private:
    struct KeyRow {
        std::string labelKey;
        SDL_Scancode* targetKey;
        eFramedButton* button = nullptr;
    };

    void updateButtonLabels();
    void selectBinding(int index);

    eKeyBindings mBindings;
    eApplyAction mApplyAction;
    int mListeningIndex = -1;
    std::vector<KeyRow> mRows;
};

#endif // ECONTROLSMENU_H
