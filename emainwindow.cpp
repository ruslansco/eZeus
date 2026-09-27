#include "emainwindow.h"

#include "widgets/emainmenu.h"
#include "widgets/esettingsmenu.h"
#include "widgets/egamewidget.h"
#include "widgets/egameloadingwidget.h"
#include "widgets/egamemenu.h"
#include "widgets/emenuloadingwidget.h"
#include "textures/eterrainhd.h"
#include "textures/egeometrybatch.h"
#include "ebenchtimers.h"
#include "characters/echaracter.h"
#include "widgets/eworldwidget.h"
#include "widgets/echoosegameeditmenu.h"
#include "widgets/eselectcolonywidget.h"

#include "audio/emusic.h"
#include "audio/esounds.h"

#include "engine/ethreadpool.h"

#include "egamedir.h"

#include "fileIO/ereadstream.h"

#include <array>
#include <map>
#include <set>
#include <ctime>
#include <chrono>
#include <filesystem>
#include <fstream>

#include "widgets/efilewidget.h"
#include "widgets/esaveinfo.h"
#include "widgets/emenuscene.h"
#include "elanguage.h"
#include "emessages.h"
#include "widgets/efonts.h"

#include "evectorhelpers.h"

#include "widgets/eeventbackground.h"
#include "widgets/eepisodeintroductionwidget.h"
#include "widgets/eepisodelostwidget.h"
#include "widgets/erosterofleaders.h"

eMainWindow::eMainWindow() {}

eMainWindow::~eMainWindow() {
    if(mSdlWindow) SDL_DestroyWindow(mSdlWindow);
    if(mSdlRenderer) SDL_DestroyRenderer(mSdlRenderer);
    setWidget(nullptr);
}

bool eMainWindow::initialize(const eSettings& settings) {
    const auto& res = settings.fRes;
    // Screenshot mode (development aid): EZEUS_SHOT="<save.ez>;<out.png>;<zoom 0-3>[;<fx>;<fy>]"
    // loads the save in a hidden 1920x1080 window, captures one frame and quits.
    // EZEUS_MENU_SHOT (see exec()) captures a front-end screen the same way;
    // EZEUS_MENU_SHOT_SIZE="1280x720" picks another window size for it.
    const bool menuShot = getenv("EZEUS_MENU_SHOT") != nullptr;
    const bool shot = getenv("EZEUS_SHOT") != nullptr || menuShot;
    int w = shot ? 1920 : res.width();
    int h = shot ? 1080 : res.height();
    if(shot) {
        if(const char* const sz = getenv("EZEUS_MENU_SHOT_SIZE")) {
            int sw = 0, sh = 0;
            if(sscanf(sz, "%dx%d", &sw, &sh) == 2 && sw >= 640 && sh >= 480) {
                w = sw;
                h = sh;
            }
        }
    }
    Uint32 windowFlags = shot ? SDL_WINDOW_HIDDEN : (SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);
    if(settings.fFullscreen && !shot) {
        windowFlags |= SDL_WINDOW_FULLSCREEN_DESKTOP;
    }
    const auto window = SDL_CreateWindow("eZeus",
                                         SDL_WINDOWPOS_UNDEFINED,
                                         SDL_WINDOWPOS_UNDEFINED,
                                         w, h, windowFlags);

    if(!window) {
        printf("Window could not be created! SDL Error: %s\n",
               SDL_GetError());
        return false;
    }
    SDL_SetWindowMinimumSize(window, 800, 600);
    Uint32 flags = SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC;
    auto renderer = SDL_CreateRenderer(window, -1, flags);
    if(!renderer) {
        flags = SDL_RENDERER_ACCELERATED;
        renderer = SDL_CreateRenderer(window, -1, flags);
    }
    if(!renderer) {
        printf("Renderer could not be created! SDL Error: %s\n",
               SDL_GetError());
        SDL_DestroyWindow(window);
        return false;
    }
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");

    if(mSdlWindow) SDL_DestroyWindow(mSdlWindow);
    if(mSdlRenderer) SDL_DestroyRenderer(mSdlRenderer);
    mSdlWindow = window;
    mSdlRenderer = renderer;
    setResolution(shot ? eResolution(w, h) : res);
    if(!shot) setFullscreen(settings.fFullscreen);
    mSettings = settings;
    if(shot) {
        mSettings.fRes = eResolution(w, h);
        mSettings.fFullscreen = false;
        // EZEUS_MENU_SHOT_LANG=ru|en checks a translation
        if(const char* const lang = getenv("EZEUS_MENU_SHOT_LANG")) {
            mSettings.fLanguage = lang;
        }
    }
    eGameDir::setAudioLanguage(mSettings.fAudioLanguage);
    eFonts::setLanguage(mSettings.fLanguage);
    SDL_SetWindowPosition(window, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED);

    const std::string icoPath = eGameDir::path("zeus.ico");
    const auto icon = IMG_Load(icoPath.c_str());
    SDL_SetWindowIcon(window, icon);
    eGameTextures::setSettings(mSettings);
    return true;
}

void eMainWindow::setWidget(eWidget* const w) {
    if(mWidget) {
        if(mWidget != mGW && mWidget != mWW) {
            mWidget->deleteLater();
        }
    }
    mWidget = w;
}

eWidget* eMainWindow::takeWidget() {
    const auto w = mWidget;
    mWidget = nullptr;
    return w;
}

void eMainWindow::addSlot(const eSlot& slot) {
    mSlots.push_back(slot);
}

void eMainWindow::setResolution(const eResolution& res) {
    if(mSettings.fRes == res && !mFirstResolutionSetting) return;
    mFirstResolutionSetting = false;
    mSettings.fRes = res;
    const int w = res.width();
    const int h = res.height();
    SDL_SetWindowSize(mSdlWindow, w, h);
    SDL_SetWindowPosition(mSdlWindow, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED);
    if(mWidget) {
        mWidget->resize(w, h);
    }
}

void eMainWindow::setFullscreen(const bool f) {
    if(mSettings.fFullscreen == f && !mFirstFullscrenSetting) return;
    mFirstFullscrenSetting = false;
    mSettings.fFullscreen = f;
    SDL_SetWindowFullscreen(mSdlWindow, f ? SDL_WINDOW_FULLSCREEN_DESKTOP : 0);
    mSettings.write();
}

void eMainWindow::startGameAction(eGameBoard* const board,
                                  const eGameWidgetSettings& settings) {
    const auto show = [this, board, settings]() {
        showGame(board, settings);
    };
    startGameAction(show);
}

void eMainWindow::startGameAction(const stdsptr<eCampaign>& c,
                                  const eGameWidgetSettings& settings) {
    const auto show = [this, c, settings]() {
        showGame(c, settings);
    };
    startGameAction(show);
}

void eMainWindow::startGameAction(const eAction& a) {
    clearWidgets();
    const auto l = new eGameLoadingWidget(this);
    l->resize(width(), height());
    l->setDoneAction(a);
    setWidget(l);
    l->initialize();
}

void eMainWindow::showEpisodeIntroduction(
        const stdsptr<eCampaign>& c) {
    clearWidgets();
    if(c) mCampaign = c;
    const auto e = new eEpisodeIntroductionWidget(this);
    const auto proceedA = [this]() {
        mCampaign->startEpisode();
        const auto dir = leaderSaveDir();
        saveGame(dir + "autosave replay.ez");
        startGameAction([this]() {
            eGameWidgetSettings settings;
            settings.fPaused = true;
            showGame(mCampaign, settings);
        });
    };
    e->resize(width(), height());
    const auto ee = mCampaign->currentEpisode();

    const auto path = mCampaign->currentEpisodeAudioFilePath(true);
    const bool played = eMusic::playCampaignVoice(path);
    if(!played) eMusic::playMissionIntroMusic();

    e->initialize(mCampaign,
                  mCampaign->titleText(),
                  ee->fIntroduction,
                  ee->fGoals,
                  proceedA,
                  eEpisodeIntroType::intro);
    setWidget(e);
}

std::string eMainWindow::leaderSaveDir() const {
    return eGameDir::saveDir() + mLeader + "/";
}

void eMainWindow::clearWidgets() {
    if(mGW && mWidget != mGW) {
        mGW->setBoard(nullptr);
        mGW->deleteLater();
        mGW = nullptr;
    }
    if(mWW && mWidget != mWW) {
        mWW->deleteLater();
        mWW = nullptr;
    }
}

void eMainWindow::episodeFinished() {
    clearWidgets();
    if(!mCampaign) return;
    mCampaign->episodeFinished();
    const bool f = mCampaign->finished();
    if(f) return adventureComplete();
    const auto n = mCampaign->currentEpisodeType();
    if(n == eEpisodeType::parentCity) {
        showEpisodeIntroduction();
    } else {
        const auto w = new eSelectColonyWidget(this);
        const auto sel = mCampaign->remainingColonies();
        const auto selA = [this](const stdsptr<eWorldCity>& c) {
            int cid = 0;
            const auto& eps = mCampaign->colonyEpisodes();
            for(const auto& e : eps) {
                if(e->fCity == c) break;
                cid++;
            }
            mCampaign->setCurrentColonyEpisode(cid);
            showEpisodeIntroduction();
        };
        w->resize(width(), height());
        w->initialize(sel, selA, &mCampaign->worldBoard());
        setWidget(w);
    }
}

void eMainWindow::adventureComplete() {
    clearWidgets();
    if(!mCampaign) return;
    const auto e = new eEpisodeIntroductionWidget(this);
    const auto proceedA = [this]() {
        showMainMenu();
    };
    e->resize(width(), height());

    const auto path = mCampaign->adventureVictoryAudioFilePath();
    const bool played = eMusic::playCampaignVoice(path);
    if(!played) eMusic::playCampaignVictoryMusic();

    e->initialize(mCampaign,
                  eLanguage::zeusText(62, 0),
                  mCampaign->completeText(),
                  {},
                  proceedA,
                  eEpisodeIntroType::campaingVictory);
    setWidget(e);
}

void eMainWindow::episodeLost() {
    clearWidgets();
    const auto e = new eEpisodeLostWidget(this);
    const auto proceedA = [this]() {
        showMainMenu();
    };
    e->resize(width(), height());
    e->initialize(proceedA);
    setWidget(e);
}

bool eMainWindow::saveGame(const std::string& path) {
    // A long screenshot / benchmark run can cross a new year and trigger
    // the autosave.
    if(sSavingDisabled()) {
        printf("EZEUS_SHOT: skipped saving %s\n", path.c_str());
        return false;
    }
    return saveGameUnchecked(path);
}

bool eMainWindow::saveGameUnchecked(const std::string& path) {
    const auto fsp = std::filesystem::path(path);
    const auto fspd = fsp.parent_path();
    std::filesystem::create_directories(fspd);
    std::ofstream file(path, std::ios::out | std::ios::binary |
                       std::ios::trunc);
    if(!file) return false;
    eWriteTarget target(&file);
    eWriteStream dst(target);
    dst.writeFormat("eZeus.ez");
    if(mGW) {
        const auto s = mGW->settings();
        s.write(dst);
    } else {
        eGameWidgetSettings s;
        s.fPaused = true;
        s.write(dst);
    }
    mCampaign->write(dst);
    file.close();
    return true;
}

bool eMainWindow::loadGame(const std::string& path) {
    std::ifstream file(path, std::ios::in | std::ios::binary);
    if(!file) return false;
    eReadSource source(&file);
    eReadStream src(source);
    src.readFormat();
    const auto& format = src.format();
    const int version = src.formatVersion();
    if(format != "eZeus.ez") {
        printf("Invalid file '%s' format '%s', expected 'eZeus.ez'.\n",
               path.c_str(), format.c_str());
        return false;
    }
    if(version > eFileFormat::version) {
        printf("Attempting to read '%s' format '%s' version '%i' newer than the executable.\n",
               path.c_str(), format.c_str(), version);
    }
    eGameWidgetSettings s;
    s.read(src);
    const auto c = std::make_shared<eCampaign>();
    c->read(src);
    c->loadStrings();
    c->loadNumbers();
    src.handlePostFuncs();
    file.close();

    startGameAction(c, s);
    return true;
}

void eMainWindow::closeGame() {
    if(!mGW) return;
    if(mGW) {
        mGW->setBoard(nullptr);
        mGW->deleteLater();
        mGW = nullptr;
    }
    if(mWW) {
        mWW->deleteLater();
        mWW = nullptr;
    }
    showMainMenu();
}

void eMainWindow::showRosterOfLeaders() {
    clearWidgets();
    eMusic::playMenuMusic();
    const auto rol = new eRosterOfLeaders(this);
    rol->resize(width(), height());
    rol->initialize();
    setWidget(rol);
}

void eMainWindow::showMenuLoading() {
    const auto mlw = new eMenuLoadingWidget(this);
    mlw->setDoneAction([this]() {
        const auto ls = eRosterOfLeaders::sLeaders();
        if(!mSettings.fLeader.empty()) {
            for(const auto& l : ls) {
                if(l == mSettings.fLeader) {
                    setLeader(l);
                    break;
                }
            }
        }
        if(mLeader.empty() && !ls.empty()) {
            setLeader(ls[0]);
        }
        if(mLeader.empty()) {
            showRosterOfLeaders();
        } else {
            showMainMenu();
        }
    });
    mlw->initialize();
    mlw->resize(width(), height());
    setWidget(mlw);
}

void eMainWindow::showLoadDialog(eWidget* const parent) {
    const auto fw = new eFileWidget(this);
    const auto func = [this](const std::string& path) {
        return loadGame(path);
    };
    const auto closeAct = [fw]() {
        fw->deleteLater();
    };
    const auto dir = leaderSaveDir();
    fw->intialize(eLanguage::zeusText(1, 3),
                  dir, func, closeAct);
    fw->setAcceptOnDoubleClick(true);
    execDialog(fw, true, closeAct, parent);
    fw->align(eAlignment::center);
}

void eMainWindow::showMainMenu() {
    mCampaign = nullptr;
    clearWidgets();
    eMusic::playMenuMusic();

    const auto mm = new eMainMenu(this);
    mm->resize(width(), height());
    setWidget(mm);

    // one click back into the most recent city
    const auto saves = eSaveInfo::sList(leaderSaveDir());
    if(!saves.empty()) {
        const auto& s = saves.front();
        const auto path = s.fPath;
        mm->setContinue(s.fName + "   -   " + eSaveInfo::sAgo(s.fTime),
                        [this, path]() {
            if(!loadGame(path)) showMainMenu();
        });
    }

    const auto newGameAction = [this]() {
        showChooseGameMenu();
    };

    const auto loadGameAction = [this, mm]() {
        showLoadDialog(mm);
    };

    const auto editGameAction = [this]() {
        showChooseGameEditMenu();
    };

    const auto settingsAction = [this]() {
        showSettingsMenu();
    };

    const auto quitAction = [this]() {
        mQuit = true;
    };

    const auto leaderAction = [this]() {
        showRosterOfLeaders();
    };

    mm->initialize(newGameAction,
                   loadGameAction,
                   editGameAction,
                   settingsAction,
                   quitAction,
                   leaderAction);
}

void eMainWindow::showSettingsMenu() {
    const auto esm = new eSettingsMenu(mSettings, this);
    esm->resize(width(), height());

    const auto applyA = [this](const eSettings& settings) {
        const bool loadNeeded = settings.fRes != mSettings.fRes;
        const bool langChanged = settings.fLanguage != mSettings.fLanguage;
        const bool audioLangChanged = settings.fAudioLanguage != mSettings.fAudioLanguage;
        setResolution(settings.fRes);
        setFullscreen(settings.fFullscreen);
        mSettings = settings;
        mSettings.write();
        if(!mSettings.fTinyTextures &&
           !mSettings.fSmallTextures &&
           !mSettings.fMediumTextures &&
           !mSettings.fLargeTextures) {
            mSettings.fSmallTextures = true;
        }
        eGameTextures::setSettings(mSettings);
        if(audioLangChanged) {
            eGameDir::setAudioLanguage(mSettings.fAudioLanguage);
            eSounds::reload();
            eMusic::clearCampaignVoices();
        }
        if(langChanged) {
            eFonts::setLanguage(mSettings.fLanguage);
            eLanguage::reload(mSettings.fLanguage);
            eMessages::reload();
        }
        if(loadNeeded) showMenuLoading();
        else showMainMenu();
    };
    const auto fullscrennA = [this](const bool f) {
        setFullscreen(f);
    };
    esm->initialize(applyA, fullscrennA);
    setWidget(esm);
}

void eMainWindow::showChooseGameMenu() {
    const auto gem = new eChooseGameEditMenu(this);
    gem->resize(width(), height());
    gem->initialize(false);
    setWidget(gem);
}

void eMainWindow::showChooseGameEditMenu() {
    const auto gem = new eChooseGameEditMenu(this);
    gem->resize(width(), height());
    gem->initialize(true);
    setWidget(gem);
}

void eMainWindow::showGame(const stdsptr<eCampaign>& c,
                           const eGameWidgetSettings& settings) {
    mCampaign = c;
    const auto e = c->currentEpisode();
    showGame(e->fBoard, settings);
}

void eMainWindow::showGame(eGameBoard* b,
                           const eGameWidgetSettings& settings) {
    if(!b) b = mBoard;

    if(b == mBoard && mGW) {
        return setWidget(mGW);
    }

    if(mGW) {
        mGW->setBoard(nullptr);
        mGW->deleteLater();
        mGW = nullptr;
    }

    mBoard = b;
    if(mBoard) {
        mBoard->updateAppealMapIfNeeded();
        mBoard->waitUntilFinished();
    }

    eMusic::playRandomMusic();
    mGW = new eGameWidget(this);
    mGW->setBoard(b);
    mGW->resize(width(), height());
    mGW->initialize();
    mGW->setSettings(settings);
    setWidget(mGW);
}

void eMainWindow::showWorld() {
    if(mWidget == mWW) return;
    if(!mCampaign) return;
    if(!mWW) {
        mWW = new eWorldWidget(this);
        mWW->resize(width(), height());
        mWW->initialize();
        mWW->setBoard(mBoard);
    } else {
        mWW->update();
    }
    setWidget(mWW);
}

void eMainWindow::execDialog(
        eWidget* const d, const bool closable,
        const eAction &closeFunc,
        eWidget* const parent) {
    if(!mWidget) return;
    const auto bg = new eEventBackground(this);
    if(closeFunc) {
        bg->initialize(parent ? parent : mWidget, d, closable, closeFunc);
    } else {
        const auto closeFunc = [d]() {
            d->deleteLater();
        };
        bg->initialize(parent ? parent : mWidget, d, closable, closeFunc);
    }
}

class eTooltip {
public:
    eTooltip(eMainWindow& w) : mWindow(w) {}

    void update() {
        const auto txt = eWidget::sTooltip();
        const bool updateTxt = mText != txt;
        if(updateTxt) {
            mText = txt;
        }

        const auto& res = mWindow.resolution();
        const int fontSize = res.verySmallFontSize();
        const bool updateFont = mFontSize != fontSize;
        if(updateFont) {
            mFontSize = fontSize;
            mFont = eFonts::defaultFont(mFontSize);
        }

        const bool updateTexture = updateTxt || updateFont;
        if(updateTexture) {
            const auto r = mWindow.renderer();
            if(mText.empty()) {
                mTexture->reset();
            } else {
                mTexture->loadText(r, mText, eFontColor::light, *mFont, 50*fontSize);
            }
        }
    }

    void paint(const int x, const int y, ePainter& p) {
        const int pp = padding();
        SDL_Rect rect{x, y, width(), height()};
        p.fillRect(rect, SDL_Color{16, 108, 144, 255});
        p.drawRect(rect, SDL_Color{0, 32, 32, 255}, 1);
        p.drawTexture(x + pp, y + pp, mTexture);
    }

    int width() const { return mTexture->width() + 2*padding(); }
    int height() const { return mTexture->height() + 2*padding(); }

    bool empty() const { return mText.empty(); }
private:
    int padding() const { return mFontSize/2; }

    eMainWindow& mWindow;
    int mFontSize = -1;
    TTF_Font* mFont = nullptr;
    std::string mText;
    stdsptr<eTexture> mTexture = std::make_shared<eTexture>();
};

int eMainWindow::exec() {
    using namespace std::chrono;
    using namespace std::chrono_literals;

    std::vector<std::string> shot;
    if(const char* const env = getenv("EZEUS_SHOT")) {
        std::string rest = env;
        size_t pos;
        while((pos = rest.find(';')) != std::string::npos) {
            shot.push_back(rest.substr(0, pos));
            rest = rest.substr(pos + 1);
        }
        shot.push_back(rest);
    }
    int shotFrames = 0;
    bool shotFocused = false;
    // EZEUS_BENCH=<frames>: with EZEUS_SHOT, keep running and report paint times.
    const int benchFrames = getenv("EZEUS_BENCH") ? std::max(0, atoi(getenv("EZEUS_BENCH"))) : 0;
    std::vector<double> benchMs;
    std::vector<std::array<double, eBenchTimers::count>> benchSections;
    bool shotLoaded = false;
    if(shot.size() < 3) shot.clear();
    // Menu screenshot mode (development aid):
    // EZEUS_MENU_SHOT="<out.png>;<screen>;<seconds>[;<mouse x>;<mouse y>[;<keys>]]"
    // screen: main, adventures, editor, settings, load or roster, opened as soon
    // as the main menu is up; the frame <seconds> later is saved. The mouse is
    // pinned at x y, and keys (comma separated SDL scancode names, e.g.
    // "Down,Down") are pressed once the screen has settled.
    std::vector<std::string> menuShot;
    if(const char* const env = getenv("EZEUS_MENU_SHOT")) {
        std::string rest = env;
        size_t pos;
        while((pos = rest.find(';')) != std::string::npos) {
            menuShot.push_back(rest.substr(0, pos));
            rest = rest.substr(pos + 1);
        }
        menuShot.push_back(rest);
        if(menuShot.size() < 3) menuShot.clear();
    }
    bool menuShotStarted = false;
    bool menuShotKeysSent = false;
    double menuShotPaintMs = 0;
    int menuShotFrames = 0;
    auto menuShotStart = high_resolution_clock::now();
    showMenuLoading();

    eMouseButton button{eMouseButton::none};
    eMouseButton buttons{eMouseButton::none};

    SDL_Event e;
    eTooltip tooltip(*this);

    bool showFPS = false;
    int fpsFrameCount = 0;
    auto fpsLastCheck = high_resolution_clock::now();
    int fpsVal = 0;

    auto getTargetFps = [&]() -> double {
        SDL_DisplayMode dm;
        if(mSdlWindow && SDL_GetWindowDisplayMode(mSdlWindow, &dm) == 0 && dm.refresh_rate > 0) {
            return std::max(60.0, static_cast<double>(dm.refresh_rate));
        }
        return 60.0;
    };

    bool resetRenderTargets = false;
    while(!mQuit) {
        const auto fpsStart = high_resolution_clock::now();
        eBenchTimers::sReset();

        while(SDL_PollEvent(&e)) {
            int x, y;
            SDL_GetMouseState(&x, &y);
            const bool shift = mShiftPressed > 0;
            const bool ctrl = mCtrlPressed > 0;
            if(e.type == SDL_QUIT) {
                mQuit = true;
            } else if(e.type == SDL_WINDOWEVENT) {
                const auto we = e.window.event;
                if(we == SDL_WINDOWEVENT_MINIMIZED) {
                    resetRenderTargets = true;
                    while(SDL_WaitEvent(&e)) {
                        if(e.window.event == SDL_WINDOWEVENT_RESTORED) {
                            break;
                        }
                    }
                } else if(we == SDL_WINDOWEVENT_EXPOSED) {
                    resetRenderTargets = true;
                } else if(we == SDL_WINDOWEVENT_SIZE_CHANGED || we == SDL_WINDOWEVENT_RESIZED) {
                    const int newW = e.window.data1;
                    const int newH = e.window.data2;
                    if(newW > 0 && newH > 0 && (newW != width() || newH != height())) {
                        mSettings.fRes = eResolution(newW, newH);
                        mSettings.write();
                        if(mWidget) {
                            mWidget->resize(newW, newH);
                        }
                        if(mGW && mWidget != mGW) {
                            mGW->resize(newW, newH);
                        }
                        if(mWW && mWidget != mWW) {
                            mWW->resize(newW, newH);
                        }
                        resetRenderTargets = true;
                    }
                }
            } else if(e.type == SDL_RENDER_TARGETS_RESET ||
                      e.type == SDL_RENDER_DEVICE_RESET) {
                resetRenderTargets = true;
            } else if(e.type == SDL_MOUSEMOTION) {
                const eMouseEvent me(x, y, shift, ctrl, buttons, button);
                if(mWidget) mWidget->mouseMove(me);
            } else if(e.type == SDL_MOUSEBUTTONDOWN) {
                switch(e.button.button) {
                case SDL_BUTTON_LEFT:
                    button = eMouseButton::left;
                    break;
                case SDL_BUTTON_RIGHT:
                    button = eMouseButton::right;
                    break;
                case SDL_BUTTON_MIDDLE:
                    button = eMouseButton::middle;
                    break;
                default: continue;
                }
                buttons = button | buttons;

                const eMouseEvent me(x, y, shift, ctrl, buttons, button);
                if(mWidget) mWidget->mousePress(me);
            } else if(e.type == SDL_MOUSEBUTTONUP) {
                switch(e.button.button) {
                case SDL_BUTTON_LEFT:
                    button = eMouseButton::left;
                    break;
                case SDL_BUTTON_RIGHT:
                    button = eMouseButton::right;
                    break;
                case SDL_BUTTON_MIDDLE:
                    button = eMouseButton::middle;
                    break;
                default: continue;
                }
                buttons = buttons & ~button;
                const eMouseEvent me(x, y, shift, ctrl, buttons, button);
                if(mWidget) mWidget->mouseRelease(me);
            } else if(e.type == SDL_MOUSEWHEEL) {
                const eMouseWheelEvent me(x, y, shift, ctrl, buttons, e.wheel.y);
                if(mWidget) mWidget->mouseWheel(me);
            } else if(e.type == SDL_KEYDOWN) {
                const auto k = e.key.keysym.scancode;
                if(k == SDL_Scancode::SDL_SCANCODE_LSHIFT ||
                   k == SDL_Scancode::SDL_SCANCODE_RSHIFT) {
                    mShiftPressed++;
                } else if(k == SDL_Scancode::SDL_SCANCODE_LCTRL ||
                          k == SDL_Scancode::SDL_SCANCODE_RCTRL) {
                    mCtrlPressed++;
                }
                const auto mod = SDL_GetModState();
                const bool isCtrl = (ctrl || (mod & (KMOD_CTRL | KMOD_GUI)));
                if(isCtrl && k == SDL_SCANCODE_F) {
                    showFPS = !showFPS;
                }
                const eKeyPressEvent ke(x, y, shift, ctrl, buttons, k);
                if(mWidget) mWidget->keyPress(ke);
            } else if(e.type == SDL_KEYUP) {
                const auto k = e.key.keysym.scancode;
                if(k == SDL_Scancode::SDL_SCANCODE_LSHIFT ||
                   k == SDL_Scancode::SDL_SCANCODE_RSHIFT) {
                    mShiftPressed--;
                } else if(k == SDL_Scancode::SDL_SCANCODE_LCTRL ||
                          k == SDL_Scancode::SDL_SCANCODE_RCTRL) {
                    mCtrlPressed--;
                }
            }
        }

        if(resetRenderTargets) {
            resetRenderTargets = false;
            if(mWidget) mWidget->renderTargetsReset();
        }

        SDL_SetRenderDrawColor(mSdlRenderer, 0x0, 0x0, 0x0, 0xFF);
        SDL_RenderClear(mSdlRenderer);

        ePainter p(mSdlRenderer);

        eMusic::incTime();
        const auto paintStart = high_resolution_clock::now();
        timespec cpuStart;
        clock_gettime(CLOCK_THREAD_CPUTIME_ID, &cpuStart);
        if(mWidget) {
            {
                const eBenchScope benchWidgets(eBenchTimers::widgets);
                mWidget->paint(p);
            }
            tooltip.update();
            if(!tooltip.empty()) {
                const auto& res = resolution();
                const int pp = 25*res.multiplier();
                const int wtt = tooltip.width();
                const int htt = tooltip.height();
                int mx, my;
                SDL_GetMouseState(&mx, &my);
                int xtt;
                int ytt;
                if(mx > width()/2) {
                    xtt = mx - wtt;
                } else {
                    xtt = mx;
                }
                if(my > height()/2) {
                    ytt = my - htt - pp;
                } else {
                    ytt = my + pp;
                }
                tooltip.paint(xtt, ytt, p);
            }
        }

        if(showFPS) {
            const std::string fpsStr = std::to_string(fpsVal) + " FPS";
            auto font = eFonts::defaultFont(resolution());
            p.setFont(font);
            int tw = 60, th = 20;
            if(font) TTF_SizeUTF8(font, fpsStr.c_str(), &tw, &th);
            const SDL_Rect badgeRect{8, 8, tw + 16, th + 8};
            p.fillRect(badgeRect, SDL_Color{16, 26, 42, 220});
            p.drawGoldFrame(badgeRect, 1);
            p.drawText(badgeRect.x + 8, badgeRect.y + 4, fpsStr, eFontColor::yellow);
        }

        if(!shot.empty() && !shotLoaded && mWidget &&
           !dynamic_cast<eMenuLoadingWidget*>(mWidget)) {
            shotLoaded = true;
            if(!loadGame(shot[0])) {
                printf("EZEUS_SHOT: could not load '%s'\n", shot[0].c_str());
                mQuit = true;
            }
        }
        if(!menuShot.empty() && mWidget) {
            if(!menuShotStarted && dynamic_cast<eMainMenu*>(mWidget)) {
                menuShotStarted = true;
                menuShotStart = high_resolution_clock::now();
                if(menuShot.size() >= 5) {
                    eMenuScene::instance().setPointerOverride(std::stoi(menuShot[3]),
                                                              std::stoi(menuShot[4]));
                }
                const auto screen = menuShot[1];
                const auto mm = mWidget;
                addSlot([this, screen, mm]() {
                    if(screen == "adventures") showChooseGameMenu();
                    else if(screen == "editor") showChooseGameEditMenu();
                    else if(screen == "settings") showSettingsMenu();
                    else if(screen == "roster") showRosterOfLeaders();
                    else if(screen == "load") showLoadDialog(mm);
                });
            }
            if(menuShotStarted) {
                const duration<double> el = high_resolution_clock::now() - menuShotStart;
                if(el.count() > 1.0) {
                    const duration<double, std::milli> ms = high_resolution_clock::now() - paintStart;
                    menuShotPaintMs += ms.count();
                    menuShotFrames++;
                }
                if(menuShot.size() >= 5) {
                    const eMouseEvent me(std::stoi(menuShot[3]), std::stoi(menuShot[4]),
                                         false, false, eMouseButton::none);
                    mWidget->mouseMove(me);
                }
                if(!menuShotKeysSent && menuShot.size() >= 6 && el.count() > 1.2) {
                    menuShotKeysSent = true;
                    std::string keys = menuShot[5] + ",";
                    size_t pos;
                    while((pos = keys.find(',')) != std::string::npos) {
                        const auto name = keys.substr(0, pos);
                        keys = keys.substr(pos + 1);
                        const auto sc = SDL_GetScancodeFromName(name.c_str());
                        if(sc == SDL_SCANCODE_UNKNOWN) continue;
                        const eKeyPressEvent ke(0, 0, false, false, eMouseButton::none, sc);
                        mWidget->keyPress(ke);
                    }
                }
                if(el.count() >= std::stod(menuShot[2])) {
                    const auto surf = SDL_CreateRGBSurfaceWithFormat(0, width(), height(), 32, SDL_PIXELFORMAT_RGBA32);
                    SDL_RenderReadPixels(mSdlRenderer, nullptr, SDL_PIXELFORMAT_RGBA32, surf->pixels, surf->pitch);
                    IMG_SavePNG(surf, menuShot[0].c_str());
                    SDL_FreeSurface(surf);
                    printf("EZEUS_MENU_SHOT: saved %s (%d frames, paint avg %.2f ms)\n", menuShot[0].c_str(),
                           menuShotFrames, menuShotFrames ? menuShotPaintMs/menuShotFrames : 0.0);
                    mQuit = true;
                }
            }
        }
        eTerrainHD::sFinishFrame(mSdlRenderer);

        if(!shot.empty() && mGW && (mWidget == mGW || (mWW && mWidget == mWW))) {
            shotFrames++;
            // EZEUS_SHOT_FOCUS=<eCharacterType number>[,<n>]: centre on the n-th such
            // walker (for reviewing remastered characters). Retried for a few frames:
            // some animals are only spawned by their building on the first ticks.
            const char* const focus = getenv("EZEUS_SHOT_FOCUS");
            if(focus && !shotFocused && shotFrames >= 3 && shotFrames < 8) {
                int type = -1;
                int nth = 0;
                sscanf(focus, "%d,%d", &type, &nth);
                int seen = 0;
                for(const auto c : mBoard->characters()) {
                    if(static_cast<int>(c->type()) != type) continue;
                    if(seen++ < nth) continue;
                    mGW->viewTile(c->tile());
                    printf("EZEUS_SHOT: focused on character type %d #%d (frame %d)\n", type, nth, shotFrames);
                    shotFocused = true;
                    break;
                }
                if(!shotFocused && shotFrames == 7) {
                    std::map<int, int> n;
                    for(const auto c : mBoard->characters()) n[static_cast<int>(c->type())]++;
                    printf("EZEUS_SHOT: no character type %d #%d; present:", type, nth);
                    for(const auto& [t, k] : n) printf(" %d:%d", t, k);
                    printf("\n");
                }
            }
            // EZEUS_SHOT_CENSUS: print "type:count" of every building on the map (art priorities).
            if(getenv("EZEUS_SHOT_CENSUS") && shotFrames == 3) {
                std::set<eBuilding*> seen;
                std::map<int, int> n;
                mBoard->iterateOverAllTiles([&](eTile* const t) {
                    const auto b = t->underBuilding();
                    if(b && seen.insert(b).second) n[static_cast<int>(b->type())]++;
                });
                printf("EZEUS_CENSUS:");
                for(const auto& [ty, k] : n) printf(" %d:%d", ty, k);
                printf("\n");
            }
            // EZEUS_TEST_TIME: automated test for time progression, pause, and speed
            if(getenv("EZEUS_TEST_TIME") && shotFrames >= 3 && shotFrames <= 25) {
                static int sPrevTime = -1;
                const int curTime = mBoard->totalTime();
                printf("[TEST_TIME] frame=%d curTime=%d diff=%d isPaused=%d isRunning=%d speedId=%d\n",
                       shotFrames, curTime, sPrevTime >= 0 ? curTime - sPrevTime : 0,
                       mGW->isPaused(), mGW->isSimulationRunning(), mGW->speedId());
                sPrevTime = curTime;
                if(shotFrames == 10) {
                    printf("[TEST_TIME] Toggling pause (pressing P)...\n");
                    mGW->switchPause();
                } else if(shotFrames == 15) {
                    printf("[TEST_TIME] Resuming from pause...\n");
                    mGW->switchPause();
                } else if(shotFrames == 18) {
                    printf("[TEST_TIME] Increasing speed to next tier...\n");
                    mGW->setSpeedId(mGW->speedId() + 1);
                }
            }
            // EZEUS_TEST_DRAG: automated test for Area Drag (Housing & Walls) + Box Demolish
            if(getenv("EZEUS_TEST_DRAG") && shotFrames == 3) {
                printf("[TEST_DRAG] Starting automated verification of Area Drag-to-Place and Box Demolish...\n");
                const auto ppid = mBoard->personPlayer();
                const int startMoney = mBoard->drachmas(ppid);
                printf("[TEST_DRAG] Initial drachmas: %d\n", startMoney);

                // Find a clear area where 4 2x2 houses and surrounding walls can be built
                const auto cid = mBoard->currentCityId();
                const auto pid = mBoard->personPlayer();
                int testX = -1, testY = -1;
                for(int x = 20; x < 90; x++) {
                    for(int y = 20; y < 90; y++) {
                        if(mBoard->canBuild(x, y, 2, 2, false, cid, pid) &&
                           mBoard->canBuild(x + 2, y, 2, 2, false, cid, pid) &&
                           mBoard->canBuild(x, y + 2, 2, 2, false, cid, pid) &&
                           mBoard->canBuild(x + 2, y + 2, 2, 2, false, cid, pid)) {
                            bool clearForWalls = true;
                            for(int wx = x - 1; wx <= x + 4; wx++) {
                                for(int wy = y - 1; wy <= y + 4; wy++) {
                                    const auto t = mBoard->tile(wx, wy);
                                    if(!t || t->cityId() != cid || t->underBuilding()) {
                                        clearForWalls = false;
                                        break;
                                    }
                                }
                                if(!clearForWalls) break;
                            }
                            if(clearForWalls) {
                                testX = x;
                                testY = y;
                                break;
                            }
                        }
                    }
                    if(testX != -1) break;
                }
                assert(testX != -1);
                printf("[TEST_DRAG] Selected test anchor: (%d, %d)\n", testX, testY);

                // 1. Test Common Housing Drag
                printf("[TEST_DRAG 1] Testing Common Housing Drag (2x2 lots)...\n");
                mGW->gameMenu()->setMode(eBuildingMode::commonHousing);
                mGW->setPressedTileForTest(testX, testY);
                mGW->setHoverTileForTest(testX + 2, testY + 2);
                int beforeMoney = mBoard->drachmas(ppid);
                bool ok = mGW->buildMouseReleaseRecorded();
                printf("[TEST_DRAG 1] Build result: %d, spent: %d\n", ok, beforeMoney - mBoard->drachmas(ppid));
                assert(ok);

                std::set<eBuilding*> houses;
                for(int x = testX; x <= testX + 3; x++) {
                    for(int y = testY - 1; y <= testY + 2; y++) {
                        const auto t = mBoard->tile(x, y);
                        if(t && t->underBuilding()) houses.insert(t->underBuilding());
                    }
                }
                printf("[TEST_DRAG 1] Unique house buildings placed: %zu\n", houses.size());
                assert(houses.size() >= 2);

                // Test Undo
                printf("[TEST_DRAG 1] Testing Undo of batch-placed houses...\n");
                assert(mGW->undoAvailable());
                mGW->undoLastBuild();
                int remainingHouses = 0;
                for(int x = testX; x <= testX + 3; x++) {
                    for(int y = testY - 1; y <= testY + 2; y++) {
                        const auto t = mBoard->tile(x, y);
                        if(t && t->underBuilding()) remainingHouses++;
                    }
                }
                printf("[TEST_DRAG 1] Remaining houses after undo: %d\n", remainingHouses);
                assert(remainingHouses == 0);
                assert(mBoard->drachmas(ppid) == beforeMoney);

                // 2. Test Wall Drag (Perimeter)
                printf("[TEST_DRAG 2] Testing Wall Drag (Perimeter enclosure)...\n");
                mGW->gameMenu()->setMode(eBuildingMode::wall);
                mGW->setPressedTileForTest(testX - 1, testY - 1);
                mGW->setHoverTileForTest(testX + 4, testY + 4);
                beforeMoney = mBoard->drachmas(ppid);
                ok = mGW->buildMouseReleaseRecorded();
                printf("[TEST_DRAG 2] Build wall result: %d, spent: %d\n", ok, beforeMoney - mBoard->drachmas(ppid));
                assert(ok);

                int wallCount = 0;
                for(int x = testX - 1; x <= testX + 4; x++) {
                    for(int y = testY - 1; y <= testY + 4; y++) {
                        const auto t = mBoard->tile(x, y);
                        if(t && t->underBuilding() && t->underBuilding()->type() == eBuildingType::wall) wallCount++;
                    }
                }
                printf("[TEST_DRAG 2] Perimeter walls placed: %d\n", wallCount);
                assert(wallCount >= 10);
                assert(beforeMoney - mBoard->drachmas(ppid) > 0);
                const auto centerT = mBoard->tile(testX + 1, testY + 1);
                if(centerT && !centerT->underBuilding()) {
                    printf("[TEST_DRAG 2] Interior tile (%d, %d) correctly kept open for city!\n", testX+1, testY+1);
                }

                // 3. Test Box Demolish
                printf("[TEST_DRAG 3] Testing Box Demolish over walled area...\n");
                mGW->gameMenu()->setMode(eBuildingMode::erase);
                mGW->setPressedTileForTest(testX - 2, testY - 2);
                mGW->setHoverTileForTest(testX + 5, testY + 5);
                mGW->buildMouseRelease();

                int remainingWalls = 0;
                for(int x = testX - 1; x <= testX + 4; x++) {
                    for(int y = testY - 1; y <= testY + 4; y++) {
                        const auto t = mBoard->tile(x, y);
                        if(t && t->underBuilding() && t->underBuilding()->type() == eBuildingType::wall) remainingWalls++;
                    }
                }
                printf("[TEST_DRAG 3] Remaining walls after demolish: %d\n", remainingWalls);
                assert(remainingWalls == 0);

                // Set up visual preview for screenshot: place Wall Drag preview
                mGW->gameMenu()->setMode(eBuildingMode::wall);
                mGW->setPressedTileForTest(testX - 1, testY - 1);
                mGW->setHoverTileForTest(testX + 4, testY + 4);
                mGW->viewTile(mBoard->tile(testX + 2, testY + 2));

                printf("[TEST_DRAG SUCCESS] All automated checks for Housing Drag, Wall Drag, Undo, and Box Demolish passed!\n");
            }
            // EZEUS_SHOT_DIR=<0-3>: view direction (eWorldDirection N, W, S, E) before focusing.
            if(const char* const sd = getenv("EZEUS_SHOT_DIR"); sd && shotFrames == 2) {
                mGW->setWorldDirection(static_cast<eWorldDirection>(atoi(sd) % 4));
            }
            // EZEUS_SHOT_PROBE=<x>,<y>,<r>: print the building type of every tile around (x, y).
            if(const char* const pr = getenv("EZEUS_SHOT_PROBE"); pr && shotFrames == 3) {
                int px = 0, py = 0, r = 3;
                sscanf(pr, "%d,%d,%d", &px, &py, &r);
                for(int y = py - r; y <= py + r; y++) {
                    for(int x = px - r; x <= px + r; x++) {
                        const auto t = mBoard->tile(x, y);
                        printf("%4d", t ? static_cast<int>(t->underBuildingType()) : -9);
                    }
                    printf("   <- y=%d\n", y);
                }
            }
            // EZEUS_SHOT_BUILDING=<eBuildingType number>[,<n>]: centre on the n-th tile under
            // that building type (roads, avenues ...).
            if(const char* const bf = getenv("EZEUS_SHOT_BUILDING"); bf && !shotFocused && shotFrames == 3) {
                int type = -1, nth = 0;
                sscanf(bf, "%d,%d", &type, &nth);
                int seen = 0;
                mBoard->iterateOverAllTiles([&](eTile* const t) {
                    if(shotFocused || static_cast<int>(t->underBuildingType()) != type) return;
                    if(seen++ < nth) return;
                    mGW->viewTile(t);
                    shotFocused = true;
                    printf("EZEUS_SHOT: focused on building type %d tile %d,%d\n", type, t->x(), t->y());
                });
            }
            // EZEUS_SHOT_TERRAIN=<eTerrain bits>[,<n>][,e]: centre on the n-th tile of that
            // terrain (",e" = elevation/cliff tiles only), for reviewing terrain remasters.
            if(const char* const tf = getenv("EZEUS_SHOT_TERRAIN"); tf && !shotFocused && shotFrames == 3) {
                int bits = 0, nth = 0;
                sscanf(tf, "%d,%d", &bits, &nth);
                const bool elev = std::string(tf).find(",e") != std::string::npos;
                int seen = 0;
                mBoard->iterateOverAllTiles([&](eTile* const t) {
                    if(shotFocused) return;
                    if(!(static_cast<int>(t->terrain()) & bits)) return;
                    if(elev && !t->isElevationTile()) return;
                    if(seen++ < nth) return;
                    mGW->viewTile(t);
                    shotFocused = true;
                    printf("EZEUS_SHOT: focused on terrain %d tile %d,%d\n", bits, t->x(), t->y());
                });
            }
            // EZEUS_SHOT_SAVE=<path>: take a history sample and a test trade
            // in each of the player's cities, save there, and quit (a
            // save/load round trip of the city history and trade ledger).
            if(const char* const sp = getenv("EZEUS_SHOT_SAVE"); sp && shotFrames == 3) {
                for(const auto cid : mBoard->personPlayerCitiesOnBoard()) {
                    if(const auto c = mBoard->boardCityWithId(cid)) {
                        c->recordHistory();
                        c->tradeLedger().addExport(1, eResourceType::wine, 3, 90);
                        c->tradeLedger().addImport(1, eResourceType::fleece, 2, 40);
                    }
                }
                const bool ok = saveGameUnchecked(sp);
                printf("EZEUS_SHOT: saved game %s: %s\n", sp, ok ? "ok" : "failed");
            }
            if(shotFrames == 2) {
                if(shot.size() >= 5) {
                    mGW->viewFraction(std::stod(shot[3]), std::stod(shot[4]));
                }
                const int zoom = std::stoi(shot[2]);
                const int steps = zoom - mGW->currentZoomIndex();
                if(steps != 0) {
                    mGW->zoomSteps(steps, width()/2, height()/2);
                }
            } else if(shotFrames > 2 && shotFrames < 8 + benchFrames) {
                const duration<double, std::milli> ms = high_resolution_clock::now() - paintStart;
                timespec cpuEnd;
                clock_gettime(CLOCK_THREAD_CPUTIME_ID, &cpuEnd);
                eBenchTimers::sMs[eBenchTimers::cpu] = (cpuEnd.tv_sec - cpuStart.tv_sec)*1e3 +
                                                       (cpuEnd.tv_nsec - cpuStart.tv_nsec)*1e-6;
                if(benchFrames) {
                    benchMs.push_back(ms.count());
                    std::array<double, eBenchTimers::count> sec;
                    std::copy(std::begin(eBenchTimers::sMs), std::end(eBenchTimers::sMs), sec.begin());
                    benchSections.push_back(sec);
                }
                else printf("EZEUS_SHOT: frame paint %.1f ms\n", ms.count());
            } else if(shotFrames == 8 + benchFrames) {
                if(benchFrames && !benchMs.empty()) {
                    auto sorted = benchMs;
                    std::sort(sorted.begin(), sorted.end());
                    double sum = 0;
                    for(const double v : sorted) sum += v;
                    const auto pct = [&](const double q) {
                        return sorted[std::min(sorted.size() - 1, size_t(q*sorted.size()))];
                    };
                    printf("EZEUS_BENCH: %zu frames paint avg %.2f p50 %.2f p95 %.2f p99 %.2f max %.2f ms\n",
                           sorted.size(), sum/sorted.size(), pct(0.5), pct(0.95), pct(0.99), sorted.back());
                    // Section breakdown: typical frames vs the slowest 2%.
                    // present is this frame's flush + RenderPresent, recorded next frame.
                    const double slow = pct(0.98);
                    const char* names[eBenchTimers::count] =
                        {"sim", "terrainUpdate", "tiles", "gamePaint", "text", "texLoad", "widgets", "cpu", "present"};
                    for(const bool slowSet : {false, true}) {
                        double acc[eBenchTimers::count] = {};
                        int n = 0;
                        int simFrames = 0;
                        for(size_t i = 0; i < benchMs.size(); i++) {
                            if((benchMs[i] >= slow) != slowSet) continue;
                            n++;
                            if(benchSections[i][eBenchTimers::sim] > 0.05) simFrames++;
                            for(int k = 0; k < eBenchTimers::count; k++) acc[k] += benchSections[i][k];
                        }
                        if(!n) continue;
                        printf("EZEUS_BENCH: %s frames (%d, %d%% with a sim tick):",
                               slowSet ? "slowest 2%" : "other", n, 100*simFrames/n);
                        for(int k = 0; k < eBenchTimers::count; k++) printf(" %s %.2f", names[k], acc[k]/n);
                        printf(" ms\n");
                    }
                }
                const auto surf = SDL_CreateRGBSurfaceWithFormat(0, width(), height(), 32, SDL_PIXELFORMAT_RGBA32);
                SDL_RenderReadPixels(mSdlRenderer, nullptr, SDL_PIXELFORMAT_RGBA32, surf->pixels, surf->pitch);
                IMG_SavePNG(surf, shot[1].c_str());
                SDL_FreeSurface(surf);
                printf("EZEUS_SHOT: saved %s\n", shot[1].c_str());
                mQuit = true;
            }
        }

        {
            const eBenchScope benchPresent(eBenchTimers::present);
            eGeometryBatch::sFlush();
            SDL_RenderPresent(mSdlRenderer);
        }
        if(!benchSections.empty() && benchSections.size() == benchMs.size()) {
            benchSections.back()[eBenchTimers::present] = eBenchTimers::sMs[eBenchTimers::present];
        }

        for(const auto& s : mSlots) {
            s();
        }
        mSlots.clear();

        const double targetFps = getTargetFps();
        const auto fpsEnd = high_resolution_clock::now();
        const duration<double, std::milli> fpsElapsed = fpsEnd - fpsStart;
        const duration<double, std::milli> fpsDuration(1000.0 / targetFps);
        const duration<double, std::milli> fpsSleep(fpsDuration - fpsElapsed);
        if(fpsSleep.count() > 0.5) {
            std::this_thread::sleep_for(fpsSleep);
        }

        fpsFrameCount++;
        const auto nowFps = high_resolution_clock::now();
        const duration<double> diff = nowFps - fpsLastCheck;
        if(diff.count() >= 0.5) {
            fpsVal = static_cast<int>(std::round(fpsFrameCount / diff.count()));
            fpsFrameCount = 0;
            fpsLastCheck = nowFps;
        }
    }

    return 0;
}
