# Care360 Patient: signed Google Play AAB on the authorized publisher's Windows PC.
# Local-only production preparation. Does NOT upload/publish to Google Play.
# Example: .\tools\build-patient-play-aab.ps1 -BuildName 7.3.0 -BuildNumber 124
# Both version values must be confirmed against the publisher's Play Console.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$BuildName,
    [Parameter(Mandatory=$true)][int]$BuildNumber
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root

function Invoke-Checked([string]$Command, [string[]]$Args) {
    & $Command @Args
    if ($LASTEXITCODE -ne 0) {
        throw "$Command failed (exit code $LASTEXITCODE). Release output is not approved."
    }
}
if ($BuildName -notmatch '^\d+\.\d+\.\d+$') { throw 'BuildName must be a verified semantic version, e.g. 7.3.0.' }
if ($BuildNumber -le 0) { throw 'BuildNumber must exceed the last versionCode from Play Console.' }
if ($env:K3_OFFLINE_TEST -eq 'true') { throw 'Synthetic offline build flag must never be enabled for Play.' }
if (-not $env:K3_API_BASE_URL) { throw 'Set a verified production K3_API_BASE_URL first.' }
if (-not $env:K3_PRODUCTION_FIREBASE_PROJECT_ID) { throw 'Verify production Firebase project ID.' }
if (-not $env:K3_ANDROID_MAPS_API_KEY) { throw 'Set Android Maps key restricted to this package and signing certificate.' }
if (-not $env:K3_PLAY_LATEST_VERSION_CODE) { throw 'Read current versionCode from Play Console; do not guess.' }

$env:K3_BUILD_ENV = 'production'
$env:K3_ANDROID_NEXT_VERSION_CODE = $BuildNumber.ToString()
$python = (Get-Command python -ErrorAction Stop).Source
$flutter = (Get-Command flutter -ErrorAction Stop).Source
$dart = (Get-Command dart -ErrorAction Stop).Source

$privateDir = Join-Path $env:LOCALAPPDATA 'Care360\private-build'
New-Item -Path $privateDir -ItemType Directory -Force | Out-Null
$defineFile = Join-Path $privateDir ("patient-production-" + [Guid]::NewGuid().ToString('N') + ".json")
try {
    Invoke-Checked $python @('tools/k3_android_release_preflight.py')
    Invoke-Checked $python @(
        'tools/k3_production_config.py',
        '--platform', 'android',
        '--firebase', 'android/app/google-services.json',
        '--out', $defineFile
    )
    # Do not pass signed binaries through the synthetic/offline GitHub runner.
    Invoke-Checked $flutter @('pub', 'get')
    Invoke-Checked $dart @('run', 'build_runner', 'build', '--delete-conflicting-outputs')
    Invoke-Checked $python @('tools/k3_rewrite_generated_url.py')
    Invoke-Checked $flutter @('test', '--no-pub',
        'test/k3_startup_gate_test.dart',
        'test/k3_startup_diagnostics_test.dart',
        'test/k3_entry_brand_test.dart')
    Invoke-Checked $flutter @(
        'build', 'appbundle', '--release',
        "--build-name=$BuildName",
        "--build-number=$BuildNumber",
        '--dart-define=K3_BUILD_ENV=production',
        "--dart-define-from-file=$defineFile"
    )
    $bundle = Join-Path $root 'build/app/outputs/bundle/release/app-release.aab'
    if (-not (Test-Path $bundle)) { throw 'No AAB produced by Flutter.' }
    Invoke-Checked $python @('tools/k3_android_native_page_alignment.py', $bundle)
    $hash = Get-FileHash -Path $bundle -Algorithm SHA256
    Write-Host "SIGNED AAB BUILT LOCALLY: $bundle"
    Write-Host "AAB SHA-256: $($hash.Hash)"
    Write-Host 'STOP: Compare upload-signing certificate fingerprint with Play Console; inspect bundletool zip alignment; run 16 KiB page-size device test and internal-track QA before any upload.'
}
finally {
    if (Test-Path $defineFile) {
        Remove-Item -Path $defineFile -Force -ErrorAction SilentlyContinue
    }
}
