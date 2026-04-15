

#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./run_env_production.sh [run|run-release|build-apk|build-appbundle|build-ios]

MODE="${1:-run}"
exec "$(dirname "$0")/tool/run_env.sh" prod "$MODE"

