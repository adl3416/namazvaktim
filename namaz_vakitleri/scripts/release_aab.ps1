param(
    [switch]$BuildOnly,
    [switch]$SkipBuild,
    [switch]$SkipRecord
)

$ErrorActionPreference = "Stop"

function Get-JavaKeytoolPath {
    if ($env:JAVA_HOME) {
        $javaHomeTool = Join-Path $env:JAVA_HOME "bin\\keytool.exe"
        if (Test-Path $javaHomeTool) {
            return $javaHomeTool
        }
    }

    $fallback = "C:\\Program Files\\Java\\jdk-17\\bin\\keytool.exe"
    if (Test-Path $fallback) {
        return $fallback
    }

    throw "keytool.exe bulunamadi. JAVA_HOME ayarini kontrol edin."
}

function Get-VersionParts {
    param([string]$VersionLine)

    if ($VersionLine -notmatch '^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$') {
        throw "pubspec.yaml icindeki version satiri beklenen formatta degil: $VersionLine"
    }

    return @{
        Major = [int]$matches[1]
        Minor = [int]$matches[2]
        Patch = [int]$matches[3]
        Build = [int]$matches[4]
    }
}

function Update-PubspecVersion {
    param(
        [string]$PubspecPath,
        [string]$CurrentVersionLine,
        [string]$NextVersionLine
    )

    $content = Get-Content $PubspecPath -Raw
    $updated = $content.Replace($CurrentVersionLine, $NextVersionLine)
    Set-Content -Path $PubspecPath -Value $updated -Encoding UTF8
}

function Get-KeyProperties {
    param([string]$KeyPropertiesPath)

    $map = @{}
    foreach ($line in Get-Content $KeyPropertiesPath) {
        if (-not $line.Trim()) {
            continue
        }

        $pair = $line -split '=', 2
        if ($pair.Count -eq 2) {
            $map[$pair[0].Trim()] = $pair[1].Trim()
        }
    }

    return $map
}

function Get-FingerprintValue {
    param(
        [string]$KeytoolOutput,
        [string]$Label
    )

    $pattern = [regex]::Escape($Label) + '\s*([A-F0-9:]+)'
    $match = [regex]::Match($KeytoolOutput, $pattern)
    if (-not $match.Success) {
        throw "$Label degeri okunamadi."
    }

    return $match.Groups[1].Value.Trim()
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$pubspecPath = Join-Path $projectRoot "pubspec.yaml"
$releaseNotesPath = Join-Path $projectRoot "RELEASE_SIGNING.md"
$keyPropertiesPath = Join-Path $projectRoot "android\\key.properties"
$buildGradlePath = Join-Path $projectRoot "android\\app\\build.gradle.kts"

if (-not (Test-Path $pubspecPath)) {
    throw "pubspec.yaml bulunamadi: $pubspecPath"
}

if (-not (Test-Path $keyPropertiesPath)) {
    throw "key.properties bulunamadi: $keyPropertiesPath"
}

$versionLine = (Get-Content $pubspecPath | Where-Object { $_ -match '^version:' } | Select-Object -First 1)
if (-not $versionLine) {
    throw "pubspec.yaml icinde version satiri bulunamadi."
}

$parts = Get-VersionParts -VersionLine $versionLine
$nextPatch = $parts.Patch
$nextBuild = $parts.Build

if (-not $BuildOnly) {
    $nextPatch += 1
    $nextBuild += 1
}

$nextVersionLine = "version: $($parts.Major).$($parts.Minor).$nextPatch+$nextBuild"
$versionName = "$($parts.Major).$($parts.Minor).$nextPatch"
$versionCode = "$nextBuild"

if (-not $BuildOnly) {
    Update-PubspecVersion -PubspecPath $pubspecPath -CurrentVersionLine $versionLine -NextVersionLine $nextVersionLine
    Write-Host "Surum guncellendi: $versionLine -> $nextVersionLine"
} else {
    Write-Host "Mevcut surumle build alinacak: $versionLine"
}

$keyProperties = Get-KeyProperties -KeyPropertiesPath $keyPropertiesPath
$storeFileValue = $keyProperties["storeFile"]
$storePassword = $keyProperties["storePassword"]
$keyAlias = $keyProperties["keyAlias"]
$keyPassword = $keyProperties["keyPassword"]

if (-not $storeFileValue -or -not $storePassword -or -not $keyAlias -or -not $keyPassword) {
    throw "key.properties icinde gerekli release signing alanlari eksik."
}

$appModuleDir = Split-Path $buildGradlePath -Parent
$keystorePath = [System.IO.Path]::GetFullPath((Join-Path $appModuleDir $storeFileValue))
if (-not (Test-Path $keystorePath)) {
    throw "Keystore bulunamadi: $keystorePath"
}

$applicationIdLine = (Get-Content $buildGradlePath | Where-Object { $_ -match 'applicationId\s*=' } | Select-Object -First 1)
$applicationId = "com.vakit.app.ezanlar"
if ($applicationIdLine -match '"([^"]+)"') {
    $applicationId = $matches[1]
}

if (-not $SkipBuild) {
    Push-Location $projectRoot
    try {
        flutter build appbundle --release
    } finally {
        Pop-Location
    }
}

$aabPath = Join-Path $projectRoot "build\\app\\outputs\\bundle\\release\\app-release.aab"
if (-not (Test-Path $aabPath)) {
    throw "Release AAB bulunamadi: $aabPath"
}

$keytoolPath = Get-JavaKeytoolPath
$keytoolOutput = & $keytoolPath -list -v -keystore $keystorePath -storepass $storePassword -alias $keyAlias -keypass $keyPassword | Out-String
$sha1 = Get-FingerprintValue -KeytoolOutput $keytoolOutput -Label "SHA1:"
$sha256 = Get-FingerprintValue -KeytoolOutput $keytoolOutput -Label "SHA256:"

if (-not $SkipRecord) {
    $entryDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
    $entry = @(
        "",
        "## Release $versionName ($versionCode)",
        "",
        "- Date: $entryDate",
        "- Version name: $versionName",
        "- Version code: $versionCode",
        "- pubspec.yaml: $nextVersionLine",
        "- AAB artifact: build/app/outputs/bundle/release/app-release.aab",
        "- Android package: $applicationId",
        "- Upload keystore: android/$(Split-Path $keystorePath -Leaf)",
        "- Key alias: $keyAlias",
        "- SHA1: $sha1",
        "- SHA256: $sha256"
    ) -join [Environment]::NewLine

    if (-not (Test-Path $releaseNotesPath)) {
        $initial = @(
            "# Release Signing Notes",
            "",
            "This file keeps a simple history of Play Store release metadata and signing details for future updates."
        ) -join [Environment]::NewLine
        Set-Content -Path $releaseNotesPath -Value $initial -Encoding UTF8
    }

    Add-Content -Path $releaseNotesPath -Value $entry -Encoding UTF8
}

Write-Host ""
Write-Host "Hazir:"
Write-Host "  Version name : $versionName"
Write-Host "  Version code : $versionCode"
Write-Host "  AAB          : $aabPath"
Write-Host "  SHA1         : $sha1"
Write-Host "  SHA256       : $sha256"
