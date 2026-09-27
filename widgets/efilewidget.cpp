#include "efilewidget.h"

#include "emainwindow.h"

#include "eacceptbutton.h"
#include "ecancelbutton.h"
#include "equestionwidget.h"

#include "escrollwidgetcomplete.h"

#include "elineedit.h"
#include "eframedbutton.h"
#include "elabel.h"

#include "elanguage.h"
#include "audio/esounds.h"
#include "esaveinfo.h"
#include "emenuscene.h"
#include "emenu3d.h"
#include "textures/egeometrybatch.h"

#include <string>
#include <iostream>
#include <filesystem>
#include <chrono>
#include <map>
namespace fs = std::filesystem;

namespace {
std::string tr(const std::string& key, const std::string& fallback) {
    const auto& s = eLanguage::text(key);
    return s.empty() ? fallback : s;
}

// The name field also steers the list: Up/Down, Enter, Escape.
class eFileLineEdit : public eLineEdit {
public:
    eFileLineEdit(eMainWindow* const w, eFileWidget* const fw) :
        eLineEdit(w), mFW(fw) {}
protected:
    bool keyPressEvent(const eKeyPressEvent& e) override {
        const auto k = e.key();
        if(k == SDL_SCANCODE_UP) {
            mFW->moveSelection(-1);
        } else if(k == SDL_SCANCODE_DOWN) {
            mFW->moveSelection(1);
        } else if(k == SDL_SCANCODE_RETURN || k == SDL_SCANCODE_KP_ENTER) {
            mFW->accept();
        } else if(k == SDL_SCANCODE_ESCAPE) {
            mFW->cancel();
        } else {
            return eLineEdit::keyPressEvent(e);
        }
        return true;
    }
private:
    eFileWidget* const mFW;
};
}

// A saved city: its name, and on the right how long ago it was played.
class eSaveRow : public eButtonBase {
public:
    eSaveRow(eMainWindow* const w, const std::string& when) :
        eButtonBase(w), mWhen(when) {}
    ~eSaveRow() {
        if(mWhenTex) SDL_DestroyTexture(mWhenTex);
    }

    void setSelected(const bool s) { mSelected = s; }
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
        const auto r = p.renderer();
        const auto white = eMenuScene::instance().whiteTexture();
        eGeometryBatch::sFlush();
        const float x = static_cast<float>(p.x());
        const float y = static_cast<float>(p.y());
        const float w = static_cast<float>(width());
        const float h = static_cast<float>(height());
        const auto a = [](const double v) { return static_cast<Uint8>(std::round(255*std::min(1.0, v))); };
        SDL_SetTextureBlendMode(white, SDL_BLENDMODE_BLEND);
        {
            // resting rows: faint stone band, so the list reads as rows
            const double sel = mSel;
            const double hv = mHover*(1 - sel);
            const SDL_Color l{static_cast<Uint8>(34 + 78*sel + 18*hv), static_cast<Uint8>(52 + 40*sel + 20*hv),
                              static_cast<Uint8>(84 - 44*sel + 26*hv), a(0.35 + 0.5*sel + 0.35*hv)};
            const SDL_Color rr{l.r, l.g, l.b, a(0.12 + 0.2*sel + 0.1*hv)};
            const SDL_FPoint q[4] = {{x, y}, {x + w, y}, {x + w, y + h}, {x, y + h}};
            const SDL_Color cs[4] = {l, rr, rr, l};
            eMenu3D::drawFlat(r, white, q, cs);
            SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_BLEND);
            if(sel > 0.01) {
                SDL_SetRenderDrawColor(r, 255, 214, 92, a(sel));
                const SDL_FRect bar{x, y + 2, std::max(2.f, h*0.07f), h - 4};
                SDL_RenderFillRectF(r, &bar);
            }
            SDL_SetRenderDrawColor(r, 212, 175, 55, a(0.25 + 0.35*sel));
            const SDL_FRect rule{x, y + h - 1, w, 1};
            SDL_RenderFillRectF(r, &rule);
        }
        if(!mWhenTex && !mWhen.empty()) {
            const auto font = eFonts::defaultFont(resolution().verySmallFontSize());
            mWhenTex = eMenu3D::makeText(r, font, mWhen, SDL_Color{214, 190, 132, 255}, mWhenW, mWhenH);
        }
        if(mWhenTex) {
            SDL_SetTextureAlphaMod(mWhenTex, a(0.75 + 0.25*std::max(mSel, mHover)));
            const SDL_FRect d{x + w - mWhenW - h*0.4f, y + (h - mWhenH)*0.5f, float(mWhenW), float(mWhenH)};
            SDL_RenderCopyF(r, mWhenTex, nullptr, &d);
        }
        p.save();
        p.translate(static_cast<int>(h*0.4) + static_cast<int>(5*mSel), 0);
        eButtonBase::paintEvent(p);
        p.restore();
    }
private:
    std::string mWhen;
    SDL_Texture* mWhenTex = nullptr;
    int mWhenW = 0;
    int mWhenH = 0;
    bool mSelected = false;
    double mHover = 0;
    double mSel = 0;
    Uint64 mLast = 0;
    int mColorState = -1;
};

eFileWidget::~eFileWidget() {
    if(mFilesWidget) {
        mFilesWidget->deleteLater();
        mFilesWidget = nullptr;
    }
}

void eFileWidget::intialize(const std::string& title,
                            const std::string& folder,
                            const eFileFunc& func,
                            const eAction& closeAction) {
    mFolder = folder;
    mFunc = func;
    mCloseAction = closeAction;

    setType(eFrameType::message);

    const int p = padding();
    const auto res = window()->resolution();
    const int ww = std::min(window()->width() - 4*p, static_cast<int>(560*res.multiplier()));
    const int hh = std::min(window()->height() - 4*p, static_cast<int>(440*res.multiplier()));

    resize(ww, hh);

    mTitleLabel = new eLabel(title, window());
    mTitleLabel->setHugeFontSize();
    mTitleLabel->setYellowFontColor();
    mTitleLabel->fitContent();
    addWidget(mTitleLabel);
    mTitleLabel->align(eAlignment::top | eAlignment::hcenter);
    mTitleLabel->setY(mTitleLabel->y() + p);

    mOk = new eAcceptButton(window());
    addWidget(mOk);
    mOk->align(eAlignment::bottom | eAlignment::right);
    mOk->move(mOk->x() - 2*p, mOk->y() - 2*p);
    mOk->setPressAction([this] {
        accept();
    });

    mCancel = new eCancelButton(window());
    addWidget(mCancel);
    mCancel->align(eAlignment::bottom | eAlignment::left);
    mCancel->move(mCancel->x() + 2*p, mCancel->y() - 2*p);
    mCancel->setPressAction(closeAction);

    mDelete = new eFramedButton(window());
    mDelete->setRenderBg(true);
    mDelete->setUnderline(false);
    mDelete->setText(eLanguage::zeusText(287, 1));
    mDelete->setSmallFontSize();
    mDelete->fitContent();
    mDelete->setWidth(mDelete->width() + 4*p);
    mDelete->setHeight(mDelete->height() + p);
    addWidget(mDelete);
    mDelete->align(eAlignment::bottom | eAlignment::hcenter);
    mDelete->setY(mCancel->y() + (mCancel->height() - mDelete->height()) / 2);
    mDelete->setMouseEnterAction([this]() {
        if(mDelete) mDelete->setYellowFontColor();
    });
    mDelete->setMouseLeaveAction([this]() {
        if(mDelete) mDelete->setLightFontColor();
    });
    mDelete->setPressAction([this]() {
        if(mLineEdit && !mLineEdit->text().empty()) {
            confirmDelete(mLineEdit->text());
        }
    });

    const auto lineW = new eFramedWidget(window());
    lineW->setType(eFrameType::inner);
    lineW->setNoPadding();
    mLineEdit = new eFileLineEdit(window(), this);
    mLineEdit->setTinyPadding();
    mLineEdit->setText("A");
    mLineEdit->fitContent();
    mLineEdit->setSmallFontSize();
    mLineEdit->setText("");
    lineW->addWidget(mLineEdit);
    mLineEdit->setX(p);
    const int lineY = mTitleLabel->y() + mTitleLabel->height() + p;
    lineW->setY(lineY);
    lineW->setX(2*p);
    addWidget(lineW);

    mScrollCont = new eScrollWidgetComplete(window());
    addWidget(mScrollCont);
    mScrollCont->resize(ww - 4*p, hh - lineY - mLineEdit->height() - 10*p);
    mScrollCont->setY(lineY + mLineEdit->height() + 2*p);
    mScrollCont->setX(2*p);
    mScrollCont->initialize();

    const int swwidth = mScrollCont->listWidth();
    mLineEdit->resize(swwidth - 2*p, mLineEdit->height());
    lineW->resize(swwidth, mLineEdit->height());

    mLineEdit->grabKeyboard();

    refreshFileList();
}

void eFileWidget::refreshFileList() {
    if(!mScrollCont) return;

    const int swwidth = mScrollCont->listWidth();
    const auto filesWidget = new eWidget(window());
    filesWidget->setNoPadding();

    const auto saves = eSaveInfo::sList(mFolder);

    mRows.clear();
    mNames.clear();
    mSelected = -1;
    int y = 0;
    if(saves.empty()) {
        const auto emptyMsg = new eLabel(tr("menu_no_saves", "No saved adventures yet"), window());
        emptyMsg->setSmallFontSize();
        emptyMsg->setLightFontColor();
        emptyMsg->fitContent();
        filesWidget->addWidget(emptyMsg);
        emptyMsg->setY(y + 16);
        y += emptyMsg->height() + 8;

        const auto emptySub = new eLabel(tr("menu_no_saves_hint", "Begin a New Adventure to found your city."), window());
        emptySub->setVerySmallFontSize();
        emptySub->setYellowFontColor();
        emptySub->fitContent();
        filesWidget->addWidget(emptySub);
        emptySub->setY(y + 16);
        y += emptySub->height() + 16;
    } else {
        for(const auto& s : saves) {
            const auto name = s.fName;
            const int id = static_cast<int>(mRows.size());

            // Row delete button (right side)
            const auto delBtn = new eFramedButton(window());
            delBtn->setRenderBg(true);
            delBtn->setUnderline(false);
            delBtn->setText("X");
            delBtn->setSmallFontSize();
            delBtn->fitContent();
            const int btnH = delBtn->height() + 12;
            const int delW = btnH;
            delBtn->setWidth(delW);
            delBtn->setHeight(btnH);
            delBtn->setTextAlignment(eAlignment::center);
            delBtn->setTooltip(eLanguage::zeusText(287, 1));
            delBtn->setMouseEnterAction([delBtn]() {
                delBtn->setYellowFontColor();
            });
            delBtn->setMouseLeaveAction([delBtn]() {
                delBtn->setLightFontColor();
            });
            delBtn->setPressAction([this, name]() {
                confirmDelete(name);
            });

            // Save file row: name, and when it was last played
            const auto b = new eSaveRow(window(), eSaveInfo::sAgo(s.fTime) + "    " +
                                                  eSaveInfo::sStamp(s.fTime));
            b->setText(name);
            b->setSmallFontSize();
            b->fitContent();
            b->setWidth(swwidth - delW - 6);
            b->setHeight(btnH);
            b->setTextAlignment(eAlignment::left | eAlignment::vcenter);
            b->setPressAction([this, id]() {
                rowPressed(id);
            });

            filesWidget->addWidget(b);
            b->setX(0);
            b->setY(y);

            filesWidget->addWidget(delBtn);
            delBtn->setX(swwidth - delW);
            delBtn->setY(y);

            mRows.push_back(b);
            mNames.push_back(name);
            y += btnH + 4;
        }
    }
    filesWidget->fitContent();

    if(mFilesWidget) {
        mFilesWidget->deleteLater();
    }
    mFilesWidget = filesWidget;

    mScrollCont->setScrollArea(mFilesWidget);
    mScrollCont->clampDY();
}

void eFileWidget::confirmDelete(const std::string& name) {
    if(name.empty()) return;
    const auto targetFile = mFolder + name + ".ez";
    if(!std::filesystem::exists(targetFile)) return;

    const auto qw = new eQuestionWidget(window());
    const auto acceptA = [this, name, targetFile]() {
        std::error_code ec;
        std::filesystem::remove(targetFile, ec);
        eSounds::playButtonSound();
        if(mLineEdit && mLineEdit->text() == name) {
            mLineEdit->setText("");
        }
        refreshFileList();
    };
    qw->initialize(eLanguage::zeusText(14, 179),
                   eLanguage::zeusText(14, 180),
                   acceptA, nullptr);
    window()->execDialog(qw);
    qw->align(eAlignment::center);
}

void eFileWidget::setFileName(const std::string& path) {
    mLineEdit->setText(path);
}

void eFileWidget::select(const int id) {
    if(id < 0 || id >= static_cast<int>(mRows.size())) return;
    if(mSelected >= 0 && mSelected < static_cast<int>(mRows.size())) {
        mRows[mSelected]->setSelected(false);
    }
    mSelected = id;
    mRows[id]->setSelected(true);
    setFileName(mNames[id]);
    if(mScrollCont) mScrollCont->ensureVisible(mRows[id]->y(), mRows[id]->height());
}

void eFileWidget::rowPressed(const int id) {
    const Uint64 now = SDL_GetPerformanceCounter();
    const double since = double(now - mLastPressTime)/SDL_GetPerformanceFrequency();
    const bool twice = id == mLastPressId && since < 0.45;
    mLastPressId = id;
    mLastPressTime = now;
    select(id);
    if(twice && mAcceptOnDoubleClick) accept();
}

void eFileWidget::moveSelection(const int d) {
    const int n = static_cast<int>(mRows.size());
    if(n == 0) return;
    if(mSelected < 0) select(d > 0 ? 0 : n - 1);
    else select(std::max(0, std::min(n - 1, mSelected + d)));
}

void eFileWidget::accept() {
    if(!mLineEdit || mLineEdit->text().empty()) return;
    const auto path = filePath();
    const auto func = mFunc;
    const auto close = mCloseAction;
    if(func && func(path) && close) close();
}

void eFileWidget::cancel() {
    if(mCloseAction) mCloseAction();
}

std::string eFileWidget::filePath() const {
    return mFolder + mLineEdit->text() + ".ez";
}
