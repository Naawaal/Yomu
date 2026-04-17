#!/bin/bash
# Compatibility wrapper for hook configs that reference .github/hooks/scripts.
# Delegates to the canonical script location.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

exec "$ROOT_DIR/.github/scripts/flutter-quality.sh" "$@"
