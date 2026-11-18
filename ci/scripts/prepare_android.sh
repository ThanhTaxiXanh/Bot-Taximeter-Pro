#!/usr/bin/env bash
# Chuẩn bị thư mục android/ trên CI. Chạy lại nhiều lần không hỏng (idempotent).
# Biến môi trường (đều có mặc định):
#   APP_LABEL, APP_ORG, APP_PROJECT_NAME, MAPS_API_KEY
set -euo pipefail

APP_ORG="${APP_ORG:-vn.bottaximeter}"
APP_PROJECT_NAME="${APP_PROJECT_NAME:-bot_taximeter_pro}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

had_widget_test=false
[ -f test/widget_test.dart ] && had_widget_test=true

if [ ! -d android ]; then
  echo ">> Chưa có android/, chạy flutter create..."
  flutter create --platforms=android --org "$APP_ORG" --project-name "$APP_PROJECT_NAME" .
  # flutter create sinh test mẫu (đếm số) sẽ làm hỏng flutter test, xóa nếu do nó tạo ra.
  if [ "$had_widget_test" = false ]; then
    rm -f test/widget_test.dart
  fi
else
  echo ">> Đã có android/, chỉ vá lại cấu hình."
fi

if [ -z "${MAPS_API_KEY:-}" ]; then
  echo "::warning::Chưa có Secret MAPS_API_KEY, bản đồ sẽ trống nhưng ứng dụng vẫn chạy."
fi

python3 "$SCRIPT_DIR/patch_android.py"
echo ">> Xong bước chuẩn bị Android."
