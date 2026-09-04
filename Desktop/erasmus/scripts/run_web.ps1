$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path -Path (Join-Path $scriptRoot '..')
Push-Location $projectRoot

try {
    flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:5000
} finally {
    Pop-Location
}
