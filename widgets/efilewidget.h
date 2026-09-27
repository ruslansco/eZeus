#ifndef EFILEWIDGET_H
#define EFILEWIDGET_H

#include "eframedwidget.h"
#include <functional>
#include <string>

class eLabel;
class eAcceptButton;
class eCancelButton;
class eLineEdit;
class eFramedButton;
class eScrollWidgetComplete;
class eSaveRow;

class eFileWidget : public eFramedWidget {
public:
    using eFramedWidget::eFramedWidget;
    virtual ~eFileWidget();

    using eFileFunc = std::function<bool(const std::string&)>;
    void intialize(const std::string& title,
                   const std::string& folder,
                   const eFileFunc& func,
                   const eAction& closeAction);

    void setFileName(const std::string& path);
    std::string filePath() const;

    void refreshFileList();
    void confirmDelete(const std::string& name);

    // Load dialogs: a double-click on a save loads it (never for saving,
    // where it would overwrite).
    void setAcceptOnDoubleClick(const bool a) { mAcceptOnDoubleClick = a; }

    // keyboard, from the name field
    void moveSelection(const int d);
    void accept();
    void cancel();

private:
    eLabel* mTitleLabel = nullptr;
    eAcceptButton* mOk = nullptr;
    eCancelButton* mCancel = nullptr;
    eFramedButton* mDelete = nullptr;
    eLineEdit* mLineEdit = nullptr;
    eScrollWidgetComplete* mScrollCont = nullptr;
    eWidget* mFilesWidget = nullptr;

    void select(const int id);
    void rowPressed(const int id);

    std::string mFolder;
    eFileFunc mFunc;
    eAction mCloseAction;
    bool mAcceptOnDoubleClick = false;
    std::vector<eSaveRow*> mRows;
    std::vector<std::string> mNames;
    int mSelected = -1;
    int mLastPressId = -1;
    Uint64 mLastPressTime = 0;
};

#endif // EFILEWIDGET_H
