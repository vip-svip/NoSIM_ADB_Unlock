# -*- coding: utf-8 -*-
"""把 module/ 目录打包成 Magisk/KernelSU/APatch 可安装的模块 zip。

- 统一转成 LF 换行（避免 Windows 编辑混入 CRLF 导致设备端 sh 报错）
- zip 内 shell 脚本与 update-binary 标记为 0755，其余 0644
- 打包后自检（testzip）并列出所有条目与权限
"""
import os
import time
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "module")
OUT = os.path.normpath(os.path.join(HERE, "..", "NoSIM_ADB_Unlock_v1.0.0.zip"))

EXEC_FILES = {"META-INF/com/google/android/update-binary"}

if not os.path.isfile(os.path.join(ROOT, "module.prop")):
    raise SystemExit("ERROR: module/module.prop not found")

if os.path.exists(OUT):
    os.remove(OUT)

count = 0
with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as z:
    for dirpath, _dirs, files in os.walk(ROOT):
        for name in sorted(files):
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, ROOT).replace("\\", "/")
            with open(full, "rb") as fh:
                data = fh.read()
            data = data.replace(b"\r\n", b"\n")
            zi = zipfile.ZipInfo(rel, date_time=time.localtime()[:6])
            zi.compress_type = zipfile.ZIP_DEFLATED
            perm = 0o755 if (rel in EXEC_FILES or rel.endswith(".sh")) else 0o644
            zi.external_attr = perm << 16
            z.writestr(zi, data)
            count += 1

with zipfile.ZipFile(OUT) as z:
    bad = z.testzip()
    if bad is not None:
        raise SystemExit("ERROR: corrupt entry: %s" % bad)
    print("entries: %d" % count)
    for i in z.infolist():
        print("  %-6s %7d  %s" % (oct(i.external_attr >> 16), i.file_size, i.filename))

print("OK -> %s" % OUT)
