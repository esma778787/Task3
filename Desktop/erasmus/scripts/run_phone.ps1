param(
    [string]$DeviceId
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path -Path (Join-Path $scriptRoot '..')
Push-Location $projectRoot

try {
    $adb = Get-Command adb -ErrorAction SilentlyContinue
    if (-not $adb) {
        throw 'adb bulunamadı. Lütfen Android SDK platform-tools yükleyin ve adb dizinini PATH içinde sağlayın.'
    }

    $devices = & adb devices | Select-Object -Skip 1 | Where-Object { $_ -and ($_ -notmatch '^$') }
    $authorizedDevices = @()

    foreach ($line in $devices) {
        $parts = $line -split '\s+'
        if ($parts.Count -ge 2 -and $parts[1] -eq 'device') {
            $authorizedDevices += $parts[0]
        }
    }

    if ($authorizedDevices.Count -eq 0) {
        throw 'Hiç bağlı ve yetkilendirilmiş cihaz bulunamadı. Lütfen USB hata ayıklamayı etkinleştirin ve cihazı onaylayın.'
    }

    if (-not $DeviceId) {
        if ($authorizedDevices.Count -gt 1) {
            Write-Host 'Birden fazla cihaz bağlı. Aşağıdaki DeviceId lerden birini parametre olarak verin:'
            $authorizedDevices | ForEach-Object { Write-Host "- $_" }
            throw 'Bir cihaz seçmek için run_phone.ps1 -DeviceId <cihaz_id> kullanın.'
        }
        $DeviceId = $authorizedDevices[0]
    }

    if ($authorizedDevices -notcontains $DeviceId) {
        throw "Belirtilen cihaz bulunamadı veya yetkilendirilmemiş: $DeviceId"
    }

    Write-Host "Cihaz seçildi: $DeviceId"

    Write-Host 'adb reverse yönlendirmesi oluşturuluyor...'
    try {
        & adb -s $DeviceId reverse tcp:5000 tcp:5000 2>&1 | Out-Null
    } catch {
        Write-Warning 'adb reverse komutu çalıştırılamadı. Mevcut yönlendirmeyi kaldırıp yeniden deneyeceğim.'
        & adb -s $DeviceId reverse --remove tcp:5000 tcp:5000 2>&1 | Out-Null
        & adb -s $DeviceId reverse tcp:5000 tcp:5000 2>&1 | Out-Null
    }

    Write-Host 'Yönlendirme kontrol ediliyor...'
    $reverseList = & adb -s $DeviceId reverse --list
    if ($reverseList -notmatch 'tcp:5000') {
        throw 'adb reverse tcp:5000 tcp:5000 yönlendirmesi oluşturulamadı.'
    }

    Write-Host 'Backend durum kontrolü yapılıyor...'
    try {
        $resp = Invoke-WebRequest -Uri 'http://127.0.0.1:5000/' -UseBasicParsing -TimeoutSec 5
        if ($resp.StatusCode -ne 200) {
            throw "Backend health check failed: $($resp.StatusCode)"
        }
    } catch {
        throw 'Flask backend çalışmıyor. Önce python app.py komutunu çalıştırın.'
    }

    Write-Host 'Backend çalışıyor. Flutter başlatılıyor...'
    flutter run -d $DeviceId --dart-define=API_BASE_URL=http://127.0.0.1:5000
} finally {
    Pop-Location
}
