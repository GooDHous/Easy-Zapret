$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-NOT $isAdmin) {
$arguments = "& '" + $myinvocation.mycommand.definition + "'"
Start-Process powershell -Verb runAs -ArgumentList $arguments
Break
}

$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=== Установка Zapret ===" -ForegroundColor Green

$ZAPRET_DIR = "C:\Zapret"
$TEMP_DIR = "$env:TEMP\ZapretInstaller"
$OLD_DIR = "C:\zapret-discord-youtube-main"
$ZAPRET_URL = "https://codeload.github.com/Flowseal/zapret-discord-youtube/zip/refs/heads/main"
$HOSTS_LIST_URL = "https://raw.githubusercontent.com/GooDHous/HostsList/refs/heads/main/hosts.txt"
$LOG_FILE = "$TEMP_DIR\zapret_install.log"

if (!(Test-Path $TEMP_DIR)) {
    New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null
}


Write-Host "1. Остановка процессов winws.exe..." -ForegroundColor Cyan
Get-Process -Name "winws" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
if ($?) {
    Write-Host "   Процесс winws.exe остановлен" -ForegroundColor Green
} else {
    Write-Host "   Процесс winws.exe не найден" -ForegroundColor Yellow
}

Write-Host "2. Остановка служб Zapret..." -ForegroundColor Cyan
Get-Service -Name "zapret" -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
Get-Service -Name "windivert" -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host "   Службы остановлены" -ForegroundColor Green

Write-Host "3. Удаление старых установок..." -ForegroundColor Cyan
@($ZAPRET_DIR, $OLD_DIR) | ForEach-Object {
    if (Test-Path $_) {
        Write-Host "   Удаление папки: $_"
        Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue
        if (!(Test-Path $_)) {
            Write-Host "   Папка удалена: $_" -ForegroundColor Green
        } else {
            Write-Host "   Не удалось удалить папку: $_" -ForegroundColor Red
        }
    }
}

Write-Host "4. Загрузка архива Zapret..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $ZAPRET_URL -OutFile "$TEMP_DIR\Zapret.zip" -UseBasicParsing
    if (Test-Path "$TEMP_DIR\Zapret.zip") {
        $fileInfo = Get-Item "$TEMP_DIR\Zapret.zip"
        Write-Host "   Архив Zapret загружен успешно ($($fileInfo.Length) байт)" -ForegroundColor Green
    } else {
        throw "Файл не создан"
    }
} catch {
    Write-Host "   Ошибка загрузки архива Zapret: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Нажмите любую клавишу для выхода..."
    [Console]::ReadKey()
    exit 1
}

Write-Host "5. Загрузка списка хостов..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $HOSTS_LIST_URL -OutFile "$TEMP_DIR\list-general.txt" -UseBasicParsing
    if (Test-Path "$TEMP_DIR\list-general.txt") {
        Write-Host "   Список хостов загружен успешно" -ForegroundColor Green
    } else {
        Write-Host "   Не удалось загрузить список хостов" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Ошибка загрузки списка хостов: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "6. Распаковка архива..." -ForegroundColor Cyan
try {
    Expand-Archive -Path "$TEMP_DIR\Zapret.zip" -DestinationPath "C:\" -Force
    Write-Host "   Архив распакован успешно" -ForegroundColor Green
} catch {
    Write-Host "   Ошибка распаковки архива: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Нажмите любую клавишу для выхода..."
    [Console]::ReadKey()
    exit 1
}

Write-Host "7. Проверка распакованной папки..." -ForegroundColor Cyan
if (Test-Path $OLD_DIR) {
    Write-Host "   Папка найдена: $OLD_DIR" -ForegroundColor Green
} else {
    Write-Host "   Ошибка: папка не найдена после распаковки: $OLD_DIR" -ForegroundColor Red
    Write-Host "Нажмите любую клавишу для выхода..."
    [Console]::ReadKey()
    exit 1
}

Write-Host "8. Переименование папки..." -ForegroundColor Cyan
try {
    Rename-Item -Path $OLD_DIR -NewName "Zapret" -Force
    Write-Host "   Папка переименована успешно" -ForegroundColor Green
} catch {
    Write-Host "   Ошибка переименования папки: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Нажмите любую клавишу для выхода..."
    [Console]::ReadKey()
    exit 1
}

Write-Host "9. Копирование списка хостов..." -ForegroundColor Cyan
if (Test-Path "$TEMP_DIR\list-general.txt") {
    if (!(Test-Path "$ZAPRET_DIR\lists")) {
        New-Item -ItemType Directory -Path "$ZAPRET_DIR\lists" -Force | Out-Null
    }
    Copy-Item -Path "$TEMP_DIR\list-general.txt" -Destination "$ZAPRET_DIR\lists\" -Force -ErrorAction SilentlyContinue
    Write-Host "   Список хостов скопирован" -ForegroundColor Green
}

Write-Host "10. Запуск Zapret..." -ForegroundColor Cyan
if (Test-Path "$ZAPRET_DIR\service.bat") {
    Set-Location $ZAPRET_DIR
    Write-Host "   Текущая директория: $(Get-Location)"
    Write-Host "   Запуск service.bat..."
    
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c service.bat"  -NoNewWindow -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "   Сервис запущен успешно" -ForegroundColor Green
        Break
    } else {
        Write-Host "   Сервис запущен с кодом ошибки: $($process.ExitCode)" -ForegroundColor Yellow
    }
    
    
} else {
    Write-Host "   Ошибка: файл service.bat не найден в $ZAPRET_DIR" -ForegroundColor Red
    Write-Host "Нажмите любую клавишу для выхода..."
    [Console]::ReadKey()
    exit 1
}

Write-Host "11. Очистка временных файлов..." -ForegroundColor Cyan
if (Test-Path $TEMP_DIR) {
    Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "   Временные файлы удалены" -ForegroundColor Green
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "Установка Zapret завершена успешно!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Нажмите любую клавишу для выхода..."
