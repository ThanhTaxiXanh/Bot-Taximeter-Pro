#!/usr/bin/env python3
"""Gom log CI thành báo cáo Markdown ngắn gọn, in ra stdout.
Bạn dán báo cáo này cho AI để AI sửa đúng chỗ lỗi."""
import os
import pathlib
import re

LOGS = pathlib.Path("logs")
MAX_BODY = 60000  # Issue GitHub giới hạn khoảng 65.536 ký tự

STATUS = {
    "success": "✅ Đạt",
    "failure": "❌ Lỗi",
    "skipped": "⏭️ Bỏ qua",
    "cancelled": "⚪ Đã hủy",
}


def read(name: str) -> str:
    p = LOGS / name
    return p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""


def tail(text: str, n: int) -> str:
    return "\n".join(text.strip().splitlines()[-n:])


def pick(text: str, pattern: str, limit: int) -> list:
    rx = re.compile(pattern)
    out = []
    for line in text.splitlines():
        if rx.search(line):
            out.append(line.rstrip())
            if len(out) >= limit:
                break
    return out


def status(value: str) -> str:
    return STATUS.get(value or "skipped", f"❔ {value}")


def block(title: str, lines: list) -> str:
    if not lines:
        return ""
    body = "\n".join(lines)
    return f"\n**{title}**\n```text\n{body}\n```\n"


def main() -> None:
    env = os.environ
    analyze = env.get("ANALYZE_OUTCOME", "")
    unit = env.get("UNIT_OUTCOME", "")
    apk = env.get("APK_OUTCOME", "")
    build_job = env.get("BUILD_JOB_RESULT", "")
    ui_job = env.get("UI_JOB_RESULT", "")
    ui_raw = read("ui_outcome.txt").strip()
    ui = ui_raw or ("skipped" if ui_job in ("", "skipped") else ui_job)

    repo = env.get("GITHUB_REPOSITORY", "")
    server = env.get("GITHUB_SERVER_URL", "https://github.com")
    run_id = env.get("GITHUB_RUN_ID", "")
    run_no = env.get("GITHUB_RUN_NUMBER", "?")
    sha = env.get("GITHUB_SHA", "")[:7]
    run_url = f"{server}/{repo}/actions/runs/{run_id}" if run_id else ""

    flutter_ver = " | ".join(read("flutter-version.txt").splitlines()[:2])

    all_ok = (analyze == "success" and unit == "success" and apk == "success"
              and ui in ("success", "skipped"))

    out = []
    out.append(f"# Báo cáo CI #{run_no} ({sha})")
    out.append("**Kết quả chung: " + ("✅ TẤT CẢ ĐẠT" if all_ok else "❌ CÓ MỤC CẦN SỬA") + "**\n")
    if run_url:
        out.append(f"Lượt chạy: {run_url}")
    if flutter_ver:
        out.append(f"Flutter: `{flutter_ver}`")
    sha1 = env.get("SHA1", "")
    if sha1:
        out.append(f"SHA-1 khóa debug: `{sha1}`")
    out.append("")
    out.append("| Hạng mục | Kết quả |")
    out.append("|---|---|")
    out.append(f"| Phân tích tĩnh (flutter analyze) | {status(analyze)} |")
    out.append(f"| Test đơn vị và widget (flutter test) | {status(unit)} |")
    out.append(f"| Build APK debug | {status(apk)} |")
    out.append(f"| Test giao diện Android 13 | {status(ui)} |")
    if apk == "success" and repo:
        out.append("")
        out.append(f"APK tải về điện thoại: {server}/{repo}/releases/tag/debug-latest")

    detail = []
    prep = read("prepare.log")
    if build_job == "failure" and not read("analyze.log") and prep:
        detail.append(block("Lỗi bước chuẩn bị Android (cuối log)", tail(prep, 30).splitlines()))

    pub = read("pubget.log")
    if pub and re.search(r"Because .* (depends on|requires)|version solving failed|Could not find|pub get failed", pub):
        detail.append(block("Lỗi pub get (xung đột phiên bản)", tail(pub, 25).splitlines()))

    if analyze == "failure":
        issues = pick(read("analyze.log"), r"^\s*(error|warning)\s+•", 40)
        detail.append(block("flutter analyze: lỗi và cảnh báo", issues or tail(read("analyze.log"), 30).splitlines()))

    if unit == "failure":
        t = read("test.log")
        key = pick(t, r"\[E\]|Expected:|Actual:|Which:|EXCEPTION CAUGHT|Some tests failed|Failed to load|Error: ", 40)
        detail.append(block("flutter test: chỗ lỗi", key))
        detail.append(block("flutter test: cuối log", tail(t, 25).splitlines()))

    if apk == "failure":
        b = read("build.log")
        key = pick(b, r"FAILURE:|What went wrong|Execution failed|error:|Error:|e: file|Unresolved|Could not", 30)
        detail.append(block("Build APK: nguyên nhân", key))
        detail.append(block("Build APK: cuối log", tail(b, 30).splitlines()))

    if ui == "failure":
        u = read("ui.log")
        key = pick(u, r"\[E\]|Expected:|Actual:|Which:|EXCEPTION CAUGHT|Some tests failed|Failed to load|Error: |Found 0", 40)
        detail.append(block("Test giao diện: chỗ lỗi", key))
        detail.append(block("Test giao diện: cuối log", tail(u, 25).splitlines()))

    detail = [d for d in detail if d]
    if detail:
        out.append("\n## Chi tiết lỗi")
        out.extend(detail)

    out.append("\n## Prompt dán cho AI")
    out.append("```text")
    out.append("Đây là báo cáo CI của dự án Bột TaxiMeter Pro (Flutter, build bằng GitHub Actions).")
    out.append("Hãy sửa đúng các file gây lỗi theo báo cáo, theo quy tắc trong Master Prompt:")
    out.append("- chỉ gửi lại các file đã sửa, mỗi file một khối code, tiêu đề là đường dẫn đầy đủ;")
    out.append("- ghi một dòng nguyên nhân cho mỗi lỗi; không viết lại phần đang chạy đúng;")
    out.append("- nếu thiếu thông tin để chắc chắn, hỏi tôi một lần gộp rồi mới sửa.")
    out.append("```")

    body = "\n".join(out)
    if len(body) > MAX_BODY:
        body = body[:MAX_BODY] + "\n\n... (đã cắt bớt, xem log đầy đủ trong Artifacts của lượt chạy)"
    print(body)


if __name__ == "__main__":
    main()
