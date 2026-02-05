$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-NOT $isAdmin) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

Write-Host "=== Uninstalling Zapret ===" -ForegroundColor Yellow


Write-Host "1. Killing winws.exe..."
Get-Process -Name "winws" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue


Write-Host "2. Removing Zapret service..."
if (Get-Service -Name "zapret" -ErrorAction SilentlyContinue) {
    Stop-Service -Name "zapret" -Force -ErrorAction SilentlyContinue
    & sc.exe delete "zapret" | Out-Null
}


Get-Service -Name "windivert" -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
& sc.exe delete "windivert" 2>$null | Out-Null


Write-Host "4. Deleting files..."
$PathsToRemove = @(
    "C:\Zapret",
    "C:\zapret-discord-youtube-main",
    "$env:TEMP\ZapretInstaller"
)

foreach ($Path in $PathsToRemove) {
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "   Removed: $Path" -ForegroundColor Green
    }
}

Write-Host "`nCleanup complete!" -ForegroundColor Green
Start-Sleep -Seconds 2