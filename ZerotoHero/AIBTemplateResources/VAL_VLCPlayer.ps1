# This script checks if VLC media player is installed by looking for its registry key

$DisplayName = "VLC media player"
$check = $false

Get-ChildItem -Path HKLM:\software\microsoft\windows\currentversion\uninstall -Recurse -ErrorAction SilentlyContinue | % {
    if ((Get-ItemProperty -Path $_.pspath).DisplayName -eq $DisplayName) {
        $check = $true
    }
}

Get-ChildItem -Path HKLM:\software\wow6432node\microsoft\windows\currentversion\uninstall -Recurse -ErrorAction SilentlyContinue | % {
    if ((Get-ItemProperty -Path $_.pspath).DisplayName -eq $DisplayName) {
        $check = $true
    }
}

if ($check) {
    Write-Output "VLC media player is installed."
    exit 0
} else {
    Write-Output "VLC media player is not installed."
    exit 1
}
