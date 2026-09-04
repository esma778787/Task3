$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path -Path (Join-Path $scriptRoot '..')
Push-Location $projectRoot

try {
    flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000
} finally {
    Pop-Location
}
