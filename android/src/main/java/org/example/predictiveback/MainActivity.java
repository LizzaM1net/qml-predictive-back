package org.example.predictiveback;

import android.graphics.Insets;
import android.os.Build;
import android.os.Bundle;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
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

        // Edge-to-edge: extend the Qt surface behind the status bar and
        // navigation bar. This aligns BackEvent touch coordinates (which are
        // relative to the full display) with QML's coordinate system.
        // Content is padded via safe-area insets exposed through getWindowInsets().
        getWindow().setDecorFitsSystemWindows(false);

        // Use light (white) icons on the system bars — we have a dark background.
        WindowInsetsController ctrl = getWindow().getInsetsController();
        if (ctrl != null) {
            ctrl.setSystemBarsAppearance(
                    0,
                    WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS
                            | WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS);
        }

        registerBackCallback();
    }

    /** Called from C++ via QJniObject when the QML switch changes. */
    public static void setExitOnBack(boolean exit) {
        if (instance == null) return;
        instance.exitOnBack = exit;
        instance.runOnUiThread(instance::registerBackCallback);
    }

    /**
     * Returns system-bar + display-cutout insets as [top, bottom, left, right] in dp.
     * Called from C++ (BackGestureHandler::refreshSafeArea) after the window is laid out.
     */
    public static int[] getWindowInsets() {
        if (instance == null) return new int[]{0, 0, 0, 0};
        android.view.View root = instance.getWindow().getDecorView();
        WindowInsets wi = root.getRootWindowInsets();
        if (wi == null) return new int[]{0, 0, 0, 0};
        float density = instance.getResources().getDisplayMetrics().density;
        Insets bars = wi.getInsets(
                WindowInsets.Type.systemBars() | WindowInsets.Type.displayCutout());
        return new int[]{
                Math.round(bars.top    / density),
                Math.round(bars.bottom / density),
                Math.round(bars.left   / density),
                Math.round(bars.right  / density),
        };
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
                    // BackEvent gives physical pixels; QML uses dp → divide by density
                    float d = getResources().getDisplayMetrics().density;
                    onBackStartedNative(e.getSwipeEdge(), e.getTouchX() / d, e.getTouchY() / d);
                }

                @Override
                public void onBackProgressed(BackEvent e) {
                    float d = getResources().getDisplayMetrics().density;
                    onBackProgressedNative(
                            e.getProgress(), e.getTouchX() / d, e.getTouchY() / d, e.getSwipeEdge());
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
