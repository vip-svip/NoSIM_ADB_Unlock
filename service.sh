#!/system/bin/sh
# =============================================================
#  No-SIM USB Debug & Install Unlock  (v2 service)
#  v2 新增: 直接维护 SecurityCenter 的 remote_provider_preferences.xml
#           (MIUI「USB安装」开关的真正存储位置, 绕过 SIM 卡校验)
#  流程: 等开机完成 -> 杀 SecurityCenter -> 写 XML true -> 系统自动拉起
# =============================================================

MODDIR=${0%/*}
[ -d "$MODDIR" ] || MODDIR=/data/adb/modules/no_sim_adb_unlock
LOG="$MODDIR/service.log"
BB=/data/adb/ksu/bin/busybox
[ -x "$BB" ] || BB=busybox

PREF=/data/data/com.miui.securitycenter/shared_prefs/remote_provider_preferences.xml
WATCHDOG_INTERVAL=30

log() { echo "$(date '+%F %T') $*" >> "$LOG"; }

set_prop() {
    if command -v resetprop >/dev/null 2>&1; then
        resetprop "$1" "$2"
    else
        setprop "$1" "$2" 2>/dev/null
    fi
}

apply_props() {
    settings put global adb_enabled 1
    set_prop persist.security.adbinstall 1
    set_prop persist.security.adbinput 1
    settings put global verifier_verify_adb_installs 0
}

# 写入 SecurityCenter 的 USB安装 开关 (真正生效的存储位置)
apply_sp() {
    [ -f "$PREF" ] || { log "!! pref 文件不存在: $PREF"; return 1; }
    # 已是 true 则跳过
    if $BB grep -q 'name="security_adb_install_enable" value="true"' "$PREF"; then
        return 0
    fi
    # 杀掉 securitycenter 全部进程 (防止旧内存值在退出时覆盖文件)
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
    if $BB grep -q 'name="security_adb_install_enable" value="true"' "$PREF"; then
        log "USB安装 SP 已写入 true"
        return 0
    else
        log "!! SP 写入失败"
        return 1
    fi
}

state_line() {
    echo "adb_enabled=$(settings get global adb_enabled) | adbinstall=$(getprop persist.security.adbinstall) | adbinput=$(getprop persist.security.adbinput) | sp=$($BB grep -c 'security_adb_install_enable" value="true"' $PREF 2>/dev/null || echo NA)"
}

# ---------- 等待系统启动完成 ----------
i=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ "$i" -lt 120 ]; do
    sleep 2
    i=$((i + 1))
done
sleep 15

apply_props
apply_sp
log "开机应用完成: $(state_line)"

# ---------- 守护 ----------
if [ ! -f "$MODDIR/no_watchdog" ]; then
    (
        while true; do
            sleep "$WATCHDOG_INTERVAL"
            [ "$(settings get global adb_enabled)" != "1" ] && apply_props
            if [ -f "$PREF" ] && ! $BB grep -q 'security_adb_install_enable" value="true"' "$PREF"; then
                # 只有用户主动关闭时才不回写 —— 界面点击关闭会留下 intent 痕迹,
                # 这里简化处理: 无条件维持 true (用户想关可在管理器停用模块)
                apply_sp
                log "检测到 USB安装 SP 被改回, 已重新应用"
            fi
        done
    ) &
fi

exit 0
