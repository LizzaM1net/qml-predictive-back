#include "BackGestureHandler.h"
#include <QCoreApplication>

#ifdef Q_OS_ANDROID
#include <QJniEnvironment>
#include <QJniObject>

// ---------------------------------------------------------------------------
// JNI callbacks — called on the Android UI thread, so we queue to Qt thread
// ---------------------------------------------------------------------------

static void jniOnBackStarted(JNIEnv *, jclass, jint edge, jfloat x, jfloat y)
{
    QMetaObject::invokeMethod(BackGestureHandler::instance(), [edge, x, y]() {
        BackGestureHandler::instance()->handleBackStarted(
            static_cast<int>(edge),
            static_cast<float>(x),
            static_cast<float>(y));
    }, Qt::QueuedConnection);
}

static void jniOnBackProgressed(JNIEnv *, jclass,
                                jfloat progress, jfloat x, jfloat y, jint edge)
{
    QMetaObject::invokeMethod(BackGestureHandler::instance(),
                              [progress, x, y, edge]() {
        BackGestureHandler::instance()->handleBackProgressed(
            progress, x, y, static_cast<int>(edge));
    }, Qt::QueuedConnection);
}

static void jniOnBackCommitted(JNIEnv *, jclass)
{
    QMetaObject::invokeMethod(BackGestureHandler::instance(), []() {
        BackGestureHandler::instance()->handleBackCommitted();
    }, Qt::QueuedConnection);
}

static void jniOnBackCancelled(JNIEnv *, jclass)
{
    QMetaObject::invokeMethod(BackGestureHandler::instance(), []() {
        BackGestureHandler::instance()->handleBackCancelled();
    }, Qt::QueuedConnection);
}

static const JNINativeMethod kMethods[] = {
    {"onBackStartedNative",    "(IFF)V",  reinterpret_cast<void *>(jniOnBackStarted)},
    {"onBackProgressedNative", "(FFFI)V", reinterpret_cast<void *>(jniOnBackProgressed)},
    {"onBackCommittedNative",  "()V",     reinterpret_cast<void *>(jniOnBackCommitted)},
    {"onBackCancelledNative",  "()V",     reinterpret_cast<void *>(jniOnBackCancelled)},
};
#endif // Q_OS_ANDROID

// ---------------------------------------------------------------------------

BackGestureHandler *BackGestureHandler::s_instance = nullptr;

BackGestureHandler::BackGestureHandler(QObject *parent)
    : QObject(parent)
{
    s_instance = this;

#ifdef Q_OS_ANDROID
    QJniEnvironment env;
    env.registerNativeMethods(
        "org/example/predictiveback/MainActivity",
        kMethods,
        static_cast<int>(std::size(kMethods)));
#endif
}

BackGestureHandler *BackGestureHandler::instance()
{
    return s_instance;
}

bool BackGestureHandler::exitOnBack() const
{
    return m_exitOnBack;
}

void BackGestureHandler::setExitOnBack(bool exit)
{
    if (m_exitOnBack == exit)
        return;
    m_exitOnBack = exit;

#ifdef Q_OS_ANDROID
    QJniObject::callStaticMethod<void>(
        "org/example/predictiveback/MainActivity",
        "setExitOnBack",
        "(Z)V",
        static_cast<jboolean>(exit));
#endif

    emit exitOnBackChanged();
}

void BackGestureHandler::handleBackStarted(int edge, float x, float y)
{
    emit backStarted(edge, static_cast<qreal>(x), static_cast<qreal>(y));
}

void BackGestureHandler::handleBackProgressed(float progress, float x, float y, int edge)
{
    emit backProgressed(static_cast<qreal>(progress),
                        static_cast<qreal>(x),
                        static_cast<qreal>(y),
                        edge);
}

void BackGestureHandler::handleBackCommitted()
{
    if (m_exitOnBack) {
        QCoreApplication::quit();
    } else {
        emit backCommitted();
    }
}

void BackGestureHandler::handleBackCancelled()
{
    emit backCancelled();
}
