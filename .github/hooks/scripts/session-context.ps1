# Compatibility wrapper for hook configs that reference .github/hooks/scripts.
# Delegates to the canonical script location.

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Resolve-Path (Join-Path $scriptDir "..\..\..")

& (Join-Path $rootDir ".github\scripts\session-context.ps1") @args
exit $LASTEXITCODE
