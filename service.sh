#!/system/bin/sh
# =============================================================
#  No-SIM USB Debug & Install Unlock
#  作用: 手机无SIM卡时, 绕过设置界面的SIM卡校验,
#        直接在底层打开 USB调试 / USB安装(含ADB模拟输入)
#  原理:
#    USB调试(原生)   -> Settings.Global: adb_enabled = 1
#    USB安装(MIUI)   -> persist.security.adbinstall = 1
#    ADB输入(MIUI)   -> persist.security.adbinput  = 1
#    adb安装免验证   -> Settings.Global: verifier_verify_adb_installs = 0
#  运行阶段: late_start service (系统完全开机后)
# =============================================================

MODDIR=${0%/*}
[ -d "$MODDIR" ] || MODDIR=/data/adb/modules/no_sim_adb_unlock
LOG="$MODDIR/service.log"

# 守护检查间隔(秒)。想关闭守护: 在模块目录新建 no_watchdog 文件后重启
WATCHDOG_INTERVAL=30

set_prop() {
    if command -v resetprop >/dev/null 2>&1; then
        resetprop "$1" "$2"
    else
        setprop "$1" "$2" 2>/dev/null
    fi
}

apply_all() {
    # 1) USB调试总开关(Android原生, 绕过设置App里的SIM卡校验)
    settings put global adb_enabled 1
    # 2) MIUI/HyperOS「USB安装」: adb/USB安装应用免手机端确认
    set_prop persist.security.adbinstall 1
    # 3) MIUI/HyperOS「USB调试(安全设置)」: 允许adb模拟点击/输入
    set_prop persist.security.adbinput 1
    # 4) adb安装时跳过"验证应用"提示
    settings put global verifier_verify_adb_installs 0
}

state_line() {
    echo "adb_enabled=$(settings get global adb_enabled) | adbinstall=$(getprop persist.security.adbinstall) | adbinput=$(getprop persist.security.adbinput) | verifier_adb=$(settings get global verifier_verify_adb_installs)"
}

log() {
    echo "$(date '+%F %T') $*" >> "$LOG"
}

# ---------- 等待系统启动完成 ----------
i=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ "$i" -lt 120 ]; do
    sleep 2
    i=$((i + 1))
done
sleep 10

apply_all
log "开机应用完成: $(state_line)"

# ---------- 守护: 被系统自动改回时立即重新开启 ----------
if [ ! -f "$MODDIR/no_watchdog" ]; then
    (
        while true; do
            sleep "$WATCHDOG_INTERVAL"
            if [ "$(settings get global adb_enabled)" != "1" ] \
               || [ "$(getprop persist.security.adbinstall)" != "1" ] \
               || [ "$(getprop persist.security.adbinput)" != "1" ]; then
                apply_all
                log "检测到开关被改回, 已重新应用: $(state_line)"
            fi
        done
    ) &
fi

exit 0
