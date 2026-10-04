#include "esettingsmenu.h"

#include "echeckbox.h"
#include "eframedbutton.h"
#include "eframedwidget.h"
#include "elabeledwidget.h"
#include "eokbutton.h"

#include "econtrolsmenu.h"
#include "egamedir.h"
#include "elanguage.h"
#include "emainwindow.h"
#include "emenubutton.h"
#include "textures/egeometrybatch.h"

#include <filesystem>

eSettingsMenu::eSettingsMenu(const eSettings &iniSettings,
                             eMainWindow *const window)
    : eMainMenuBase(window), mIniSettings(iniSettings), mSettings(iniSettings) {

}

eWidget *createTextureBox(eMainWindow *const window, const bool checked,
                          const eCheckAction &checkA, const std::string &text,
                          const int p, const std::string &path) {
  const bool missing = !std::filesystem::exists(path);
  const auto w = new eWidget(window);
  w->setNoPadding();

  const auto b = new eCheckBox(window);
  b->setNoPadding();
  b->setChecked(checked);
  b->setCheckAction(checkA);
  b->fitContent();
  if (missing)
    b->hide();

  const auto l = new eLabel(window);
  l->setNoPadding();
  l->setSmallFontSize();
  l->setText(text);
  l->fitContent();

  w->addWidget(b);
  w->addWidget(l);
  l->setX(b->width() + p);
  w->fitContent();

  return w;
}

namespace {
std::string tr(const std::string &key, const std::string &fallback) {
  const auto &s = eLanguage::text(key);
  return s.empty() ? fallback : s;
}

// Section title with a fading gold rule beneath.
class eMenuHeading : public eLabel {
public:
  using eLabel::eLabel;

protected:
  void paintEvent(ePainter &p) override {
    eLabel::paintEvent(p);
    const int t = std::max(1, height() / 28);
    const int w = width();
    const int steps = 8;
    for (int i = 0; i < steps; i++) {
      const Uint8 a = static_cast<Uint8>(200 * (steps - i) / steps);
      p.fillRect(SDL_Rect{i * w / steps, height() - t, w / steps + 1, t},
                 SDL_Color{212, 175, 55, a});
    }
  }
};
} // namespace

void eSettingsMenu::initialize(const eApplyAction &settingsA,
                               const eFullscreenA &fullscreenA) {
  eMainMenuBase::initialize(eMenuShot::settings);
  setBackAction([this]() { window()->showMainMenu(); });

  const auto res = resolution();
  const int p = res.largePadding();
  const double u = std::min(height() / 1080., width() / 1500.);
  const auto U = [u](const double v) {
    return static_cast<int>(std::round(v * u));
  };

  const auto title = new eLabel(window());
  title->setHugeFontSize();
  title->setYellowFontColor();
  title->setText(eLanguage::zeusText(2, 0));
  title->fitContent();
  addWidget(title);
  title->align(eAlignment::hcenter);
  title->setY(U(44));

  const int barH = U(64);
  const int frameW = std::min(width() - U(80), U(1180));
  const int top = title->y() + title->height() + U(22);
  const int frameH = height() - top - barH - U(70);
  const auto frame = new eFramedWidget(window());
  frame->setType(eFrameType::message);
  frame->resize(frameW, frameH);
  frame->move((width() - frameW) / 2, top);
  addWidget(frame);

  const auto inner = new eWidget(window());
  inner->setNoPadding();
  frame->addWidget(inner);
  inner->move(3 * p, 3 * p);
  inner->resize(frameW - 6 * p, frameH - 6 * p);

  const int gap = U(48);
  const int leftW = (inner->width() - gap) * 44 / 100;
  const int rightW = inner->width() - gap - leftW;

  const auto left = new eWidget(window());
  left->setNoPadding();
  left->resize(leftW, inner->height());
  inner->addWidget(left);

  const auto right = new eWidget(window());
  right->setNoPadding();
  right->resize(rightW, inner->height());
  right->move(leftW + gap, 0);
  inner->addWidget(right);

  const auto heading = [&](eWidget *const col, const std::string &text,
                           const int y) {
    const auto h = new eMenuHeading(window());
    h->setSmallFontSize();
    h->setYellowFontColor();
    h->setNoPadding();
    h->setText(text);
    h->fitContent();
    h->setTextAlignment(eAlignment::left | eAlignment::top);
    h->resize(col->width(), h->height() + U(10));
    h->move(0, y);
    col->addWidget(h);
    return y + h->height() + U(16);
  };

  // --- display -------------------------------------------------------------
  int y = heading(left, tr("menu_display", "Display"), 0);
  {
    const auto fs = new eMenuButton(window());
    fs->setup(mSettings.fFullscreen ? eLanguage::zeusText(42, 2) : // windowed
                  eLanguage::zeusText(42, 1), // full screen
              eMenuButton::eStyle::secondary, leftW);
    fs->move(0, y);
    left->addWidget(fs);
    fs->setPressAction([this, fs, fullscreenA]() {
      const bool f = !mSettings.fFullscreen;
      mSettings.fFullscreen = f;
      fullscreenA(f);
      fs->setText(f ? eLanguage::zeusText(42, 2) : eLanguage::zeusText(42, 1));
    });
    y += fs->height() + U(30);
  }

  // --- language --------------------------------------------------------------
  y = heading(left, eLanguage::text("language"), y);
  {
    const auto langRow = [&](const std::string &label,
                             std::string *const value) {
      const auto l = new eLabel(window());
      l->setSmallFontSize();
      l->setNoPadding();
      l->setText(label + ":");
      l->fitContent();
      left->addWidget(l);
      const int bw = U(96);
      const auto en = new eMenuButton(window());
      en->setup("EN", eMenuButton::eStyle::secondary, bw);
      const auto ru = new eMenuButton(window());
      ru->setup("RU", eMenuButton::eStyle::secondary, bw);
      en->setSelected(*value != "ru");
      ru->setSelected(*value == "ru");
      en->setPressAction([value, en, ru]() {
        *value = "en";
        en->setSelected(true);
        ru->setSelected(false);
      });
      ru->setPressAction([value, en, ru]() {
        *value = "ru";
        ru->setSelected(true);
        en->setSelected(false);
      });
      left->addWidget(en);
      left->addWidget(ru);
      const int ew = std::max(en->width(), ru->width());
      en->setWidth(ew);
      ru->setWidth(ew);
      ru->move(leftW - ew, y);
      en->move(ru->x() - U(12) - ew, y);
      l->move(0, y + (en->height() - l->height()) / 2);
      y += en->height() + U(12);
    };
    langRow(eLanguage::text("language"), &mSettings.fLanguage);
    langRow(eLanguage::text("audio_language"), &mSettings.fAudioLanguage);
    y += U(18);
  }

  // --- textures
  // ----------------------------------------------------------------
  y = heading(left, tr("menu_textures", "Textures"), y);
  {
    const auto box = [&](const bool checked, const eCheckAction &a,
                         const std::string &key, const std::string &path) {
      const auto w =
          createTextureBox(window(), checked, a, eLanguage::text(key), p, path);
      left->addWidget(w);
      w->move(0, y);
      y += w->height() + U(8);
    };
    box(
        mSettings.fTinyTextures,
        [this](const bool c) { mSettings.fTinyTextures = c; }, "tiny_textures",
        eGameDir::i15BinaryPath());
    box(
        mSettings.fSmallTextures,
        [this](const bool c) { mSettings.fSmallTextures = c; },
        "small_textures", eGameDir::i30BinaryPath());
    box(
        mSettings.fMediumTextures,
        [this](const bool c) { mSettings.fMediumTextures = c; },
        "medium_textures", eGameDir::i45BinaryPath());
    box(
        mSettings.fLargeTextures,
        [this](const bool c) { mSettings.fLargeTextures = c; },
        "large_textures", eGameDir::i60BinaryPath());
    y += U(22);
  }

  // --- controls
  // ------------------------------------------------------------------
  {
    const auto controlsBtn = new eMenuButton(window());
    controlsBtn->setup(eLanguage::text("controls"),
                       eMenuButton::eStyle::secondary, leftW);
    controlsBtn->move(0, std::min(y, left->height() - controlsBtn->height()));
    controlsBtn->setPressAction([this]() {
      const auto cm = new eControlsMenu(
          mSettings.fKeyBindings, window(),
          [this](const eKeyBindings &b) { mSettings.fKeyBindings = b; });
      cm->initialize();
      window()->execDialog(cm);
      cm->align(eAlignment::center);
    });
    left->addWidget(controlsBtn);
  }

  // --- resolution grid
  // ---------------------------------------------------------------
  {
    int ry = heading(right, tr("menu_resolution", "Resolution"), 0);
    const auto &ress = eResolution::sResolutions;
    const int cols = 3;
    const int cgap = U(12);
    const int bw = (rightW - (cols - 1) * cgap) / cols;
    const auto buttons = std::make_shared<std::vector<eMenuButton *>>();
    int bh = 0;
    for (int i = 0; i < static_cast<int>(ress.size()); i++) {
      const auto r = ress[i];
      const auto b = new eMenuButton(window());
      b->setup(r.name(), eMenuButton::eStyle::secondary, bw);
      b->setWidth(bw);
      bh = b->height();
      b->move((i % cols) * (bw + cgap), ry + (i / cols) * (bh + U(10)));
      b->setSelected(r == mSettings.fRes);
      b->setPressAction([this, buttons, b, r]() {
        for (const auto o : *buttons)
          o->setSelected(o == b);
        mSettings.fRes = r;
      });
      buttons->push_back(b);
      right->addWidget(b);
    }

    // --- game ---------------------------------------------------------------
    const int rows = (static_cast<int>(ress.size()) + cols - 1) / cols;
    int gy = ry + rows * (bh + U(10)) + U(20);
    gy = heading(right, tr("menu_game", "Game"), gy);
    const auto check = [&](const bool checked, const eCheckAction &a,
                           const std::string &text) {
      const auto w = new eWidget(window());
      w->setNoPadding();
      const auto b = new eCheckBox(window());
      b->setNoPadding();
      b->setChecked(checked);
      b->setCheckAction(a);
      b->fitContent();
      const auto l = new eLabel(window());
      l->setNoPadding();
      l->setSmallFontSize();
      l->setText(text);
      l->fitContent();
      w->addWidget(b);
      w->addWidget(l);
      l->setX(b->width() + p);
      w->fitContent();
      right->addWidget(w);
      w->move(0, gy);
      gy += w->height() + U(8);
    };
    check(
        mSettings.fMonthlySummary,
        [this](const bool c) { mSettings.fMonthlySummary = c; },
        tr("menu_monthly_summary", "Monthly summary card"));
    check(
        mSettings.fWeather, [this](const bool c) { mSettings.fWeather = c; },
        tr("menu_weather", "Seasons and weather"));
    check(
        mSettings.fClassicFont,
        [this](const bool c) { mSettings.fClassicFont = c; },
        tr("menu_classic_font", "Classic font for all text"));
  }

  // --- action bar
  // ------------------------------------------------------------------------
  const int barY = top + frameH + U(22);
  const auto cancel = new eMenuButton(window());
  cancel->setup(tr("menu_cancel", "Cancel"), eMenuButton::eStyle::secondary,
                U(220));
  cancel->setHeight(barH);
  cancel->move(frame->x(), barY);
  cancel->setPressAction([this]() { window()->showMainMenu(); });
  addWidget(cancel);

  const auto ok = new eMenuButton(window());
  ok->setup(tr("menu_apply", "Apply"), eMenuButton::eStyle::primary, U(260));
  ok->setHeight(barH);
  ok->move(frame->x() + frameW - ok->width(), barY);
  ok->setPressAction([this, settingsA]() { settingsA(mSettings); });
  addWidget(ok);
}
