#pragma once
#include <QObject>

class BackGestureHandler : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool exitOnBack READ exitOnBack WRITE setExitOnBack NOTIFY exitOnBackChanged)

public:
    explicit BackGestureHandler(QObject *parent = nullptr);
    static BackGestureHandler *instance();

    bool exitOnBack() const;
    void setExitOnBack(bool exit);

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

private:
    static BackGestureHandler *s_instance;
    bool m_exitOnBack = true;
};
