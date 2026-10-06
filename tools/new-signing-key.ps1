# 風語輸入法 — 產生自動更新用的簽章金鑰（只需執行一次）
#
# 用法（Windows PowerShell 5）：
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\new-signing-key.ps1
#
# 私鑰存在 %USERPROFILE%\.fengyu-release\signing-key.xml，絕對不要放進 git 或上傳到任何地方，
# 並請另外備份（隨身碟、密碼管理器）。遺失私鑰後，已安裝的電腦將無法再自動更新。
# 印出的公鑰要貼進 output\fengyu-update.ps1 的 $PublicKey。

$ErrorActionPreference = 'Stop'
$dir = Join-Path $env:USERPROFILE '.fengyu-release'
$keyFile = Join-Path $dir 'signing-key.xml'

if (Test-Path $keyFile) {
  throw "金鑰已存在：$keyFile（為避免覆蓋，請先自行確認再處理）"
}
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider 3072
try {
  [IO.File]::WriteAllText($keyFile, $rsa.ToXmlString($true))
  # 只允許目前使用者讀取私鑰
  $acl = New-Object System.Security.AccessControl.FileSecurity
  $acl.SetAccessRuleProtection($true, $false)
  $me = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
  $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($me, 'FullControl', 'Allow')))
  Set-Acl -Path $keyFile -AclObject $acl

  Write-Output "私鑰已儲存：$keyFile"
  Write-Output '公鑰（貼進 output\fengyu-update.ps1 的 $PublicKey）：'
  Write-Output $rsa.ToXmlString($false)
} finally {
  $rsa.Dispose()
}
