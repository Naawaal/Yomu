#!/bin/bash
# PostToolUse hook: runs flutter analyze after file edits
# Injects results into agent context via additionalContext

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# Only trigger on file writes
case "$TOOL_NAME" in
  editFiles|createFile|create_file|str_replace_based_edit_tool) ;;
  *) echo '{"continue":true}'; exit 0 ;;
esac

# Get changed dart files
FILES=$(echo "$INPUT" | jq -r '
  .tool_input.files[]?,
  .tool_input.path?,
  .tool_input.new_file_path?
  | select(. != null)' 2>/dev/null | grep '\.dart$' || true)

[ -z "$FILES" ] && echo '{"continue":true}' && exit 0

# Apply dart fixes silently
echo "$FILES" | xargs dart fix --apply 2>/dev/null || true

# Run analyze
RESULT=$(flutter analyze $FILES --no-fatal-infos 2>&1 | \
         grep -E '\b(error|warning)\b' | head -15)

if [ -n "$RESULT" ]; then
  COUNT=$(echo "$RESULT" | wc -l | tr -d ' ')
  MSG="⚠️ flutter analyze: $COUNT issue(s) found — fix before marking TODO complete:\n$RESULT"
else
  MSG="✅ flutter analyze: clean"
fi

# Return as additionalContext (injected into agent conversation)
python3 -c "
import sys, json
msg = sys.argv[1]
output = {
  'hookSpecificOutput': {
    'hookEventName': 'PostToolUse',
    'additionalContext': msg
  }
}
print(json.dumps(output))
" "$MSG" 2>/dev/null || echo '{"continue":true}'