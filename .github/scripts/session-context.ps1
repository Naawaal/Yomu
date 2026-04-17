# SessionStart hook: inject project context at session start.

function Get-PubspecValue {
  param([string]$Key)
  if (-not (Test-Path 'pubspec.yaml')) { return 'unknown' }
  $line = Select-String -Path 'pubspec.yaml' -Pattern "^${Key}:\s*(.+)$" -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($null -eq $line) { return 'unknown' }
  return $line.Matches[0].Groups[1].Value.Trim()
}

$appName = Get-PubspecValue -Key 'name'
$appVersion = Get-PubspecValue -Key 'version'

$branch = 'unknown'
try {
  $branchResult = (& git branch --show-current 2>$null | Select-Object -First 1)
  if (-not [string]::IsNullOrWhiteSpace($branchResult)) { $branch = $branchResult.Trim() }
} catch {}

$flutterVer = 'unknown'
try {
  $firstLine = (& flutter --version 2>$null | Select-Object -First 1)
  if (-not [string]::IsNullOrWhiteSpace($firstLine)) {
    $parts = ($firstLine -split '\s+')
    if ($parts.Count -ge 2) { $flutterVer = $parts[1] }
  }
} catch {}

$changed = '0'
try {
  $statusLines = (& git status --short 2>$null)
  if ($null -ne $statusLines) { $changed = @($statusLines).Count.ToString() }
} catch {}

$designStatus = 'not yet created'
if (Test-Path 'lib/core/theme/design_system.json') {
  $designStatus = 'present at lib/core/theme/design_system.json'
}

$planStatus = 'none'
if (Test-Path '.github/current-plan.md') {
  $planStatus = 'in progress — see .github/current-plan.md'
}

$context = @"
Flutter project context:
App: $appName v$appVersion | Branch: $branch | Flutter $flutterVer
Uncommitted changes: $changed file(s)
Design system: $designStatus
Active plan: $planStatus

Architecture: Clean Architecture + Riverpod state management
Navigation: GoRouter
Error handling: Either<Failure, T> via dartz
DI: GetIt

RULES (enforced by PostToolUse hook):
- ALL colors: colorScheme.[role] — Color() and Colors.* are forbidden
- ALL text styles: textTheme.[scale] — TextStyle() is forbidden outside theme files
- Navigation: NavigationBar (never BottomNavigationBar)
- Loading states: Shimmer skeleton (never CircularProgressIndicator alone on full screen)
"@

$output = @{
  hookSpecificOutput = @{
    hookEventName = 'SessionStart'
    additionalContext = $context
  }
}

$output | ConvertTo-Json -Compress -Depth 4
