#include "echoosegameeditmenu.h"

#include "eframedwidget.h"
#include "eframedbutton.h"
#include "escrollwidgetcomplete.h"
#include "ebuttonbase.h"
#include "ecancelbutton.h"
#include "emainwindow.h"
#include "eproceedbutton.h"
#include "elineedit.h"
#include "equestionwidget.h"
#include "eeditormainmenu.h"
#include "ebitmapwidget.h"
#include "eadventurepreview.h"
#include "emenubutton.h"
#include "eeventbackground.h"
#include "emenuscene.h"
#include "emenu3d.h"
#include "textures/egeometrybatch.h"
#include "eepisodeintroductionwidget.h"
#include "estringhelpers.h"
#include "elanguage.h"
#include "egamedir.h"
#include "engine/eadventurelist.h"
#include "audio/esounds.h"

#include <filesystem>
namespace fs = std::filesystem;
#include <algorithm>

#include "pak/zeusfile.h"
#include "pak/epakhelpers.h"

namespace {
std::string tr(const std::string& key, const std::string& fallback) {
    const auto& s = eLanguage::text(key);
    return s.empty() ? fallback : s;
}
}

// One adventure in the list: a gold bar marks the chosen one.
class eAdventureRow : public eButtonBase {
public:
    using eButtonBase::eButtonBase;

    void setSelected(const bool s) {
        mSelected = s;
    }
protected:
    void paintEvent(ePainter& p) override {
        const Uint64 now = SDL_GetPerformanceCounter();
        const double dt = mLast ? std::min(0.1, double(now - mLast)/SDL_GetPerformanceFrequency()) : 0;
        mLast = now;
        mHover += ((hovered() ? 1.0 : 0.0) - mHover)*(1 - std::exp(-dt*16));
        mSel += ((mSelected ? 1.0 : 0.0) - mSel)*(1 - std::exp(-dt*14));
        const int state = (mSelected || hovered()) ? 1 : 0;
        if(state != mColorState) {
            mColorState = state;
            if(state) setYellowFontColor();
            else setLightFontColor();
        }
        auto& scene = eMenuScene::instance();
        const auto r = p.renderer();
        const auto white = scene.whiteTexture();
        eGeometryBatch::sFlush();
        const float x = static_cast<float>(p.x());
        const float y = static_cast<float>(p.y());
        const float w = static_cast<float>(width());
        const float h = static_cast<float>(height());
        SDL_SetTextureBlendMode(white, SDL_BLENDMODE_BLEND);
        if(mHover > 0.01 || mSel > 0.01) {
            const double sel = mSel;
            const double hv = mHover*(1 - sel);
            const auto a = [](const double v) { return static_cast<Uint8>(std::round(255*std::min(1.0, v))); };
            const SDL_Color l{static_cast<Uint8>(52 + 60*sel), static_cast<Uint8>(72 + 20*sel),
                              static_cast<Uint8>(110 - 70*sel), a(0.85*sel + 0.6*hv)};
            const SDL_Color rr{l.r, l.g, l.b, 0};
            const SDL_FPoint q[4] = {{x, y}, {x + w, y}, {x + w, y + h}, {x, y + h}};
            const SDL_Color cs[4] = {l, rr, rr, l};
            eMenu3D::drawFlat(r, white, q, cs);
            if(sel > 0.01) {
                const float bw = std::max(2.f, h*0.08f);
                SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_BLEND);
                SDL_SetRenderDrawColor(r, 255, 214, 92, a(sel));
                const SDL_FRect bar{x, y + 2, bw, h - 4};
                SDL_RenderFillRectF(r, &bar);
                SDL_SetRenderDrawColor(r, 255, 214, 92, a(0.45*sel));
                const SDL_FRect rule{x, y + h - 1, w*0.8f, 1};
                SDL_RenderFillRectF(r, &rule);
            }
        }
        p.save();
        p.translate(static_cast<int>(h*0.45) + static_cast<int>(6*mSel), 0);
        eButtonBase::paintEvent(p);
        p.restore();
    }
private:
    bool mSelected = false;
    double mHover = 0;
    double mSel = 0;
    Uint64 mLast = 0;
    int mColorState = -1;
};

void eChooseGameEditMenu::initialize(const bool editor) {
    eMainMenuBase::initialize(eMenuShot::adventures);
    mEditor = editor;
    setBackAction([this]() { window()->showMainMenu(); });

    const auto glossaries = eAdventureList::scan();
    mGlossaries = glossaries;

    const auto res = resolution();
    const int p = res.largePadding();
    const double u = std::min(height()/1080., width()/1500.);
    const auto U = [u](const double v) { return static_cast<int>(std::round(v*u)); };

    // --- title -------------------------------------------------------------
    const auto title = new eLabel(window());
    title->setHugeFontSize();
    title->setYellowFontColor();
    title->setText(editor ? eLanguage::zeusText(287, 3) :
                            eLanguage::zeusText(293, 9));
    title->fitContent();
    addWidget(title);
    title->align(eAlignment::hcenter);
    title->setY(U(44));

    const int listW = U(600);
    const int gapX = U(34);
    const int prevW = U(700);
    const int prevH = U(410);
    const int totalW = listW + gapX + prevW;
    const int x0 = (width() - totalW)/2;
    const int top = title->y() + title->height() + U(22);
    const int barH = U(64);
    const int contentH = height() - top - barH - U(70);

    // --- list panel ----------------------------------------------------------
    const auto listFrame = new eFramedWidget(window());
    listFrame->setType(eFrameType::message);
    listFrame->resize(listW, contentH);
    listFrame->move(x0, top);
    addWidget(listFrame);

    const auto count = new eLabel(window());
    count->setSmallFontSize();
    count->setNoPadding();
    {
        auto s = tr("menu_adventure_count", "%1 adventures");
        const auto pos = s.find("%1");
        if(pos != std::string::npos) s.replace(pos, 2, std::to_string(glossaries.size()));
        count->setText(s);
    }
    count->fitContent();
    listFrame->addWidget(count);
    count->move(2*p, 2*p);

    mScroll = new eScrollWidgetComplete(window());
    listFrame->addWidget(mScroll);
    const int scrollY = count->y() + count->height() + p;
    mScroll->resize(listW - 4*p, contentH - scrollY - 2*p);
    mScroll->move(2*p, scrollY);
    mScroll->initialize();

    // --- preview and introduction --------------------------------------------
    const int px = x0 + listW + gapX;
    mPreview = new eAdventurePreview(window());
    mPreview->resize(prevW, prevH);
    mPreview->move(px, top - U(4));
    addWidget(mPreview);

    const auto descFrame = new eFramedWidget(window());
    descFrame->setType(eFrameType::message);
    const int descY = top + prevH;
    descFrame->resize(prevW, top + contentH - descY);
    descFrame->move(px, descY);
    addWidget(descFrame);

    const auto descIW = new eWidget(window());
    descIW->setNoPadding();
    descIW->resize(descFrame->width() - 4*p, descFrame->height() - 3*p);
    descFrame->addWidget(descIW);
    descIW->move(2*p, 3*p/2);

    mTitle = new eLabel(window());
    mTitle->setFontSize(res.largeFontSize());
    mTitle->setNoPadding();
    mTitle->setText("Height");
    mTitle->fitContent();
    mTitle->setText("");
    mTitle->setYellowFontColor();
    descIW->addWidget(mTitle);

    mDesc = new eLabel(window());
    mDesc->setWrapWidth(descIW->width());
    mDesc->setSmallFontSize();
    mDesc->setNoPadding();
    descIW->addWidget(mDesc);
    mDesc->setY(mTitle->height() + p);

    // --- action bar ------------------------------------------------------------
    const int barY = top + contentH + U(22);
    const auto back = new eMenuButton(window());
    back->setup(tr("menu_back", "Back"), eMenuButton::eStyle::secondary, U(200));
    back->setHeight(barH);
    back->move(x0, barY);
    back->setPressAction([this]() { window()->showMainMenu(); });
    addWidget(back);

    const auto begin = new eMenuButton(window());
    begin->setup(editor ? eLanguage::zeusText(287, 2) : eLanguage::zeusText(287, 6),
                 eMenuButton::eStyle::primary, U(320));
    begin->setHeight(barH);
    begin->move(x0 + totalW - begin->width(), barY);
    begin->setPressAction([this]() { proceed(); });
    addWidget(begin);

    if(editor) {
        const auto newB = new eMenuButton(window());
        newB->setup(eLanguage::zeusText(287, 0), eMenuButton::eStyle::secondary);
        newB->setHeight(barH);
        newB->move(back->x() + back->width() + U(18), barY);
        addWidget(newB);
        newB->setPressAction([this]() {
            const auto box = new eFramedWidget(window());
            box->setType(eFrameType::message);
            const auto res = resolution();
            const int p = res.largePadding();

            const auto iw = new eWidget(window());
            iw->setNoPadding();
            iw->setWidth(300*res.multiplier());

            const auto title = new eLabel(window());
            title->setSmallFontSize();
            title->setYellowFontColor();
            title->setText(eLanguage::zeusText(287, 0));
            title->fitContent();
            iw->addWidget(title);
            title->align(eAlignment::hcenter);

            const auto edit = new eLineEdit(window());
            edit->setWidth(iw->width());
            edit->setHeight(30*res.multiplier());
            iw->addWidget(edit);

            const auto buttonsW = new eWidget(window());
            buttonsW->setNoPadding();

            const auto cButton = new eCancelButton(window());
            buttonsW->addWidget(cButton);
            cButton->setPressAction([box]() {
                box->deleteLater();
            });

            const auto proceedW = new eWidget(window());
            proceedW->setNoPadding();

            const auto proceedLabel = new eLabel(window());
            proceedLabel->setSmallFontSize();
            proceedLabel->setSmallPadding();
            proceedLabel->setText(eLanguage::zeusText(287, 2));
            proceedLabel->fitContent();
            proceedW->addWidget(proceedLabel);

            const auto proceedB = new eProceedButton(window());
            proceedB->setPressAction([this, edit]() {
                const auto name = edit->text();
                if(name.empty()) return;
                eCampaign c;
                c.initialize(name);
                c.save();
                window()->showChooseGameEditMenu();
            });
            proceedW->addWidget(proceedB);

            proceedW->stackHorizontally(2*p);
            proceedW->fitContent();
            proceedLabel->align(eAlignment::vcenter);
            proceedB->align(eAlignment::vcenter);
            buttonsW->addWidget(proceedW);

            buttonsW->layoutHorizontallyWithoutSpaces();
            buttonsW->fitHeight();

            iw->addWidget(buttonsW);

            iw->stackVertically(2*p);
            iw->fitHeight();
            box->addWidget(iw);
            iw->move(2*p, 2*p);
            box->setHeight(iw->height() + 4*p);

            window()->execDialog(box);
            box->align(eAlignment::center);

            edit->grabKeyboard();
        });

        const auto deleteB = new eMenuButton(window());
        deleteB->setup(eLanguage::zeusText(287, 1), eMenuButton::eStyle::secondary);
        deleteB->setHeight(barH);
        deleteB->move(newB->x() + newB->width() + U(18), barY);
        addWidget(deleteB);
        deleteB->setPressAction([this]() {
            if(mSelected.fIsPak || mSelected.fFolderName.empty()) return;
            const auto q = new eQuestionWidget(window());
            const auto acceptA = [this]() {
                const auto dir = eGameDir::adventuresDir() + mSelected.fFolderName + "/";
                std::filesystem::remove_all(dir);
                window()->showChooseGameEditMenu();
            };
            q->initialize(eLanguage::zeusText(5, 179),
                          eLanguage::zeusText(5, 180),
                          acceptA, nullptr);
            window()->execDialog(q);
            q->align(eAlignment::center);
        });
    }

    const auto hint = new eLabel(window());
    hint->setVerySmallFontSize();
    hint->setNoPadding();
    hint->setText(tr("menu_choose_hint", "Enter - begin     Esc - back"));
    hint->fitContent();
    addWidget(hint);
    hint->align(eAlignment::hcenter);
    hint->setY(barY + barH + U(14));

    // --- rows ----------------------------------------------------------------
    {
        const auto scrollArea = new eWidget(window());
        scrollArea->setNoPadding();
        const int rowW = mScroll->listWidth() - 2*res.tinyPadding();
        int y = 0;
        for(int i = 0; i < static_cast<int>(glossaries.size()); i++) {
            const auto& g = glossaries[i];
            const auto w = new eAdventureRow(window());
            w->setSmallFontSize();
            w->setNoPadding();
            w->setText(g.fTitle);
            w->fitContent();
            w->setWidth(rowW);
            w->setHeight(w->height() + U(16));
            w->setTextAlignment(eAlignment::left | eAlignment::vcenter);
            w->setPressAction([this, i]() { rowPressed(i); });
            scrollArea->addWidget(w);
            w->setY(y);
            y += w->height() + 2;
            mRows.push_back(w);
        }
        scrollArea->fitContent();
        mScroll->setScrollArea(scrollArea);
    }
    if(!glossaries.empty()) select(0, false);
}

bool eChooseGameEditMenu::dialogOpen() const {
    for(const auto c : children()) {
        if(dynamic_cast<eEventBackground*>(c)) return true;
    }
    return false;
}

void eChooseGameEditMenu::paintEvent(ePainter& p) {
    eMainMenuBase::paintEvent(p);
    // the list follows the keyboard unless a dialog wants it
    if(dialogOpen()) {
        if(isKeyboardGrabber()) releaseKeyboard();
    } else {
        grabKeyboard();
    }
}

void eChooseGameEditMenu::select(const int id, const bool scroll) {
    if(id < 0 || id >= static_cast<int>(mGlossaries.size())) return;
    if(mSelectedId >= 0 && mSelectedId < static_cast<int>(mRows.size())) {
        mRows[mSelectedId]->setSelected(false);
    }
    mSelectedId = id;
    const auto row = mRows[id];
    row->setSelected(true);
    setGlossary(mGlossaries[id]);
    if(scroll && mScroll) mScroll->ensureVisible(row->y(), row->height());
}

void eChooseGameEditMenu::rowPressed(const int id) {
    const Uint64 now = SDL_GetPerformanceCounter();
    const double since = double(now - mLastPressTime)/SDL_GetPerformanceFrequency();
    const bool twice = id == mLastPressId && since < 0.45;
    mLastPressId = id;
    mLastPressTime = now;
    select(id, false);
    if(twice) proceed();
}

void eChooseGameEditMenu::proceed() {
    if(!mSelected.fIsPak && mSelected.fFolderName.empty()) return;
    if(mSelected.fIsPak && mSelected.fPakPath.empty()) return;
    const auto w = window();
    const bool editor = mEditor;
    const auto sel = mSelected;
    // after this frame: the new screen replaces (and deletes) this one
    w->addSlot([w, editor, sel]() {
        const auto c = std::make_shared<eCampaign>();
        if(sel.fIsPak) c->readPak(sel.fTitle, sel.fPakPath);
        else c->load(sel.fFolderName);
        if(editor) {
            const auto e = new eEditorMainMenu(w);
            e->resize(w->width(), w->height());
            c->setEditorMode(true);
            e->initialize(c);
            w->setWidget(e);
        } else {
            w->showEpisodeIntroduction(c);
        }
    });
}

bool eChooseGameEditMenu::keyPressEvent(const eKeyPressEvent& e) {
    if(dialogOpen()) return false;
    const auto k = e.key();
    const int n = static_cast<int>(mGlossaries.size());
    if(k == SDL_SCANCODE_UP || k == SDL_SCANCODE_W) {
        if(n) select(mSelectedId <= 0 ? n - 1 : mSelectedId - 1, true);
    } else if(k == SDL_SCANCODE_DOWN || k == SDL_SCANCODE_S) {
        if(n) select((mSelectedId + 1)%n, true);
    } else if(k == SDL_SCANCODE_PAGEUP) {
        if(n) select(std::max(0, mSelectedId - 8), true);
    } else if(k == SDL_SCANCODE_PAGEDOWN) {
        if(n) select(std::min(n - 1, mSelectedId + 8), true);
    } else if(k == SDL_SCANCODE_HOME) {
        if(n) select(0, true);
    } else if(k == SDL_SCANCODE_END) {
        if(n) select(n - 1, true);
    } else if(k == SDL_SCANCODE_RETURN || k == SDL_SCANCODE_KP_ENTER) {
        eSounds::playButtonSound();
        proceed();
    } else {
        return eMainMenuBase::keyPressEvent(e);
    }
    return true;
}

void eChooseGameEditMenu::setGlossary(const eCampaignGlossary& g) {
    mSelected = g;
    mPreview->setBitmap(g.fBitmap);
    mTitle->setText(g.fTitle);
    mTitle->fitContent();
    auto textPrep = g.fIntroduction;
    eStringHelpers::replaceSpecial(textPrep);
    mDesc->setText(textPrep);
    mDesc->fitContent();
}
