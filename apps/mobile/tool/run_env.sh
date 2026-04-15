#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="${1:-}"
MODE="${2:-run}" # run | run-release | build-apk | build-appbundle | build-ios

if [[ -z "$ENV_NAME" ]]; then
  echo "Usage: tool/run_env.sh <dev|uat|prod> [run|run-release|build-apk|build-appbundle|build-ios]" >&2
  exit 2
fi

case "$ENV_NAME" in
  dev)  ENV_FILE=".env.dev" ;;
  uat)  ENV_FILE=".env.uat" ;;
  prod) ENV_FILE=".env.prod" ;;
  *) echo "Unknown env: $ENV_NAME (expected dev|uat|prod)" >&2; exit 2 ;;
esac

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE. Create it from .env.example (or set dart-define manually)." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

API_BASE_URL="${API_BASE_URL:-}"
ENVIRONMENT="${ENVIRONMENT:-}"
USE_MOCK="${USE_MOCK:-}"

if [[ -z "$API_BASE_URL" || -z "$ENVIRONMENT" || -z "$USE_MOCK" ]]; then
  echo "$ENV_FILE must define: API_BASE_URL, ENVIRONMENT, USE_MOCK" >&2
  exit 1
fi

COMMON_ARGS=(
  "--dart-define=API_BASE_URL=$API_BASE_URL"
  "--dart-define=ENVIRONMENT=$ENVIRONMENT"
  "--dart-define=USE_MOCK=$USE_MOCK"
)

case "$MODE" in
  run)
    flutter run "${COMMON_ARGS[@]}"
    ;;
  run-release)
    flutter run --release "${COMMON_ARGS[@]}"
    ;;
  build-apk)
    flutter build apk --release "${COMMON_ARGS[@]}"
    ;;
  build-appbundle)
    flutter build appbundle --release "${COMMON_ARGS[@]}"
    ;;
  build-ios)
    flutter build ios --release "${COMMON_ARGS[@]}"
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    exit 2
    ;;
esac

