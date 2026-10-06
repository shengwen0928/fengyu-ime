# Fengyu IME release: bump version, build, sign the update manifest, tag and publish.
#
# Usage (Windows PowerShell 5, on the release machine that holds the signing key):
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\release.ps1 -Version 1.0.2
#
# Steps:
#   1. set VERSION_MAJOR/MINOR/PATCH in build.bat and commit
#   2. build the installer (build.bat fengyu installer, RELEASE_BUILD from env.bat)
#   3. write fengyu-ime-update.txt (version, file name, SHA-256) and sign it with the
#      private key from %USERPROFILE%\.fengyu-release\signing-key.xml
#   4. tag v<version>, push, and create the GitHub release with the installer,
#      manifest and signature (installed copies pick it up via fengyu-update.ps1)

param(
  [Parameter(Mandatory = $true)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version,
  [string]$Notes = ''
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
# build through the ASCII junction when present (cmd/b2 mishandle non-ASCII paths)
if ((Test-Path 'C:\fengyu-build\build.bat') -and
    ((Get-Item 'C:\fengyu-build').Target -eq $repo -or (Resolve-Path 'C:\fengyu-build').Path -eq $repo)) {
  $root = 'C:\fengyu-build'
} else {
  $root = $repo
}
$keyFile = Join-Path $env:USERPROFILE '.fengyu-release\signing-key.xml'
if (-not (Test-Path $keyFile)) { throw "Signing key not found: $keyFile" }

function Invoke-Checked([string]$exe, [string[]]$arguments) {
  & $exe @arguments
  if ($LASTEXITCODE -ne 0) { throw "$exe $($arguments -join ' ') failed ($LASTEXITCODE)" }
}

Push-Location $root
try {
  if (git status --porcelain) { throw 'Working tree is not clean; commit or stash first.' }
  $tag = "v$Version"
  if (git tag --list $tag) { throw "Tag $tag already exists." }

  # 1. bump version
  $major, $minor, $patch = $Version.Split('.')
  $bat = [IO.File]::ReadAllText("$root\build.bat")
  $bat = $bat -replace 'set VERSION_MAJOR=\d+', "set VERSION_MAJOR=$major" `
              -replace 'set VERSION_MINOR=\d+', "set VERSION_MINOR=$minor" `
              -replace 'set VERSION_PATCH=\d+', "set VERSION_PATCH=$patch"
  [IO.File]::WriteAllText("$root\build.bat", $bat)
  Invoke-Checked git @('add', 'build.bat')
  Invoke-Checked git @('commit', '-q', '-m', "chore: 版本號更新為 $Version")

  # 2. build
  $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
  $vs = & $vswhere -latest -products * -property installationPath
  $vcvars = Join-Path $vs 'VC\Auxiliary\Build\vcvarsall.bat'
  $cmd = "set NoDefaultCurrentDirectoryInExePath=& set ""PATH=${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer;%PATH%""& " +
         "call ""$vcvars"" x64 && cd /d ""$root"" && call build.bat fengyu installer"
  Invoke-Checked cmd.exe @('/c', $cmd)
  $installerName = "fengyu-ime-$Version.0-installer.exe"
  $installer = Join-Path $root "output\archives\$installerName"
  if (-not (Test-Path $installer)) { throw "Installer not produced: $installer" }

  # 3. signed manifest
  $hash = (Get-FileHash -Algorithm SHA256 -Path $installer).Hash
  $manifest = Join-Path $root 'output\archives\fengyu-ime-update.txt'
  $signature = Join-Path $root 'output\archives\fengyu-ime-update.sig'
  $text = "version=$Version.0`nfile=$installerName`nsha256=$hash`n"
  [IO.File]::WriteAllBytes($manifest, [Text.Encoding]::UTF8.GetBytes($text))
  $rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider
  try {
    $rsa.FromXmlString([IO.File]::ReadAllText($keyFile))
    $sig = $rsa.SignData([IO.File]::ReadAllBytes($manifest),
      [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)
  } finally { $rsa.Dispose() }
  [IO.File]::WriteAllText($signature, [Convert]::ToBase64String($sig))

  # 4. tag and publish
  Invoke-Checked git @('tag', $tag)
  Invoke-Checked git @('push', 'origin', 'HEAD', $tag)
  if (-not $Notes) { $Notes = "風語輸入法 $Version" }
  Invoke-Checked gh @('release', 'create', $tag, $installer, $manifest, $signature,
    '--title', "風語輸入法 $Version", '--notes', $Notes)
  Write-Output "Released $tag"
} finally {
  Pop-Location
}
