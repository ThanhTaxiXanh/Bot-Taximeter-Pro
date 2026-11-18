#!/usr/bin/env python3
"""Vá AndroidManifest.xml và build.gradle(.kts) cho dự án Flutter. Chạy lại nhiều lần vẫn an toàn.

Đường dẫn gốc có thể đổi bằng biến môi trường ANDROID_DIR (mặc định ./android) để dễ kiểm thử.
"""
import os
import pathlib
import re
import sys

ANDROID_DIR = pathlib.Path(os.environ.get("ANDROID_DIR", "android"))
APP_LABEL = os.environ.get("APP_LABEL", "BOT TAXIMETER PRO")
MAPS_API_KEY = os.environ.get("MAPS_API_KEY", "").strip() or "MISSING_MAPS_API_KEY"
MIN_SDK = os.environ.get("MIN_SDK", "24")

PERMISSIONS = [
    "android.permission.INTERNET",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.FOREGROUND_SERVICE",
    "android.permission.FOREGROUND_SERVICE_LOCATION",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.VIBRATE",
    "android.permission.WAKE_LOCK",
    "android.permission.RECORD_AUDIO",
]
META_KEY = "com.google.android.geo.API_KEY"


def xml_attr(value: str) -> str:
    return (value.replace("&", "&amp;").replace('"', "&quot;")
            .replace("<", "&lt;").replace(">", "&gt;"))


def patch_manifest() -> None:
    path = ANDROID_DIR / "app/src/main/AndroidManifest.xml"
    if not path.exists():
        sys.exit(f"Không thấy {path}")
    text = path.read_text(encoding="utf-8")

    # 1) Quyền: thêm những quyền còn thiếu ngay sau thẻ <manifest ...>
    missing = [p for p in PERMISSIONS if f'android:name="{p}"' not in text]
    if missing:
        block = "".join(f'\n    <uses-permission android:name="{p}"/>' for p in missing)
        text, n = re.subn(r"(<manifest\b[^>]*>)", lambda m: m.group(1) + block, text, count=1)
        if n == 0:
            sys.exit("Không tìm thấy thẻ <manifest>")

    # 2) Nhãn ứng dụng (chỉ thẻ <application>)
    def set_label(m):
        tag = m.group(0)
        if "android:label=" in tag:
            return re.sub(r'android:label="[^"]*"', f'android:label="{xml_attr(APP_LABEL)}"', tag, count=1)
        return tag[:-1] + f' android:label="{xml_attr(APP_LABEL)}">'

    text = re.sub(r"<application\b[^>]*>", set_label, text, count=1, flags=re.DOTALL)

    # 3) Khóa Google Maps
    meta = f'<meta-data android:name="{META_KEY}" android:value="{xml_attr(MAPS_API_KEY)}"/>'
    existing = re.compile(r'<meta-data\s+android:name="' + re.escape(META_KEY) + r'"[^>]*/>')
    if existing.search(text):
        text = existing.sub(lambda _m: meta, text, count=1)
    else:
        text = text.replace("</application>", f"    {meta}\n    </application>", 1)

    path.write_text(text, encoding="utf-8")
    print(f"Manifest: thêm {len(missing)} quyền, nhãn '{APP_LABEL}', khóa Maps đã cài.")


def patch_gradle() -> None:
    candidates = [ANDROID_DIR / "app/build.gradle.kts", ANDROID_DIR / "app/build.gradle"]
    path = next((p for p in candidates if p.exists()), None)
    if path is None:
        sys.exit("Không thấy android/app/build.gradle(.kts)")
    text = path.read_text(encoding="utf-8")

    pattern = re.compile(r"(minSdk(?:Version)?)(\s*=?\s*)flutter\.minSdkVersion")
    new_text, n = pattern.subn(lambda m: f"{m.group(1)}{m.group(2)}{MIN_SDK}", text)
    if n == 0:
        # Đã là số cố định: chỉ nâng lên nếu đang thấp hơn MIN_SDK
        def bump(m):
            return m.group(0) if int(m.group(3)) >= int(MIN_SDK) else f"{m.group(1)}{m.group(2)}{MIN_SDK}"
        new_text, n2 = re.subn(r"(minSdk(?:Version)?)(\s*=?\s*)(\d+)", bump, text)
        if n2 == 0:
            print("::warning::Không tìm thấy minSdk trong build.gradle, giữ nguyên.")
    path.write_text(new_text, encoding="utf-8")
    print(f"Gradle ({path.name}): minSdk = {MIN_SDK}")


if __name__ == "__main__":
    patch_manifest()
    patch_gradle()
