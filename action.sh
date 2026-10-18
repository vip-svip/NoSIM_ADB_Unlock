#!/system/bin/sh
# 管理器 [执行] 按钮: 立即重新应用全部设置 (含 SP 写入)
MODDIR=${0%/*}
[ -d "$MODDIR" ] || MODDIR=/data/adb/modules/no_sim_adb_unlock
BB=/data/adb/ksu/bin/busybox
[ -x "$BB" ] || BB=busybox
PREF=/data/data/com.miui.securitycenter/shared_prefs/remote_provider_preferences.xml

if command -v resetprop >/dev/null 2>&1; then
    resetprop persist.security.adbinstall 1
    resetprop persist.security.adbinput 1
else
    setprop persist.security.adbinstall 1
    setprop persist.security.adbinput 1
fi
settings put global adb_enabled 1
settings put global verifier_verify_adb_installs 0

if [ -f "$PREF" ]; then
    if ! $BB grep -q 'security_adb_install_enable" value="true"' "$PREF"; then
        for p in $(ps -A -o PID,NAME 2>/dev/null | grep securitycenter | grep -v grep | $BB awk '{print $1}'); do
            kill -9 "$p" 2>/dev/null
        done
        sleep 1
        if $BB grep -q 'security_adb_install_enable' "$PREF"; then
            $BB sed -i 's|name="security_adb_install_enable" value="false"|name="security_adb_install_enable" value="true"|' "$PREF"
        else
            $BB sed -i 's|</map>|    <boolean name="security_adb_install_enable" value="true" />\n</map>|' "$PREF"
        fi
        chown 1000:1000 "$PREF"
        chmod 660 "$PREF"
        restorecon "$PREF" 2>/dev/null
    fi
fi

echo "已重新应用, 当前状态:"
echo "  USB调试  adb_enabled             = $(settings get global adb_enabled)"
echo "  USB安装(SP) security_adb_install = $($BB grep -c 'security_adb_install_enable" value="true"' $PREF 2>/dev/null || echo 0) (1=开)"
echo "  属性    persist...adbinstall    = $(getprop persist.security.adbinstall)"
echo "  ADB输入 persist...adbinput      = $(getprop persist.security.adbinput)"
echo "日志: $MODDIR/service.log"
exit 0
