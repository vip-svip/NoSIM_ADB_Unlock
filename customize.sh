# =============================================================
#  No-SIM USB Debug & Install Unlock — 安装脚本
#  兼容 Magisk / KernelSU / APatch 的模块安装环境
# =============================================================

ui_print "************************************"
ui_print "  No-SIM USB Debug & Install Unlock"
ui_print "  无SIM卡解锁 USB调试 / USB安装"
ui_print "************************************"
ui_print "- 设备: $(getprop ro.product.brand) $(getprop ro.product.model)"
ui_print "- 系统: Android $(getprop ro.build.version.release)"
_mi=$(getprop ro.miui.ui.version.name)
_hy=$(getprop ro.mi.os.version.name)
[ -n "$_mi$_hy" ] && ui_print "- MIUI/HyperOS: ${_mi} ${_hy}"
if [ -n "${MAGISK_VER:-}" ]; then
    ui_print "- 管理器: Magisk ${MAGISK_VER} (${MAGISK_VER_CODE})"
else
    ui_print "- 管理器: KernelSU / APatch"
fi
ui_print "- 安装完成后重启一次即可生效"
ui_print "- 生效后可在开发者选项确认 USB调试 已开启"
ui_print "- 运行日志: /data/adb/modules/no_sim_adb_unlock/service.log"
ui_print "- 也可在管理器里点本模块的 [执行] 按钮立即应用"

# 权限
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh"   0 0 0755
set_perm "$MODPATH/action.sh"    0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755

exit 0
