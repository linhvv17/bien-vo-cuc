#!/usr/bin/env bash
# Chạy toàn bộ test tự động cho app + package (không cần thiết bị).
# Dùng từ thư mục apps/mobile:
#   chmod +x tool/run_tests.sh && ./tool/run_tests.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "== flutter pub get =="
flutter pub get

echo "== widget / integration-style tests (test/) =="
flutter test test/

echo "== bvc_ui =="
flutter test packages/bvc_ui/test/

echo "== bvc_common (dart test) =="
(cd packages/bvc_common && dart test)

echo "== OK =="
