#!/system/bin/sh
# 卸载钩子: 卸载模块不会还原已经写入的开关(方便继续使用adb)。
# 如需完全还原, 卸载后在root终端执行:
#   settings put global adb_enabled 0
#   settings put global verifier_verify_adb_installs 1
#   setprop persist.security.adbinstall 0
#   setprop persist.security.adbinput 0
exit 0
