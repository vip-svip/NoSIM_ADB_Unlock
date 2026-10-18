# No-SIM USB Debug & Install Unlock（无SIM卡解锁 USB调试 / USB安装）

> GitHub: <https://github.com/vip-svip/NoSIM_ADB_Unlock>

一个 Magisk / KernelSU / APatch 模块：手机没插 SIM 卡时，
强制开启开发者选项里的「USB调试」和「USB安装」（MIUI/HyperOS 国行常见限制）。

## 前提

- 手机已解锁 BL 并已装好 Magisk / KernelSU / APatch（模块必须依赖 root 才能安装）。

## 原理

设置 App 打开这两个开关前会做 SIM 卡 / 账号校验，但校验只是 UI 层拦截，
真正的开关在系统底层。本模块在每次开机后以 root 直接写入底层开关：

| 开关 | 底层值 |
|---|---|
| USB调试（Android 原生） | `settings put global adb_enabled 1` |
| USB安装（MIUI/HyperOS） | `persist.security.adbinstall=1` |
| USB调试(安全设置)/adb模拟输入（MIUI） | `persist.security.adbinput=1` |
| adb 安装免“验证应用” | `settings put global verifier_verify_adb_installs 0` |

并附带 30 秒一次的守护：如果系统把这些开关自动关回去，会立即重新打开。

## 安装

1. 把 `NoSIM_ADB_Unlock_v1.0.0.zip` 传到手机。
2. Magisk：模块 → 从本地安装 → 选择 zip → 重启。
   KernelSU / APatch：模块 → 从存储安装 → 选择 zip → 重启。
3. 重启后生效（开机后约 10~20 秒完成应用）。

## 验证

- 开发者选项里「USB调试」会直接显示已开启（即使没有 SIM 卡）。
- 插电脑执行 `adb devices`，手机弹出授权对话框选“始终允许”。
- `adb install xxx.apk` 不再需要手机端确认。
- **注意**：MIUI 的「USB安装」开关在界面上可能仍显示灰色/关闭——忽略它，
  以实际 `adb install` 是否免确认为准。
- 运行日志：`/data/adb/modules/no_sim_adb_unlock/service.log`。

## 管理器里的 [执行](Action) 按钮

点击后立即重新应用一次全部设置（`action.sh`），无需重启，并回显当前各开关的值。

## 关闭守护

默认每 30 秒检查并维持开关为开。如果你希望自己手动控制、不让它自动拉起：

```
su
touch /data/adb/modules/no_sim_adb_unlock/no_watchdog
```

然后重启。之后模块只在开机时设置一次。

## 卸载

在管理器里删除本模块即可。已写入的开关会保留（不影响继续使用 adb）。
如需完全还原，root shell 执行：

```
settings put global adb_enabled 0
settings put global verifier_verify_adb_installs 1
setprop persist.security.adbinstall 0
setprop persist.security.adbinput 0
```

## 手动等效命令（不装模块，在已 root 终端执行一次同样有效）

```
su
settings put global adb_enabled 1
setprop persist.security.adbinstall 1
setprop persist.security.adbinput 1
settings put global verifier_verify_adb_installs 0
```

## 兼容性

- **MIUI / HyperOS**（小米/红米）：全部功能生效。
- **其他系统**（OPPO/vivo/三星等）：`adb_enabled` 是 Android 原生开关，
  USB调试部分基本有效；各家的“USB安装”是私有实现，不保证生效。
- 不依赖 Xposed / LSPosed，不修改 system 分区。

## 故障排查

- `adb devices` 无设备：换数据线/USB口、装好驱动；模块只负责开关，不涉及 USB 硬件。
- `service.log` 里 `adbinstall` 值为空：说明该版本系统改了属性名，
  请反馈机型 + 系统版本以便适配。
- 非小米机型想解锁“USB安装”：告诉我品牌和系统版本，我再做针对性适配。

## 安全提示

USB调试常开 + 守护意味着任何能物理接触手机的人配合已授权电脑可以做更多操作。
不用时建议在管理器里停用本模块并关闭 USB 调试。

## 文件结构

- `service.sh` — 开机后应用全部设置 + 守护进程
- `action.sh` — 管理器“执行”按钮：立即重新应用
- `uninstall.sh` — 卸载钩子（不还原设置，仅说明）
- `customize.sh` — 安装时的提示与权限设置
- `META-INF/...` — 兼容 Magisk / KernelSU / APatch 的安装器
