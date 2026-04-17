# PostToolUse hook: runs flutter analyze after file edits and returns hook context JSON.

$rawInput = ($input | Out-String)
if ([string]::IsNullOrWhiteSpace($rawInput)) {
  '{"continue":true}'
  exit 0
}

try {
  $payload = $rawInput | ConvertFrom-Json -ErrorAction Stop
} catch {
  '{"continue":true}'
  exit 0
}

$toolName = [string]$payload.tool_name
$writeTools = @('editFiles', 'createFile', 'create_file', 'str_replace_based_edit_tool')
if (-not $writeTools.Contains($toolName)) {
  '{"continue":true}'
  exit 0
}

$files = New-Object System.Collections.Generic.List[string]

if ($null -ne $payload.tool_input.files) {
  foreach ($f in $payload.tool_input.files) {
    if (-not [string]::IsNullOrWhiteSpace([string]$f)) {
      $files.Add([string]$f)
    }
  }
}

if (-not [string]::IsNullOrWhiteSpace([string]$payload.tool_input.path)) {
  $files.Add([string]$payload.tool_input.path)
}

if (-not [string]::IsNullOrWhiteSpace([string]$payload.tool_input.new_file_path)) {
  $files.Add([string]$payload.tool_input.new_file_path)
}

$dartFiles = $files |
  Where-Object { $_ -match '\.dart$' } |
  Sort-Object -Unique

if (-not $dartFiles -or $dartFiles.Count -eq 0) {
  '{"continue":true}'
  exit 0
}

foreach ($file in $dartFiles) {
  try {
    & dart fix --apply "$file" *> $null
  } catch {
    # Best-effort only.
  }
}

$analyzeOutput = @()
try {
  $analyzeOutput = & flutter analyze @dartFiles --no-fatal-infos 2>&1
} catch {
  $analyzeOutput = @("flutter analyze failed: $($_.Exception.Message)")
}

$issueLines = $analyzeOutput |
  ForEach-Object { [string]$_ } |
  Where-Object { $_ -match '\berror\b|\bwarning\b' } |
  Select-Object -First 15

if ($issueLines.Count -gt 0) {
  $count = $issueLines.Count
  $msg = "⚠️ flutter analyze: $count issue(s) found — fix before marking TODO complete:`n$($issueLines -join "`n")"
} else {
  $msg = "✅ flutter analyze: clean"
}

$output = @{
  hookSpecificOutput = @{
    hookEventName = 'PostToolUse'
    additionalContext = $msg
  }
}

$output | ConvertTo-Json -Compress -Depth 4
