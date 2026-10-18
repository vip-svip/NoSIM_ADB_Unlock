#!/system/bin/sh
# 在管理器(Magisk/KernelSU/APatch)中点击本模块的 [执行/Action] 按钮时运行:
# 立即重新应用一次全部设置, 无需重启
MODDIR=${0%/*}
[ -d "$MODDIR" ] || MODDIR=/data/adb/modules/no_sim_adb_unlock

if command -v resetprop >/dev/null 2>&1; then
    resetprop persist.security.adbinstall 1
    resetprop persist.security.adbinput 1
else
    setprop persist.security.adbinstall 1
    setprop persist.security.adbinput 1
fi

settings put global adb_enabled 1
settings put global verifier_verify_adb_installs 0

echo "已重新应用, 当前状态:"
echo "  USB调试 adb_enabled             = $(settings get global adb_enabled)"
echo "  USB安装 persist...adbinstall    = $(getprop persist.security.adbinstall)"
echo "  ADB输入 persist...adbinput      = $(getprop persist.security.adbinput)"
echo "  adb安装验证 verifier_verify_adb = $(settings get global verifier_verify_adb_installs)"
echo "日志: $MODDIR/service.log"
exit 0
