package com.vipsvip.nosimhook;

import de.robv.android.xposed.IXposedHookLoadPackage;
import de.robv.android.xposed.XC_MethodHook;
import de.robv.android.xposed.XC_MethodReplacement;
import de.robv.android.xposed.XposedBridge;
import de.robv.android.xposed.XposedHelpers;
import de.robv.android.xposed.callbacks.XC_LoadPackage.LoadPackageParam;

public class MainHook implements IXposedHookLoadPackage {
    private static final String ACT = "com.miui.permcenter.install.AdbInstallVerifyActivity";
    private static final String TASK = "com.miui.permcenter.install.AdbInstallVerifyActivity$a";

    @Override
    public void handleLoadPackage(final LoadPackageParam lpp) throws Throwable {
        if (!"com.miui.securitycenter".equals(lpp.packageName)) return;
        final ClassLoader cl = lpp.classLoader;

        // H1: doInBackground -> null == success, skips srv.sec.miui.com verification
        final Class<?> taskCls = XposedHelpers.findClass(TASK, cl);
        XposedHelpers.findAndHookMethod(taskCls, "a", Void[].class, new XC_MethodHook() {
            @Override
            protected void beforeHookedMethod(MethodHookParam param) {
                param.setResult(null);
            }
        });

        Class<?> actCls = XposedHelpers.findClass(ACT, cl);

        // H2: l0() -> only read is_input extra, skip xiaomi-account login gate
        XposedHelpers.findAndHookMethod(actCls, "l0", new XC_MethodReplacement() {
            @Override
            protected Object replaceHookedMethod(MethodHookParam param) throws Throwable {
                Object act = param.thisObject;
                Object intent = XposedHelpers.callMethod(act, "getIntent");
                Object isInput = XposedHelpers.callMethod(intent, "getBooleanExtra", "is_input", Boolean.FALSE);
                XposedHelpers.setBooleanField(act, "e", ((Boolean) isInput).booleanValue());
                return null;
            }
        });

        // H3: n0() -> always launch the task, skip connectivity check
        XposedHelpers.findAndHookMethod(actCls, "n0", new XC_MethodReplacement() {
            @Override
            protected Object replaceHookedMethod(MethodHookParam param) throws Throwable {
                Object act = param.thisObject;
                Object task = XposedHelpers.newInstance(taskCls, act);
                XposedHelpers.setObjectField(act, "g", task);
                Object executor = Class.forName("android.os.AsyncTask")
                        .getField("THREAD_POOL_EXECUTOR").get(null);
                // NOTE: must be Void[0], NOT Object[0] — the bridge doInBackground casts to Void[]
                XposedHelpers.callMethod(task, "executeOnExecutor", executor, new Void[0]);
                return null;
            }
        });

        XposedBridge.log("NoSimHook: installed in " + lpp.processName);
    }
}
