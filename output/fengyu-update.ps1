# Fengyu IME background updater.
#
# Installed into the program folder and run daily (and shortly after boot) by the
# "Fengyu IME Update" scheduled task as SYSTEM. It checks the latest GitHub release,
# verifies the signed update manifest with the embedded public key, checks the
# installer's SHA-256 against the manifest and installs it silently.
#
#   fengyu-update.ps1              check for an update and install it
#   fengyu-update.ps1 -Register    (installer) create or refresh the scheduled task
#   fengyu-update.ps1 -Unregister  (uninstaller) remove the scheduled task
#   fengyu-update.ps1 -StartServer start the IME server in the logged-on users' sessions
#
# The private key never leaves the release machine (see tools\release.ps1), so a
# compromised GitHub account alone cannot push a malicious installer.

param([switch]$Register, [switch]$Unregister, [switch]$StartServer)

$ErrorActionPreference = 'Stop'
$TaskName = 'Fengyu IME Update'
$Repo = 'shengwen0928/fengyu-ime'
$ManifestAsset = 'fengyu-ime-update.txt'
$SignatureAsset = 'fengyu-ime-update.sig'
$PublicKey = '<RSAKeyValue><Modulus>yY5DZeJEVcquVHVccXBSOgK7JSa7xiQ6R8rTIvj2SxW36X85EY+KlXptkuI1ehocATL1qy1TObuCJJSkqvLVmfnDN6EZESpMe7kdPOxKXKX6dzRNVJYVCTp3uIiv09C0GFoCzSBSdXTDXExduJN0T6GpnAxq5MwLVMslpfrbtah4+hbjTfsfspP9QKFfLkvx5sz0xSyJ9lCLttBDIDgrdszF5+i+f+eEJHFzc6BWrbKL7Y9nbGexbfA9f1wt3vJKIW6IaE/1OSDfSz+OBcMmCkLoSRDSGT7wCfLLHxP1rW4b7lDYSI+zPpDLv2w2YT+ocju5cs2DIlpQDOyFF8VQJEQPi7v5WXIaU8yFq0tZKgOBfQCm3z6oJ92Ernb630qJEBJUlSsTUDJtgACpLunZLTFRnBNFGvenYqjbkPpt4Lrr3qgnVwsBaGUndETP/eM0GUPLabF3zQfMi/Tcqwb4tMNoXWS7A9sRDi2ORCoQg6uijZ1TNonO4ETSVxDpPJ7p</Modulus><Exponent>AQAB</Exponent></RSAKeyValue>'

if ($Register) {
  $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument (
    '-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}"' -f $PSCommandPath)
  $daily = New-ScheduledTaskTrigger -Daily -At '12:00'
  $boot = New-ScheduledTaskTrigger -AtStartup
  $boot.Delay = 'PT15M'
  $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RunOnlyIfNetworkAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Hours 1) -MultipleInstances IgnoreNew
  $principal = New-ScheduledTaskPrincipal -UserId 'S-1-5-18' -RunLevel Highest
  Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger @($daily, $boot) `
    -Settings $settings -Principal $principal -Force | Out-Null
  exit 0
}
if ($Unregister) {
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
  exit 0
}

# Start the (new) server as each logged-on user, so typing works right after an
# update. For every user owning an explorer.exe, a one-off task with that user's
# interactive logon runs the server inside their own session.
function Start-ServerForUsers {
  $root = $null
  foreach ($key in 'HKLM:\SOFTWARE\WOW6432Node\Fengyu\IME', 'HKLM:\SOFTWARE\Fengyu\IME') {
    $item = Get-ItemProperty -Path $key -Name FengyuRoot -ErrorAction SilentlyContinue
    if ($item) { $root = $item.FengyuRoot; break }
  }
  if (-not $root) { return }
  $users = @(Get-WmiObject Win32_Process -Filter "Name='explorer.exe'" | ForEach-Object {
      $o = $_.GetOwner(); if ($o.User) { '{0}\{1}' -f $o.Domain, $o.User } } | Sort-Object -Unique)
  $action = New-ScheduledTaskAction -Execute (Join-Path $root 'FengyuServer.exe') -WorkingDirectory $root
  $i = 0
  foreach ($user in $users) {
    $name = "Fengyu IME Start Server $i"; $i++
    try {
      $principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
      Register-ScheduledTask -TaskName $name -Action $action -Principal $principal -Force | Out-Null
      Start-ScheduledTask -TaskName $name
      Start-Sleep -Seconds 3
    } catch {
      $msg = "Could not start server for ${user}: $($_.Exception.Message)"
      if (Get-Command Write-Log -ErrorAction SilentlyContinue) { Write-Log $msg } else { Write-Warning $msg }
    } finally {
      Unregister-ScheduledTask -TaskName $name -Confirm:$false -ErrorAction SilentlyContinue
    }
  }
}
if ($StartServer) {
  Start-ServerForUsers
  exit 0
}

# Work folder only SYSTEM and Administrators can touch, so nothing can swap the
# installer between verification and execution.
$work = Join-Path $env:ProgramData 'Fengyu\update'
New-Item -ItemType Directory -Force -Path $work | Out-Null
$acl = New-Object System.Security.AccessControl.DirectorySecurity
$acl.SetAccessRuleProtection($true, $false)
foreach ($sid in 'S-1-5-18', 'S-1-5-32-544') {
  $id = New-Object System.Security.Principal.SecurityIdentifier $sid
  $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
        $id, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')))
}
Set-Acl -Path $work -AclObject $acl
$log = Join-Path $work 'update.log'

function Write-Log([string]$message) {
  Add-Content -Path $log -Value ('{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $message)
}

function Get-InstalledVersion {
  foreach ($key in 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Fengyu',
                   'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Fengyu') {
    $item = Get-ItemProperty -Path $key -Name DisplayVersion -ErrorAction SilentlyContinue
    if ($item) { return [version]$item.DisplayVersion }
  }
  return $null
}

try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $headers = @{ 'User-Agent' = 'fengyu-ime-updater'; 'Accept' = 'application/vnd.github+json' }

  $installed = Get-InstalledVersion
  if (-not $installed) { Write-Log 'Fengyu IME is not installed; nothing to do.'; exit 0 }

  try {
    $release = Invoke-RestMethod -UseBasicParsing -Headers $headers `
      -Uri "https://api.github.com/repos/$Repo/releases/latest"
  } catch [System.Net.WebException] {
    if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 404) {
      Write-Log 'No release published yet.'
      exit 0
    }
    throw
  }
  $assets = @{}
  foreach ($a in $release.assets) { $assets[$a.name] = $a.browser_download_url }
  if (-not $assets[$ManifestAsset] -or -not $assets[$SignatureAsset]) {
    Write-Log "Release $($release.tag_name) has no signed manifest; skipped."
    exit 0
  }

  $manifestFile = Join-Path $work $ManifestAsset
  $signatureFile = Join-Path $work $SignatureAsset
  Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $assets[$ManifestAsset] -OutFile $manifestFile
  Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $assets[$SignatureAsset] -OutFile $signatureFile
  $manifestBytes = [IO.File]::ReadAllBytes($manifestFile)
  $signature = [Convert]::FromBase64String([IO.File]::ReadAllText($signatureFile).Trim())

  $rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider
  try {
    $rsa.FromXmlString($PublicKey)
    $valid = $rsa.VerifyData($manifestBytes, $signature,
      [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)
  } finally { $rsa.Dispose() }
  if (-not $valid) { Write-Log "Release $($release.tag_name): manifest signature INVALID; refused."; exit 1 }

  $manifest = @{}
  foreach ($line in ([Text.Encoding]::UTF8.GetString($manifestBytes) -split "`n")) {
    if ($line -match '^\s*(\w+)\s*=\s*(.+?)\s*$') { $manifest[$Matches[1]] = $Matches[2] }
  }
  $latest = [version]$manifest['version']
  if ($latest -le $installed) { Write-Log "Up to date ($installed; latest $latest)."; exit 0 }

  $file = $manifest['file']
  if ($file -notmatch '^[\w.\-]+\.exe$' -or -not $assets[$file]) { Write-Log "Manifest file '$file' not found in release; refused."; exit 1 }
  $installer = Join-Path $work $file
  Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $assets[$file] -OutFile $installer
  $hash = (Get-FileHash -Algorithm SHA256 -Path $installer).Hash
  if ($hash -ne $manifest['sha256'].ToUpperInvariant()) {
    Remove-Item -Force $installer
    Write-Log "Installer hash mismatch for $file; refused."
    exit 1
  }

  Write-Log "Updating $installed -> $latest ..."
  $p = Start-Process -FilePath $installer -ArgumentList '/S', '/T', '/UPDATE' -Wait -PassThru
  Write-Log "Installer exited with code $($p.ExitCode)."
  Remove-Item -Force $installer -ErrorAction SilentlyContinue
  if ($p.ExitCode -eq 0) {
    Start-ServerForUsers
    Write-Log 'Server restarted for logged-on users.'
  }
} catch {
  Write-Log "Update check failed: $($_.Exception.Message)"
  exit 1
}
