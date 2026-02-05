$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-NOT $isAdmin) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

Write-Host "=== Installing Zapret ===" -ForegroundColor Green

$ZAPRET_DIR = "C:\Zapret"
$TEMP_DIR = "$env:TEMP\ZapretInstaller"
$OLD_DIR = "C:\zapret-discord-youtube-main"
$ZAPRET_URL = "https://codeload.github.com/Flowseal/zapret-discord-youtube/zip/refs/heads/main"
$HOSTS_LIST_URL = "https://raw.githubusercontent.com/GooDHous/HostsList/refs/heads/main/hosts.txt"

if (!(Test-Path $TEMP_DIR)) {
    New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null
}

Write-Host "1. Stopping winws.exe processes..." -ForegroundColor Cyan
Get-Process -Name "winws" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
if ($?) {
    Write-Host "   winws.exe process stopped" -ForegroundColor Green
} else {
    Write-Host "   winws.exe process not found" -ForegroundColor Yellow
}

Write-Host "2. Stopping Zapret services..." -ForegroundColor Cyan
Get-Service -Name "zapret" -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
Get-Service -Name "windivert" -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host "   Services stopped" -ForegroundColor Green

Write-Host "3. Removing old installations..." -ForegroundColor Cyan
@($ZAPRET_DIR, $OLD_DIR) | ForEach-Object {
    if (Test-Path $_) {
        Write-Host "   Deleting folder: $_"
        Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue
        if (!(Test-Path $_)) {
            Write-Host "   Folder deleted: $_" -ForegroundColor Green
        } else {
            Write-Host "   Failed to delete folder: $_" -ForegroundColor Red
        }
    }
}

Write-Host "4. Downloading Zapret archive..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $ZAPRET_URL -OutFile "$TEMP_DIR\Zapret.zip" -UseBasicParsing
    if (Test-Path "$TEMP_DIR\Zapret.zip") {
        $fileInfo = Get-Item "$TEMP_DIR\Zapret.zip"
        Write-Host "   Archive downloaded successfully ($($fileInfo.Length) bytes)" -ForegroundColor Green
    } else {
        throw "File not created"
    }
} catch {
    Write-Host "   Download error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    [Console]::ReadKey()
    exit 1
}

Write-Host "5. Downloading hosts list..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $HOSTS_LIST_URL -OutFile "$TEMP_DIR\list-general.txt" -UseBasicParsing
    if (Test-Path "$TEMP_DIR\list-general.txt") {
        Write-Host "   Hosts list downloaded successfully" -ForegroundColor Green
    }
} catch {
    Write-Host "   Failed to download hosts list: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "6. Extracting archive..." -ForegroundColor Cyan
try {
    Expand-Archive -Path "$TEMP_DIR\Zapret.zip" -DestinationPath "C:\" -Force
    Write-Host "   Extraction completed" -ForegroundColor Green
} catch {
    Write-Host "   Extraction error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    [Console]::ReadKey()
    exit 1
}

Write-Host "7. Verifying extracted folder..." -ForegroundColor Cyan
if (Test-Path $OLD_DIR) {
    Write-Host "   Folder found: $OLD_DIR" -ForegroundColor Green
} else {
    Write-Host "   Error: target folder not found: $OLD_DIR" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    [Console]::ReadKey()
    exit 1
}

Write-Host "8. Renaming folder to Zapret..." -ForegroundColor Cyan
try {
    Rename-Item -Path $OLD_DIR -NewName "Zapret" -Force
    Write-Host "   Rename successful" -ForegroundColor Green
} catch {
    Write-Host "   Rename error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    [Console]::ReadKey()
    exit 1
}

Write-Host "9. Copying hosts list to Zapret directory..." -ForegroundColor Cyan
if (Test-Path "$TEMP_DIR\list-general.txt") {
    if (!(Test-Path "$ZAPRET_DIR\lists")) {
        New-Item -ItemType Directory -Path "$ZAPRET_DIR\lists" -Force | Out-Null
    }
    Copy-Item -Path "$TEMP_DIR\list-general.txt" -Destination "$ZAPRET_DIR\lists\" -Force
    Write-Host "   Hosts list copied" -ForegroundColor Green
}

Write-Host "10. Starting Zapret service..." -ForegroundColor Cyan
if (Test-Path "$ZAPRET_DIR\service.bat") {
    Set-Location $ZAPRET_DIR
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c service.bat" -NoNewWindow -PassThru
    # Note: service.bat usually stays active, but we check if it failed immediately
    if ($process.HasExited -and $process.ExitCode -ne 0) {
        Write-Host "   Service failed to start. Exit code: $($process.ExitCode)" -ForegroundColor Yellow
    } else {
        Write-Host "   Service started successfully" -ForegroundColor Green
    }
} else {
    Write-Host "   Error: service.bat not found in $ZAPRET_DIR" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    [Console]::ReadKey()
    exit 1
}

Write-Host "11. Cleaning up..." -ForegroundColor Cyan
if (Test-Path $TEMP_DIR) {
    Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "   Temporary files removed" -ForegroundColor Green
}

Write-Host "`n===============================================" -ForegroundColor Green
Write-Host "Installation completed successfully!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host "`nPress any key to exit..."
[Console]::ReadKey() | Out-Null
