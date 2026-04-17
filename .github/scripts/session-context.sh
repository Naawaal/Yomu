#!/bin/bash
# .github/hooks/scripts/session-context.sh
# SessionStart hook: injects project context at the start of every agent session

# Gather project information
APP_NAME=$(grep '^name:' pubspec.yaml 2>/dev/null | awk '{print $2}' || echo "unknown")
APP_VERSION=$(grep '^version:' pubspec.yaml 2>/dev/null | awk '{print $2}' || echo "unknown")
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
FLUTTER_VER=$(flutter --version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")

# Count uncommitted changes
CHANGED=$(git status --short 2>/dev/null | wc -l | tr -d ' ' || echo "0")

# Check if design system exists
DESIGN_STATUS="not yet created"
if [ -f "lib/core/theme/design_system.json" ]; then
  DESIGN_STATUS="present at lib/core/theme/design_system.json"
fi

# Check if there's an in-progress plan
PLAN_STATUS="none"
if [ -f ".github/current-plan.md" ]; then
  PLAN_STATUS="in progress — see .github/current-plan.md"
fi

CONTEXT="Flutter project context:
App: $APP_NAME v$APP_VERSION | Branch: $BRANCH | Flutter $FLUTTER_VER
Uncommitted changes: $CHANGED file(s)
Design system: $DESIGN_STATUS
Active plan: $PLAN_STATUS

Architecture: Clean Architecture + Riverpod state management
Navigation: GoRouter
Error handling: Either<Failure, T> via dartz
DI: GetIt

RULES (enforced by PostToolUse hook):
- ALL colors: colorScheme.[role] — Color() and Colors.* are forbidden
- ALL text styles: textTheme.[scale] — TextStyle() is forbidden outside theme files
- Navigation: NavigationBar (never BottomNavigationBar)
- Loading states: Shimmer skeleton (never CircularProgressIndicator alone on full screen)"

# Output as JSON for the hook system
python3 -c "
import sys, json
context = sys.argv[1]
print(json.dumps({'hookSpecificOutput': {'hookEventName': 'SessionStart', 'additionalContext': context}}))
" "$CONTEXT" 2>/dev/null || echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"Flutter project loaded. Clean architecture + Riverpod. No hardcoded colors or text styles.\"}}"