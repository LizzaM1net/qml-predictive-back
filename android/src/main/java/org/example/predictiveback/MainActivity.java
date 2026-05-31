package org.example.predictiveback;

import android.os.Build;
import android.os.Bundle;
import android.window.BackEvent;
import android.window.OnBackAnimationCallback;
import android.window.OnBackInvokedCallback;
import android.window.OnBackInvokedDispatcher;

import org.qtproject.qt.android.bindings.QtActivity;

public class MainActivity extends QtActivity {

    private static MainActivity instance;
    private boolean exitOnBack = true;
    private OnBackInvokedCallback currentCallback = null;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        instance = this;
        registerBackCallback();
    }

    /** Called from C++ via QJniObject when the QML switch changes. */
    public static void setExitOnBack(boolean exit) {
        if (instance == null) return;
        instance.exitOnBack = exit;
        instance.runOnUiThread(instance::registerBackCallback);
    }

    private void registerBackCallback() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return;

        OnBackInvokedDispatcher dispatcher = getOnBackInvokedDispatcher();

        // Always unregister whatever was active before
        if (currentCallback != null) {
            dispatcher.unregisterOnBackInvokedCallback(currentCallback);
            currentCallback = null;
        }

        if (exitOnBack) {
            // Register NO callback — Android owns the gesture entirely.
            // On API 34+ this produces the system predictive-back animation:
            // the app window scales down and slides toward the swipe edge
            // while the launcher or previous task appears behind it.
            return;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Android 14+ — full per-frame progress + touch position
            OnBackAnimationCallback anim = new OnBackAnimationCallback() {
                @Override
                public void onBackStarted(BackEvent e) {
                    onBackStartedNative(e.getSwipeEdge(), e.getTouchX(), e.getTouchY());
                }

                @Override
                public void onBackProgressed(BackEvent e) {
                    onBackProgressedNative(
                            e.getProgress(), e.getTouchX(), e.getTouchY(), e.getSwipeEdge());
                }

                @Override
                public void onBackInvoked() {
                    onBackCommittedNative();
                }

                @Override
                public void onBackCancelled() {
                    onBackCancelledNative();
                }
            };
            currentCallback = anim;
            dispatcher.registerOnBackInvokedCallback(
                    OnBackInvokedDispatcher.PRIORITY_DEFAULT, anim);
        } else {
            // Android 13 — no per-frame events; gesture start position unknown
            currentCallback = () -> onBackCommittedNative();
            dispatcher.registerOnBackInvokedCallback(
                    OnBackInvokedDispatcher.PRIORITY_DEFAULT, currentCallback);
        }
    }

    // Implemented in C++ (BackGestureHandler.cpp) via RegisterNatives
    private static native void onBackStartedNative(int swipeEdge, float startX, float startY);
    private static native void onBackProgressedNative(float progress, float x, float y, int swipeEdge);
    private static native void onBackCommittedNative();
    private static native void onBackCancelledNative();
}
