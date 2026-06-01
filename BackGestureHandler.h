#pragma once
#include <QObject>

class BackGestureHandler : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool exitOnBack READ exitOnBack WRITE setExitOnBack NOTIFY exitOnBackChanged)
    Q_PROPERTY(int safeTop    READ safeTop    NOTIFY safeAreaChanged)
    Q_PROPERTY(int safeBottom READ safeBottom NOTIFY safeAreaChanged)
    Q_PROPERTY(int safeLeft   READ safeLeft   NOTIFY safeAreaChanged)
    Q_PROPERTY(int safeRight  READ safeRight  NOTIFY safeAreaChanged)

public:
    explicit BackGestureHandler(QObject *parent = nullptr);
    static BackGestureHandler *instance();

    bool exitOnBack() const;
    void setExitOnBack(bool exit);

    int safeTop()    const { return m_safeTop;    }
    int safeBottom() const { return m_safeBottom; }
    int safeLeft()   const { return m_safeLeft;   }
    int safeRight()  const { return m_safeRight;  }

    // QML calls this once the window is laid out (and on rotation)
    Q_INVOKABLE void refreshSafeArea();

    void handleBackStarted(int edge, float startX, float startY);
    void handleBackProgressed(float progress, float x, float y, int edge);
    void handleBackCommitted();
    void handleBackCancelled();

signals:
    void backStarted(int edge, qreal startX, qreal startY);
    void backProgressed(qreal progress, qreal x, qreal y, int edge);
    void backCommitted();
    void backCancelled();
    void exitOnBackChanged();
    void safeAreaChanged();

private:
    static BackGestureHandler *s_instance;
    bool m_exitOnBack = true;
    int  m_safeTop    = 0;
    int  m_safeBottom = 0;
    int  m_safeLeft   = 0;
    int  m_safeRight  = 0;
};
